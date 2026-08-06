pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Provides system information, uptime, and resource usage for greeter cards
Singleton {
    id: root

    property string osName: "Artix Linux"
    property string wmName: "Hyprland"
    property string userName: Quickshell.env("USER") || "dim"
    property string uptimeStr: "2 minutes"

    property int cpuPercent: 8
    property int cpuTemp: 62
    property int memPercent: 18
    property int diskPercent: 51

    // Read OS release
    FileView {
        path: "/etc/os-release"
        onLoaded: {
            const txt = text();
            const m = txt.match(/PRETTY_NAME="([^"]+)"/) || txt.match(/NAME="([^"]+)"/);
            if (m) root.osName = m[1];
        }
    }

    // Read uptime & stats periodically
    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            uptimeProc.running = true;
            memProc.running = true;
        }
    }

    Component.onCompleted: {
        uptimeProc.running = true;
        memProc.running = true;
    }

    Process {
        id: uptimeProc
        command: ["sh", "-c", "awk '{s=int($1); m=int(s/60)%60; h=int(s/3600)%24; d=int(s/86400); if(d>0) printf \"%dd %dh\", d, h; else if(h>0) printf \"%dh %dm\", h, m; else printf \"%d mins\", m}' /proc/uptime 2>/dev/null || echo '2 mins'"]
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim()) root.uptimeStr = data.trim();
            }
        }
    }

    Process {
        id: memProc
        command: ["sh", "-c", "awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{if(t>0) print int((t-a)/t*100)}' /proc/meminfo 2>/dev/null || echo '20'"]
        stdout: SplitParser {
            onRead: data => {
                const val = parseInt(data.trim());
                if (!isNaN(val) && val > 0) root.memPercent = val;
            }
        }
    }
}
