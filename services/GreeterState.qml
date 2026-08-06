pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Persists greeter-specific settings (12/24h).
// Color scheme is controlled via `caelestia scheme set` which writes
// to scheme.json and is picked up live by Colours.qml.
Singleton {
    id: root

    property bool use12h: false

    // Current scheme name as reported by `caelestia scheme get`
    readonly property string currentScheme: _currentScheme
    property string _currentScheme: ""

    // Available scheme names, loaded from `caelestia scheme list`
    property var availableSchemes: []

    function setScheme(name) {
        Quickshell.execDetached(["caelestia", "scheme", "set", "-n", name]);
    }

    function save() {
        const cfg = { use12h: use12h };
        saveProc.command = ["sh", "-c",
            `mkdir -p ~/.config/caelestia && printf '%s' '${JSON.stringify(cfg)}' > ~/.config/caelestia/greeter.json`];
        saveProc.running = true;
    }

    onUse12hChanged: save()

    // Load saved settings
    Process {
        id: loadProc
        command: ["sh", "-c", "cat ~/.config/caelestia/greeter.json 2>/dev/null || echo '{}'"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    const cfg = JSON.parse(data.trim());
                    if (typeof cfg.use12h === "boolean") root.use12h = cfg.use12h;
                } catch (e) {}
            }
        }
    }

    // Get current scheme name
    Process {
        id: getSchemeProc
        command: ["caelestia", "scheme", "get", "-p", "name"]
        stdout: SplitParser {
            onRead: data => { root._currentScheme = data.trim(); }
        }
    }

    // List available schemes
    Process {
        id: listJsonProc
        property string _buf: ""
        command: ["caelestia", "scheme", "list"]
        stdout: SplitParser {
            onRead: data => { listJsonProc._buf += data; }
        }
        onRunningChanged: {
            if (!running && _buf.length > 0) {
                try {
                    const parsed = JSON.parse(_buf);
                    root.availableSchemes = Object.keys(parsed);
                } catch (e) {
                }
                _buf = "";
            }
        }
    }

    Process { id: saveProc }

    Component.onCompleted: {
        loadProc.running = true;
        getSchemeProc.running = true;
        listJsonProc.running = true;
    }
}
