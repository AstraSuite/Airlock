pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import M3Shapes
import Astra.Airlock
import "../services"
import "../components"
import "../components/kit" as Kit

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
    property int currentSessionIndex: SessionDiscovery.defaultIndex
    property int currentUserIndex: UserDiscovery.defaultIndex

    readonly property var _usersList: JSON.parse(UserDiscovery.usersJson)
    readonly property var _sessionsList: JSON.parse(SessionDiscovery.sessionsJson)

    readonly property var _user: root._usersList.length > 0 && currentUserIndex >= 0 && currentUserIndex < root._usersList.length
        ? root._usersList[root.currentUserIndex] : null
    readonly property var _session: root._sessionsList.length > 0 && currentSessionIndex >= 0 && currentSessionIndex < root._sessionsList.length
        ? root._sessionsList[root.currentSessionIndex] : null

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

    implicitWidth: Colours.tty ? ttyLogin.implicitWidth : 350
    implicitHeight: Colours.tty ? ttyLogin.implicitHeight : loginCard.implicitHeight
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

        // TTY: the arrows move the session box's selection
        if (Colours.tty && (event.key === Qt.Key_Up || event.key === Qt.Key_Down) && root._sessionsList.length > 0) {
            const n = root._sessionsList.length;
            root.selectSession((root.currentSessionIndex + (event.key === Qt.Key_Down ? 1 : n - 1)) % n);
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

    function selectSession(idx) {
        root.currentSessionIndex = idx;
        const s = root._sessionsList[idx];
        if (s && root._user) {
            GreeterState.saveSession(root._user.username, s.key || s.file || s.name);
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
            // greetd only accepts a response after it has asked for one. Deliver the
            // password typed before submitting rather than expecting a second Enter.
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

    // ── Main Glass Login Card ────────────────────────────────────────
    Rectangle {
        id: loginCard
        anchors.centerIn: parent
        implicitWidth: 360
        implicitHeight: cardCol.implicitHeight + 44
        radius: 28
        visible: !Colours.tty
        z: sessionSplitBtn.menuOpen ? 2600 : 1
        color: Colours.tPalette.m3surfaceContainer
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
                authPrompt: ""
                centerWidth: 360
                onSubmitted: root._submit()
            }

            // ── Caelestia Split Button Session Selector ──────────────
            SessionSplitButton {
                id: sessionSplitBtn
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 2
                currentIndex: root.currentSessionIndex
                onSessionChanged: idx => root.selectSession(idx)
            }

            // ── State / Feedback Message ─────────────────────────────
            StateMessage {
                id: stateMsgComponent
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.topMargin: 2
            }
        }
    }

    // ── TTY login: a "user" box holding the avatar and a console-style
    // prompt, over a "session" box to pick from ──────────────────────────
    Column {
        id: ttyLogin
        anchors.centerIn: parent
        visible: Colours.tty
        spacing: 40

        readonly property bool busy: root.testSimulating
            || Greetd.state === GreetdState.Authenticating
            || Greetd.state === GreetdState.Launching
        property bool cursorOn: true
        property int spinFrame: 0
        readonly property var spinner: ["|", "/", "-", "\\"]

        Timer {
            interval: 530
            running: ttyLogin.visible && !ttyLogin.busy
            repeat: true
            onTriggered: ttyLogin.cursorOn = !ttyLogin.cursorOn
            onRunningChanged: ttyLogin.cursorOn = true
        }
        Timer {
            interval: 120
            running: ttyLogin.visible && ttyLogin.busy
            repeat: true
            onTriggered: ttyLogin.spinFrame = (ttyLogin.spinFrame + 1) % 4
        }

        Item {
            id: userBox
            width: 420
            height: userCol.implicitHeight + 64

            Kit.TtyBox {
                anchors.fill: parent
                title: "user"
                accent: true
            }

            Column {
                id: userCol
                anchors.centerIn: parent
                width: parent.width - 64
                spacing: 24

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 84
                    height: 84

                    Image {
                        id: ttyAvatar
                        anchors.fill: parent
                        anchors.margins: 1
                        source: root._user?.avatar || ""
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                        mipmap: true
                    }

                    Kit.StyledText {
                        anchors.centerIn: parent
                        visible: !ttyAvatar.visible
                        text: {
                            const name = root._user ? (root._user.realName || root._user.username) : "";
                            return name.length > 0 ? name.charAt(0).toUpperCase() : "?";
                        }
                        color: Colours.palette.m3inverseOnSurface
                        font.family: Tokens.font.body.medium.family
                        font.pixelSize: 34
                        font.weight: Font.DemiBold
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.width: 1
                        border.color: Colours.palette.m3outlineVariant
                    }
                }

                Column {
                    width: parent.width
                    spacing: 10

                    Row {
                        spacing: 10

                        Kit.StyledText {
                            text: "airlock login:"
                            color: Colours.palette.m3outline
                        }

                        Kit.StyledText {
                            text: root._user ? root._user.username : "?"
                            color: loginMouse.containsMouse || userModal.isOpen
                                ? Colours.palette.m3primary
                                : Colours.palette.m3inverseOnSurface

                            MouseArea {
                                id: loginMouse
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: userModal.isOpen = !userModal.isOpen
                            }
                        }
                    }

                    Row {
                        spacing: 10

                        Kit.StyledText {
                            text: "password:"
                            color: Colours.palette.m3outline
                        }

                        Kit.StyledText {
                            text: ttyLogin.busy
                                ? "authenticating " + ttyLogin.spinner[ttyLogin.spinFrame]
                                : "*".repeat(Math.min(root.passwordBuffer.length, 24)) + (ttyLogin.cursorOn ? "█" : " ")
                            color: ttyLogin.busy ? Colours.palette.m3outline : Colours.palette.m3inverseOnSurface
                        }
                    }

                    Kit.StyledText {
                        width: parent.width
                        visible: text.length > 0
                        text: stateMsgComponent.msg.length > 0
                            ? stateMsgComponent.msg
                            : (stateMsgComponent.infoMsgShouldBeVisible ? stateMsgComponent.infoMsg : "")
                        color: stateMsgComponent.msg.length > 0 ? Colours.palette.m3error : Colours.palette.m3outline
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        Item {
            id: sessionBox
            anchors.horizontalCenter: parent.horizontalCenter
            width: 300
            height: sessionCol.implicitHeight + 40

            Kit.TtyBox {
                anchors.fill: parent
                title: "session"
            }

            Column {
                id: sessionCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 8

                Repeater {
                    model: root._sessionsList

                    delegate: Item {
                        id: sessionRow
                        required property int index
                        required property var modelData

                        readonly property bool current: index === root.currentSessionIndex

                        width: sessionCol.width
                        height: sessionLine.implicitHeight
                        opacity: current || sessionMouse.containsMouse ? 1 : 0.55

                        Row {
                            id: sessionLine
                            spacing: 10

                            Kit.StyledText {
                                width: 10
                                text: sessionRow.current ? "›" : ""
                                color: Colours.palette.m3primary
                            }

                            Kit.StyledText {
                                width: sessionRow.width - 20
                                text: sessionRow.modelData.name || sessionRow.modelData.key || ""
                                color: sessionRow.current ? Colours.palette.m3inverseOnSurface : Colours.palette.m3onSurfaceVariant
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: sessionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectSession(sessionRow.index)
                        }
                    }
                }
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
            const user = root._usersList[idx];
            if (user) {
                GreeterState.lastUser = user.username;
                const sessIdx = SessionDiscovery.sessionIndexForUser(user.username);
                root.currentSessionIndex = sessIdx;
                const sess = root._sessionsList[sessIdx];
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
