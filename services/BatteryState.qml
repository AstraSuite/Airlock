pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Astra.Airlock

// Central battery state for the greeter.
//
// Outside test mode it mirrors the real UPower display device (percentage and
// charging state). In test mode (running outside greetd) it reports simulated
// values driven by the settings modal instead.
Item {
    id: root

    readonly property bool testMode: !Greetd.available

    // Test-mode simulation controls (written by the settings modal)
    property bool simCharging: false
    property real simPercentage: 100

    readonly property bool realPresent: Battery.present
    readonly property bool realReady: Battery.ready
    readonly property real realPercentage: Battery.percentage
    readonly property bool realCharging: Battery.charging

    readonly property bool available: root.testMode || (root.realPresent && root.realReady)

    readonly property real percentage: root.testMode ? root.simPercentage : root.realPercentage
    readonly property bool charging: root.testMode ? root.simCharging : root.realCharging
}
