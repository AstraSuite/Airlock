pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    function poweroff() {
        powerProc.command = ["systemctl", "poweroff"];
        powerProc.running = true;
    }

    function reboot() {
        powerProc.command = ["systemctl", "reboot"];
        powerProc.running = true;
    }

    function suspend() {
        powerProc.command = ["systemctl", "suspend"];
        powerProc.running = true;
    }

    function hibernate() {
        powerProc.command = ["systemctl", "hibernate"];
        powerProc.running = true;
    }

    Process {
        id: powerProc
    }
}
