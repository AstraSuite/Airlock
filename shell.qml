pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import Astra.Airlock
import "modules"

// A plain fullscreen top-level window: works under cage (no ext-session-lock-v1 /
// layer-shell needed) and under Hyprland, same as under Quickshell before it.
Window {
    id: greeterWindow

    title: "Airlock"
    visible: true
    visibility: Window.FullScreen

    // Load Google Sans Flex from local assets
    FontLoader {
        source: Qt.resolvedUrl("assets/fonts/GoogleSansFlex-VariableFont_GRAD,ROND,opsz,slnt,wdth,wght.ttf")
    }

    // Load Titan One font from local assets
    FontLoader {
        source: Qt.resolvedUrl("assets/fonts/TitanOne-Regular.ttf")
    }

    GreeterSurface {
        anchors.fill: parent
        onExitRequested: Qt.quit()
    }

    // Masks the compositor handoff to the real session: fading to black
    // first (rather than just vanishing) means our last visible frame
    // matches whatever blank screen briefly shows while the hosting
    // compositor tears down and the real one starts, instead of a jarring
    // cut straight from the login UI.
    Rectangle {
        id: launchFade
        anchors.fill: parent
        color: "black"
        opacity: 0
        visible: opacity > 0

        NumberAnimation {
            id: launchFadeAnim
            target: launchFade
            property: "opacity"
            to: 1
            duration: 220
            easing.type: Easing.InQuad
            onStopped: Qt.quit()
        }
    }

    // UserDiscovery/SessionDiscovery can't observe GreeterState's signals
    // directly (separate Rust QObjects); QML relays the one they need.
    Connections {
        target: GreeterState
        function onLastUserChanged() {
            UserDiscovery.setLastUserHint(GreeterState.lastUser);
            SessionDiscovery.setLastUserHint(GreeterState.lastUser);
        }
    }

    // greetd starts the user's real session once it gets our start_session
    // request; nothing needs this greeter process to keep running past that
    // point, and leaving it running just competes for the display/VT with
    // the session actually starting up. Quit as soon as it's launched.
    Connections {
        target: Greetd
        function onLaunched() {
            launchFadeAnim.start();
        }
    }

    // Periodic system info refresh (replaces the old FileView/Timer combo).
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: SystemInfo.refresh()
    }

    Component.onCompleted: {
        UserDiscovery.setLastUserHint(GreeterState.lastUser);
        SessionDiscovery.setLastUserHint(GreeterState.lastUser);
        SessionDiscovery.reload();
        UserDiscovery.reload();
    }
}
