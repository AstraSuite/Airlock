pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../services"

// Power action buttons segment row placed at the top-left of the screen
// Matches Caelestia segmented buttons with dynamic corner and shape morphing on hover & press
Item {
    id: root

    implicitWidth: segRow.implicitWidth
    implicitHeight: 40

    readonly property var items: [
        {
            icon: "power_settings_new",
            act: function() { SystemPower.poweroff(); }
        },
        {
            icon: "restart_alt",
            act: function() { SystemPower.reboot(); }
        },
        {
            icon: "developer_board",
            act: function() { SystemPower.rebootToUefi(); }
        }
    ]

    Row {
        id: segRow
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: root.items
            delegate: Rectangle {
                id: segBtn
                required property int index
                required property var modelData

                readonly property bool isHovered: stateLayer.containsMouse
                readonly property bool isPressed: stateLayer.pressed
                readonly property int totalCount: root.items.length

                implicitHeight: 38
                implicitWidth: isPressed ? 58 : 44

                // ── Dynamic Corner Radius Morphing ──────────────────
                // On hover: morphs into fully rounded pill (19px radius) without changing width
                // On press/click: grows in width and morphs into tighter squircle (12px radius)
                // Inactive: segmented outer pill curve and inner subtle curve
                topLeftRadius: isHovered ? 19 : (isPressed ? 12 : (index === 0 ? 19 : 6))
                bottomLeftRadius: isHovered ? 19 : (isPressed ? 12 : (index === 0 ? 19 : 6))
                topRightRadius: isHovered ? 19 : (isPressed ? 12 : (index === totalCount - 1 ? 19 : 6))
                bottomRightRadius: isHovered ? 19 : (isPressed ? 12 : (index === totalCount - 1 ? 19 : 6))

                Behavior on topLeftRadius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on bottomLeftRadius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on topRightRadius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on bottomRightRadius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on implicitWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                // ── Tonal Colors ────────────────────────────────────
                color: isPressed
                    ? Colours.palette.m3secondary
                    : isHovered
                        ? Colours.palette.m3primary
                        : Colours.tPalette.m3surfaceContainer

                Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }

                StateLayer {
                    id: stateLayer
                    color: segBtn.isHovered ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    onClicked: segBtn.modelData.act()
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: segBtn.modelData.icon
                    fontStyle.pointSize: 16
                    color: segBtn.isHovered
                        ? Colours.palette.m3onPrimary
                        : Colours.palette.m3onSurfaceVariant

                    Behavior on color { ColorAnimation { duration: 160 } }
                }
            }
        }
    }
}
