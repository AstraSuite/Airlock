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

    // UserDiscovery/SessionDiscovery can't observe GreeterState's signals
    // directly (separate Rust QObjects); QML relays the one they need.
    Connections {
        target: GreeterState
        function onLastUserChanged() {
            UserDiscovery.setLastUserHint(GreeterState.lastUser);
            SessionDiscovery.setLastUserHint(GreeterState.lastUser);
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
