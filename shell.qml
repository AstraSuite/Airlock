pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Greetd
import Caelestia.Greeter
import "modules"

ShellRoot {
    id: root

    // Load Google Sans Flex from the caelestia-shell asset path.
    FontLoader {
        source: {
            const shellPath = Quickshell.env("HOME") + "/.config/quickshell/caelestia/assets/google-sans-flex/GoogleSansFlex-VariableFont_GRAD,ROND,opsz,slnt,wdth,wght.ttf";
            return Qt.resolvedUrl("file://" + shellPath);
        }
    }

    // Load Titan One font from local assets
    FontLoader {
        source: Qt.resolvedUrl("assets/fonts/TitanOne-Regular.ttf")
    }

    WlSessionLock {
        id: lock
        locked: true

        GreeterSurface {
            onExitRequested: {
                lock.locked = false;
                exitTimer.start();
            }
        }
    }

    Timer {
        id: exitTimer
        interval: 100
        onTriggered: Qt.quit()
    }

    Component.onCompleted: {
        SessionDiscovery.reload();
        UserDiscovery.reload();
    }
}
