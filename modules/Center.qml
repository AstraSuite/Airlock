pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import M3Shapes
import Quickshell
import Quickshell.Services.Greetd
import Caelestia.Greeter
import "../services"
import "../components"

// Centered Clean Login Panel — Profile picture, User switcher, Password input, Split session button
Item {
    id: root

    signal dismissed()

    property string passwordBuffer: ""
    property string stateMsg: ""
    property bool   authFailed: false
    property string pendingPassword: ""
    property bool   testSimulating: false
    property int    testAuthDelay: 2500
    property int    currentSessionIndex: SessionDiscovery.defaultIndex
    property int    currentUserIndex: UserDiscovery.defaultIndex

    readonly property var _user: UserDiscovery.users.length > 0 && currentUserIndex >= 0 && currentUserIndex < UserDiscovery.users.length
        ? UserDiscovery.users[root.currentUserIndex] : null
    readonly property var _session: SessionDiscovery.sessions.length > 0 && currentSessionIndex >= 0 && currentSessionIndex < SessionDiscovery.sessions.length
        ? SessionDiscovery.sessions[root.currentSessionIndex] : null

    implicitWidth: 350
    implicitHeight: loginCard.implicitHeight
    width: implicitWidth
    height: implicitHeight

    function handleKey(event) {
        if (userModal.isOpen) {
            if (event.key === Qt.Key_Escape) {
                userModal.isOpen = false;
                event.accepted = true;
                return;
            }
        }

        if (sessionSplitBtn.menuOpen) {
            if (event.key === Qt.Key_Escape) {
                sessionSplitBtn.menuOpen = false;
                event.accepted = true;
                return;
            }
        }

        // While the test-mode authentication is "in flight", the UI is locked
        // just like a real greetd handshake; Escape cancels it.
        if (root.testSimulating) {
            if (event.key === Qt.Key_Escape) {
                root._cancelSimulation();
            }
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Escape) {
            if (passwordBuffer.length > 0) {
                passwordBuffer = "";
            } else {
                if (Greetd.available) Greetd.cancelSession();
                root.pendingPassword = "";
                root.dismissed();
            }
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            _submit();
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Backspace) {
            passwordBuffer = event.modifiers & Qt.ControlModifier
                ? "" : passwordBuffer.slice(0, -1);
            event.accepted = true;
            return;
        }

        if (event.text && /^[^\x00-\x1F\x7F]+$/.test(event.text)) {
            passwordBuffer += event.text;
            event.accepted = true;
        }
    }

    function _submit() {
        stateMsg = "";
        authFailed = false;
        if (!Greetd.available) {
            // Simulate a real greetd handshake: stash the password, clear the
            // buffer so the pill shrinks and the loader spins, then reveal the
            // message after a realistic delay.
            if (root.testSimulating) return;
            root.pendingPassword = root.passwordBuffer;
            root.passwordBuffer = "";
            root.testSimulating = true;
            testAuthTimer.restart();
            return;
        }
        if (Greetd.state === GreetdState.Inactive) {
            if (_user) {
                root.pendingPassword = root.passwordBuffer;
                root.passwordBuffer = "";
                Greetd.createSession(_user.username);
            }
        } else if (Greetd.state === GreetdState.Authenticating) {
            root.passwordBuffer = "";
        }
    }

    function _cancelSimulation() {
        root.testSimulating = false;
        testAuthTimer.stop();
        root.pendingPassword = "";
        root.stateMsg = "";
        root.authFailed = false;
    }

    Timer {
        id: testAuthTimer
        interval: root.testAuthDelay
        repeat: false
        onTriggered: {
            root.testSimulating = false;
            root.stateMsg = "Test mode: login simulated";
        }
    }

    Connections {
        target: Greetd
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            // greetd only accepts a response after it has asked for one. Deliver the
            // password typed before submitting rather than expecting a second Enter.
            if (responseRequired && root.pendingPassword.length > 0) {
                const pass = root.pendingPassword;
                root.pendingPassword = "";
                Greetd.respond(pass);
            }
        }
        function onAuthFailure(message) {
            root.pendingPassword = "";
            root.stateMsg = message.length > 0 ? message : "Incorrect password.";
            root.authFailed = true;
            root.passwordBuffer = "";
            failAnim.restart();
        }
        function onReadyToLaunch() {
            root.pendingPassword = "";
            root.stateMsg = "Starting session…";
            root.authFailed = false;
            const s = root._session;
            if (s?.exec) {
                if (root._user) {
                    SessionDiscovery.saveLastSession(root._user.username, s.key || s.file || s.name);
                }
                Greetd.launch(s.exec.split(" "));
            }
        }
        function onError(error) {
            root.pendingPassword = "";
            root.stateMsg = error;
            root.authFailed = true;
            failAnim.restart();
        }
    }

    // ── Main Glass Login Card ────────────────────────────────────────
    Rectangle {
        id: loginCard
        anchors.centerIn: parent
        implicitWidth: 360
        implicitHeight: cardCol.implicitHeight + 44
        radius: 28
        z: sessionSplitBtn.menuOpen ? 2600 : 1
        color: Qt.rgba(Colours.palette.m3surfaceContainer.r,
                       Colours.palette.m3surfaceContainer.g,
                       Colours.palette.m3surfaceContainer.b, 0.94)
        Behavior on color { CAnim {} }

        ColumnLayout {
            id: cardCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 24
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 12

            // ── Profile Picture Avatar using ClamShell Shape ─────────
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 140
                implicitHeight: 140

                // Masking shape with layer.enabled: true so MultiEffect can sample its alpha
                MaterialShape {
                    id: avatarMask
                    anchors.fill: parent
                    shape: Colours.avatarShape
                    color: Colours.palette.m3surfaceContainerHighest
                    layer.enabled: true
                }

                // Fallback person icon (shows when no pfp image loaded)
                MaterialIcon {
                    anchors.centerIn: parent
                    visible: pfpImg.status !== Image.Ready
                    text: "person"
                    fontStyle.pointSize: 56
                    color: Colours.palette.m3onSurfaceVariant
                }

                // User image masked by the Material shape
                Image {
                    id: pfpImg
                    anchors.fill: parent
                    source: root._user?.avatar || ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: avatarMask
                        maskSpreadAtMin: 1
                        maskThresholdMin: 0.5
                    }
                }
            }

            // ── Switch User Chip ─────────────────────────────────────
            Rectangle {
                id: userChip
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 2
                implicitWidth: userRow.implicitWidth + 22
                implicitHeight: 30
                radius: 15
                color: userChipMouse.containsMouse || userModal.isOpen
                    ? Qt.alpha(Colours.palette.m3primaryContainer, 0.6)
                    : Qt.alpha(Colours.palette.m3surfaceContainerHigh, 0.6)

                Behavior on color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: userChipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: userModal.isOpen = !userModal.isOpen
                }

                RowLayout {
                    id: userRow
                    anchors.centerIn: parent
                    spacing: 6

                    MaterialIcon {
                        text: "person"
                        fontStyle.pointSize: 13
                        color: Colours.palette.m3primary
                    }

                    Text {
                        text: root._user ? (root._user.realName || root._user.username) : "User"
                        font.family: "Google Sans Flex"
                        font.pointSize: 11
                        font.weight: Font.DemiBold
                        color: Colours.palette.m3onSurface
                    }

                    MaterialIcon {
                        text: "swap_horiz"
                        fontStyle.pointSize: 13
                        color: Colours.palette.m3outline
                    }
                }
            }

            // ── Password Input Field Pill ────────────────────────────
            PasswordInput {
                id: pwInput
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                buffer: root.passwordBuffer
                authenticating: root.testSimulating
                             || Greetd.state === GreetdState.Authenticating
                             || Greetd.state === GreetdState.Launching
                authFailed: root.authFailed
                authPrompt: root.stateMsg.toLowerCase().includes("password") ? root.stateMsg : ""
                centerWidth: 360
                onSubmitted: root._submit()
            }

            // ── Caelestia Split Button Session Selector ──────────────
            SessionSplitButton {
                id: sessionSplitBtn
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 2
                currentIndex: root.currentSessionIndex
                onSessionChanged: idx => {
                    root.currentSessionIndex = idx;
                    const s = SessionDiscovery.sessions[idx];
                    if (s && root._user) {
                        SessionDiscovery.saveLastSession(root._user.username, s.key || s.file || s.name);
                    }
                }
            }

            // ── State / Feedback Message ─────────────────────────────
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 2
                text: root.stateMsg
                visible: root.stateMsg.length > 0
                font.family: "Google Sans Flex"
                font.pointSize: 10
                color: root.authFailed ? Colours.palette.m3error : Colours.palette.m3primary
            }
        }
    }

    // ── Session Menu Backdrop ────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        visible: sessionSplitBtn.menuOpen
        z: 2500
        onClicked: sessionSplitBtn.menuOpen = false
    }

    // ── User Picker Modal Backdrop & Popup ───────────────────────────
    MouseArea {
        anchors.fill: parent
        visible: userModal.isOpen
        z: 3999
        onClicked: userModal.isOpen = false
    }

    UserPickerModal {
        id: userModal
        anchors.centerIn: parent
        selectedIndex: root.currentUserIndex
        z: 4000
        onUserSelected: idx => {
            root.currentUserIndex = idx;
            const user = UserDiscovery.users[idx];
            if (user) {
                root.currentSessionIndex = SessionDiscovery.sessionIndexForUser(user.username);
            }
            root.passwordBuffer = "";
            root.pendingPassword = "";
            root.stateMsg = "";
            root.authFailed = false;
            root._cancelSimulation();
        }
    }
}
