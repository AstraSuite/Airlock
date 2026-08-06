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
            tip: "Shut Down",
            act: function() { SystemPower.poweroff(); }
        },
        {
            icon: "restart_alt",
            tip: "Reboot",
            act: function() { SystemPower.reboot(); }
        },
        {
            icon: "developer_board",
            tip: "Reboot to UEFI / BIOS",
            act: function() { SystemPower.rebootToUefi(); }
        }
    ]

    property int hoveredIndex: -1

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

                readonly property bool isHovered: hoverHandler.hovered
                readonly property bool isPressed: tapHandler.pressed
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
                        : Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.70)

                Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }

                HoverHandler {
                    id: hoverHandler
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: {
                        if (hovered) {
                            root.hoveredIndex = segBtn.index;
                        } else if (root.hoveredIndex === segBtn.index) {
                            root.hoveredIndex = -1;
                        }
                    }
                }

                TapHandler {
                    id: tapHandler
                    onTapped: segBtn.modelData.act()
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

    // ── Floating Action Tooltip ──────────────────────────────────────
    Rectangle {
        id: tooltipPill
        anchors.top: segRow.bottom
        anchors.topMargin: 8
        anchors.left: segRow.left
        implicitWidth: tipText.implicitWidth + 16
        implicitHeight: 24
        radius: 12
        color: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.95)

        visible: opacity > 0
        opacity: root.hoveredIndex >= 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Text {
            id: tipText
            anchors.centerIn: parent
            text: root.hoveredIndex >= 0 && root.hoveredIndex < root.items.length
                ? root.items[root.hoveredIndex].tip : ""
            font.family: "Google Sans Flex"
            font.pointSize: 9
            font.weight: Font.Medium
            color: Colours.palette.m3onSurface
        }
    }
}
