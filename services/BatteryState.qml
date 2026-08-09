pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Greetd
import Quickshell.Services.UPower

// Central battery state for the greeter.
//
// Outside test mode it mirrors the real UPower display device (percentage and
// charging state). In test mode (running outside greetd) it reports simulated
// values driven by the settings modal instead.
Singleton {
    id: root

    readonly property bool testMode: !Greetd.available

    // Test-mode simulation controls (written by the settings modal)
    property bool simCharging: false
    property real simPercentage: 100

    readonly property bool realPresent: UPower.displayDevice.isPresent
    readonly property bool realReady: UPower.displayDevice.ready
    readonly property real realPercentage: UPower.displayDevice.percentage * 100
    readonly property bool realCharging: [
        UPowerDeviceState.Charging,
        UPowerDeviceState.FullyCharged,
        UPowerDeviceState.PendingCharge
    ].includes(UPower.displayDevice.state)

    readonly property bool available: root.testMode || (root.realPresent && root.realReady)

    readonly property real percentage: root.testMode ? root.simPercentage : root.realPercentage
    readonly property bool charging: root.testMode ? root.simCharging : root.realCharging
}
