pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import M3Shapes
import Quickshell
import Quickshell.Services.Greetd
import Astra.Airlock
import "../services"
import "../components"

// Full Lockscreen-style Composite Login Panel matching Caelestia M3 Expressive design:
// - Left Column: Weather, Fetch (with distro logo & ANSI squircle palette), and Animated Logo
// - Center Column: Two-tone Clock, Date, Avatar, User switch button, Password Input, Session SplitButton
// - Right Column: M3-shaped Resources Chips and Quick Actions Hub (with M3 switches and power buttons)
// Zero borders, spacious 1344x756 card dimensions, exact Caelestia proportions.
Item {
    id: root

    signal dismissed()

    property string passwordBuffer: ""
    property string stateMsg: ""
    property bool   authFailed: false
    property string pendingPassword: ""
    property bool   testSimulating: false
    property int    testAuthDelay: 2500
    property int currentSessionIndex: SessionDiscovery.defaultIndex
    property int currentUserIndex: UserDiscovery.defaultIndex

    property string _dateStr: ""

    function _updateDate() {
        const d = new Date();
        const days = ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY",
                      "THURSDAY", "FRIDAY", "SATURDAY"];
        const months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                        "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
        root._dateStr = days[d.getDay()] + " \u2022 " + d.getDate() + " " + months[d.getMonth()];
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._updateDate()
    }

    readonly property var _user: UserDiscovery.users.length > 0 && currentUserIndex >= 0 && currentUserIndex < UserDiscovery.users.length
        ? UserDiscovery.users[root.currentUserIndex] : null
    readonly property var _session: SessionDiscovery.sessions.length > 0 && currentSessionIndex >= 0 && currentSessionIndex < SessionDiscovery.sessions.length
        ? SessionDiscovery.sessions[root.currentSessionIndex] : null

    function syncUserSession() {
        if (root._user) {
            root.currentSessionIndex = SessionDiscovery.sessionIndexForUser(root._user.username);
        } else {
            root.currentSessionIndex = SessionDiscovery.defaultIndex;
        }
    }

    onCurrentUserIndexChanged: syncUserSession()
    Component.onCompleted: syncUserSession()

    Connections {
        target: UserDiscovery
        function onDefaultIndexChanged() {
            root.currentUserIndex = UserDiscovery.defaultIndex;
            root.syncUserSession();
        }
    }

    Connections {
        target: SessionDiscovery
        function onDefaultIndexChanged() {
            root.syncUserSession();
        }
    }

    implicitWidth: panelCard.implicitWidth
    implicitHeight: panelCard.implicitHeight
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

    onPasswordBufferChanged: {
        if (passwordBuffer.length > 0) {
            root.authFailed = false;
            stateMsgComponent.clear();
        }
    }

    function _submit() {
        stateMsgComponent.clear();
        authFailed = false;
        if (!Greetd.available) {
            if (root.testSimulating) return;
            root.pendingPassword = root.passwordBuffer;
            root.passwordBuffer = "";
            root.testSimulating = true;
            testAuthTimer.restart();
            return;
        }

        if (root.passwordBuffer.length === 0 && root.pendingPassword.length === 0) {
            return;
        }

        const typedPassword = root.passwordBuffer.length > 0 ? root.passwordBuffer : root.pendingPassword;

        if (Greetd.state === GreetdState.Authenticating) {
            root.passwordBuffer = "";
            root.pendingPassword = "";
            Greetd.respond(typedPassword);
        } else {
            if (root._user) {
                if (Greetd.state !== GreetdState.Inactive) {
                    Greetd.cancelSession();
                }
                root.pendingPassword = typedPassword;
                root.passwordBuffer = "";
                Greetd.createSession(root._user.username);
            }
        }
    }

    function _cancelSimulation() {
        root.testSimulating = false;
        testAuthTimer.stop();
        root.pendingPassword = "";
        root.authFailed = false;
        stateMsgComponent.clear();
    }

    Timer {
        id: testAuthTimer
        interval: root.testAuthDelay
        repeat: false
        onTriggered: {
            root.testSimulating = false;
            root.handleAuthFailure("Incorrect password. Please try again.");
        }
    }

    function handleAuthFailure(rawMsg) {
        root.pendingPassword = "";
        root.passwordBuffer = "";
        root.authFailed = true;

        if (Greetd.available && Greetd.state !== GreetdState.Inactive) {
            Greetd.cancelSession();
        }

        stateMsgComponent.triggerFailure(qsTr("Incorrect password. Please try again."));
    }

    Connections {
        target: Greetd
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired && root.pendingPassword.length > 0) {
                const pass = root.pendingPassword;
                root.pendingPassword = "";
                Greetd.respond(pass);
            }
        }
        function onAuthFailure(message) {
            root.handleAuthFailure(message);
        }
        function onReadyToLaunch() {
            root.pendingPassword = "";
            stateMsgComponent.showInfo(qsTr("Starting session…"));
            root.authFailed = false;
            const s = root._session;
            if (s?.exec) {
                if (root._user) {
                    GreeterState.saveSession(root._user.username, s.key || s.file || s.name);
                }
                Greetd.launch(s.exec.split(" ").filter(x => x.length > 0));
            }
        }
        function onError(error) {
            root.handleAuthFailure(error);
        }
    }

    // ── Main Glass Card Frame (No Borders, M3 Expressive) ──────────────
    Rectangle {
        id: panelCard
        anchors.centerIn: parent
        implicitWidth: 1344
        implicitHeight: 756
        radius: 36
        color: Qt.rgba(Colours.palette.m3surface.r,
                       Colours.palette.m3surface.g,
                       Colours.palette.m3surface.b, 0.92)
        z: sessionSplitBtn.menuOpen ? 2600 : 1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 0.8
            blurMax: 36
            shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.70)
        }

        RowLayout {
            id: mainRow
            anchors.fill: parent
            anchors.margins: 24
            spacing: 36

            // ── Left Column: Weather, Fetch, Animated Logo ────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 391
                Layout.fillHeight: true
                spacing: 14

                WeatherCard {
                    Layout.fillWidth: true
                }

                FetchCard {
                    Layout.fillWidth: true
                }

                LogoCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }

            // ── Center Column: Clock, Date, Avatar, User button, Password, Session ──
            ColumnLayout {
                Layout.preferredWidth: 450
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 4

                Item { Layout.fillHeight: true }

                LocklikeClock {
                    Layout.alignment: Qt.AlignHCenter
                    centerScale: 0.75
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 4
                    Layout.bottomMargin: 6
                    text: root._dateStr
                    font.family: "Google Sans Flex"
                    font.pointSize: 15
                    font.weight: Font.DemiBold
                    font.variableAxes: ({ "wdth": 85, "opsz": 15 })
                    color: Colours.palette.m3onSurface
                }

                // Avatar with M3 shape mask
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                    implicitWidth: 250
                    implicitHeight: 250

                    MaterialShape {
                        id: avatarMask
                        anchors.fill: parent
                        shape: Colours.avatarShape
                        color: Colours.palette.m3surfaceContainerHighest
                        layer.enabled: true
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        visible: pfpImg.status !== Image.Ready
                        text: "person"
                        iconSize: 84
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    Image {
                        id: pfpImg
                        anchors.fill: parent
                        source: root._user?.avatar || ""
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                        mipmap: true
                        smooth: true

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: avatarMask
                            maskSpreadAtMin: 1
                            maskThresholdMin: 0.5
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: userModal.isOpen = !userModal.isOpen
                    }
                }

                // User switch button chip
                Rectangle {
                    id: userChip
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 2
                    Layout.bottomMargin: 6
                    implicitWidth: userRow.implicitWidth + 24
                    implicitHeight: 32
                    radius: 16
                    color: userChipMouse.containsMouse || userModal.isOpen
                        ? Colours.tPalette.m3primaryContainer
                        : Colours.tPalette.m3surfaceContainerHigh

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
                            iconSize: 14
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
                            iconSize: 14
                            color: Colours.palette.m3outline
                        }
                    }
                }

                // Password input pill
                PasswordInput {
                    id: pwInput
                    Layout.alignment: Qt.AlignHCenter
                    buffer: root.passwordBuffer
                    authenticating: root.testSimulating
                                 || Greetd.state === GreetdState.Authenticating
                                 || Greetd.state === GreetdState.Launching
                    authFailed: root.authFailed
                    authPrompt: ""
                    centerWidth: 420
                    onSubmitted: root._submit()
                }

                // Split button session selector row
                SessionSplitButton {
                    id: sessionSplitBtn
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 6
                    currentIndex: root.currentSessionIndex
                    onSessionChanged: idx => {
                        root.currentSessionIndex = idx;
                        const s = SessionDiscovery.sessions[idx];
                        if (s && root._user) {
                            GreeterState.saveSession(root._user.username, s.key || s.file || s.name);
                        }
                    }
                }

                // State / Feedback Message
                StateMessage {
                    id: stateMsgComponent
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                }

                Item { Layout.fillHeight: true }
            }

            // ── Right Column: Resources & Quick Actions Hub ───────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 391
                Layout.fillHeight: true
                spacing: 14

                ResourcesCard {
                    Layout.fillWidth: true
                }

                QuickActionsCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }

    // ── Session Menu Backdrop ─────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        visible: sessionSplitBtn.menuOpen
        z: 2500
        onClicked: sessionSplitBtn.menuOpen = false
    }

    // ── User Picker Modal Backdrop & Popup ────────────────────────────
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
                GreeterState.lastUser = user.username;
                const sessIdx = SessionDiscovery.sessionIndexForUser(user.username);
                root.currentSessionIndex = sessIdx;
                const sess = SessionDiscovery.sessions[sessIdx];
                if (sess) {
                    GreeterState.saveSession(user.username, sess.key || sess.file || sess.name);
                }
            }
            root.passwordBuffer = "";
            root.pendingPassword = "";
            root.stateMsg = "";
            root.authFailed = false;
            root._cancelSimulation();
        }
    }
}
