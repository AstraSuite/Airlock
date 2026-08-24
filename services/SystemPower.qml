pragma Singleton

import QtQuick
import Quickshell
import Astra.Airlock

Singleton {
    id: root

    readonly property bool canRebootToUefi: SessionManager.canRebootToUefi()

    function poweroff() {
        SessionManager.poweroff();
    }

    function reboot() {
        SessionManager.reboot();
    }

    function rebootToUefi() {
        SessionManager.rebootToUefi();
    }

    function rebootToFirmware() {
        SessionManager.rebootToUefi();
    }

    function suspend() {
        SessionManager.suspend();
    }

    function hibernate() {
        SessionManager.hibernate();
    }

    function exec(cmd) {
        if (Array.isArray(cmd)) {
            SessionManager.exec(cmd);
        } else {
            SessionManager.exec([cmd]);
        }
    }
}
