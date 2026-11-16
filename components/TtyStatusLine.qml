pragma ComponentBehavior: Bound

import QtQuick
import Astra.Airlock
import "../services"
import "kit" as Kit

// The TTY look's top-left status line: the power actions as plain icons,
// then the battery as a cell bar and a percentage, no boxes, as KiiteShell's
// bar draws them.
Row {
    id: root

    spacing: 14

    readonly property var actions: [
        { icon: "power_settings_new", act: () => SystemPower.poweroff() },
        { icon: "restart_alt", act: () => SystemPower.reboot() },
        { icon: "developer_board", act: () => SystemPower.rebootToUefi() }
    ]

    Repeater {
        model: root.actions

        delegate: Kit.MaterialIcon {
            id: action
            required property var modelData

            anchors.verticalCenter: parent.verticalCenter
            text: modelData.icon
            fontStyle: Tokens.font.icon.medium
            color: actionMouse.containsMouse ? Colours.palette.m3primary : Colours.palette.m3onSurface

            MouseArea {
                id: actionMouse
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: action.modelData.act()
            }
        }
    }

    Kit.StyledText {
        visible: BatteryState.available
        anchors.verticalCenter: parent.verticalCenter
        text: "│"
        color: Colours.palette.m3outlineVariant
    }

    Row {
        id: battery

        readonly property int cells: 12
        readonly property int filled: Math.round(BatteryState.percentage / 100 * cells)

        visible: BatteryState.available
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Row {
            anchors.verticalCenter: parent.verticalCenter

            Kit.StyledText {
                text: "█".repeat(battery.filled)
                color: BatteryState.percentage <= 15 && !BatteryState.charging ? Colours.palette.m3error : Colours.palette.m3primary
                font.family: Tokens.font.body.medium.family
                font.letterSpacing: -1
            }
            Kit.StyledText {
                text: "█".repeat(battery.cells - battery.filled)
                color: Colours.palette.m3outlineVariant
                font.family: Tokens.font.body.medium.family
                font.letterSpacing: -1
            }
        }

        Kit.StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(BatteryState.percentage) + "%" + (BatteryState.charging ? " +" : "")
            color: Colours.palette.m3onSurface
        }
    }
}
