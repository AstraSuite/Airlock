pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Greetd
import Astra.Airlock
import "modules"

ShellRoot {
    id: root

    // Load Google Sans Flex from local assets
    FontLoader {
        source: Qt.resolvedUrl("assets/fonts/GoogleSansFlex-VariableFont_GRAD,ROND,opsz,slnt,wdth,wght.ttf")
    }

    // Load Titan One font from local assets
    FontLoader {
        source: Qt.resolvedUrl("assets/fonts/TitanOne-Regular.ttf")
    }

    // A plain fullscreen xdg-shell toplevel: works under cage (no
    // ext-session-lock-v1 / layer-shell needed) and under Hyprland.
    FloatingWindow {
        id: greeterWindow
        title: "Airlock"
        fullscreen: true
        visible: true

        GreeterSurface {
            anchors.fill: parent
            onExitRequested: Qt.quit()
        }
    }

    Component.onCompleted: {
        SessionDiscovery.reload();
        UserDiscovery.reload();
    }
}
