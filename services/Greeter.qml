pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Path to the wallpaper image. Auto-detected from caelestia config.
    property string wallpaperPath: ""

    Process {
        id: wallProc
        command: ["sh", "-c",
            "cat ~/.config/caelestia/shell.json 2>/dev/null | python3 -c \"import sys,json; d=json.load(sys.stdin); print(d.get('background',{}).get('path',''))\" 2>/dev/null || echo ''"
        ]
        stdout: SplitParser {
            onRead: data => {
                const trimmed = data.trim();
                if (trimmed.length > 0) {
                    root.wallpaperPath = "file://" + trimmed;
                }
            }
        }
    }

    Component.onCompleted: {
        wallProc.running = true;
    }
}
