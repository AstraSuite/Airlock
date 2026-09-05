pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Provides live system information, uptime, and resource usage matching Caelestia
Singleton {
    id: root

    property string osName: "Artix Linux"
    property string osPrettyName: "Artix Linux"
    property string wmName: Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("XDG_SESSION_DESKTOP") || "Hyprland"
    property string userName: Quickshell.env("USER") || "dim"
    property string uptimeStr: "0 minutes"

    property int cpuPercent: 11
    property int cpuTemp: 62
    property int memPercent: 24
    property int diskPercent: 48

    // Read OS release from /etc/os-release
    FileView {
        id: osRelease
        path: "/etc/os-release"
        onLoaded: {
            const lines = text().split("\n");
            const fd = key => lines.find(l => l.startsWith(`${key}=`))?.split("=")[1].replace(/"/g, "") ?? "";
            root.osName = fd("NAME") || "Artix Linux";
            root.osPrettyName = fd("PRETTY_NAME") || root.osName;
        }
    }

    // Live Uptime reader from /proc/uptime matching Caelestia logic
    FileView {
        id: fileUptime
        path: "/proc/uptime"
        onLoaded: {
            const up = parseInt(text().split(" ")[0] ?? 0);
            const days = Math.floor(up / 86400);
            const hours = Math.floor((up % 86400) / 3600);
            const minutes = Math.floor((up % 3600) / 60);

            let str = "";
            if (days > 0)
                str += `${days} day${days === 1 ? "" : "s"}`;
            if (hours > 0)
                str += `${str ? ", " : ""}${hours} hour${hours === 1 ? "" : "s"}`;
            if (minutes > 0 || !str)
                str += `${str ? ", " : ""}${minutes} minute${minutes === 1 ? "" : "s"}`;
            root.uptimeStr = str;
        }
    }

    // Live Memory reader from /proc/meminfo
    FileView {
        id: fileMeminfo
        path: "/proc/meminfo"
        onLoaded: {
            const txt = text();
            const mTot = txt.match(/MemTotal:\s+(\d+)/);
            const mAvail = txt.match(/MemAvailable:\s+(\d+)/);
            if (mTot && mAvail) {
                const total = parseInt(mTot[1]);
                const avail = parseInt(mAvail[1]);
                if (total > 0) {
                    root.memPercent = Math.round((total - avail) / total * 100);
                }
            }
        }
    }

    // Live CPU % reader from /proc/stat
    property var _prevCpu: [0, 0]
    FileView {
        id: fileStat
        path: "/proc/stat"
        onLoaded: {
            const txt = text();
            const m = txt.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/m);
            if (m) {
                const user = parseInt(m[1]), nice = parseInt(m[2]), sys = parseInt(m[3]), idle = parseInt(m[4]);
                const iowait = parseInt(m[5]), irq = parseInt(m[6]), softirq = parseInt(m[7]);
                const total = user + nice + sys + idle + iowait + irq + softirq;
                const active = user + nice + sys + irq + softirq;
                if (root._prevCpu[0] > 0) {
                    const diffTot = total - root._prevCpu[0];
                    const diffAct = active - root._prevCpu[1];
                    if (diffTot > 0) {
                        root.cpuPercent = Math.min(100, Math.max(0, Math.round(diffAct / diffTot * 100)));
                    }
                }
                root._prevCpu = [total, active];
            }
        }
    }

    // Live CPU Temperature reader
    FileView {
        id: fileTempK10
        path: "/sys/class/hwmon/hwmon4/temp1_input"
        printErrors: false
        onLoaded: {
            const t = parseInt(text().trim());
            if (!isNaN(t) && t > 0) {
                root.cpuTemp = Math.round(t > 1000 ? t / 1000 : t);
            }
        }
    }

    FileView {
        id: fileTempFallback
        path: "/sys/class/thermal/thermal_zone0/temp"
        printErrors: false
        onLoaded: {
            if (root.cpuTemp <= 0) {
                const t = parseInt(text().trim());
                if (!isNaN(t) && t > 0) {
                    root.cpuTemp = Math.round(t > 1000 ? t / 1000 : t);
                }
            }
        }
    }

    // Periodic live refresh timer
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            fileUptime.reload();
            fileMeminfo.reload();
            fileStat.reload();
            fileTempK10.reload();
        }
    }
}
