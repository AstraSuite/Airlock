pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../services"

// Power action buttons placed at the top-left of the screen
Rectangle {
    id: root

    implicitWidth: btnRow.implicitWidth + 16
    implicitHeight: 44
    radius: 22
    color: Qt.rgba(Colours.palette.m3surfaceContainer.r,
                   Colours.palette.m3surfaceContainer.g,
                   Colours.palette.m3surfaceContainer.b, 0.85)

    RowLayout {
        id: btnRow
        anchors.centerIn: parent
        spacing: 6

        component PowerBtn: Rectangle {
            id: pbtn
            required property string icon
            required property string tip
            signal act()

            implicitWidth: 34
            implicitHeight: 34
            radius: 17
            color: mouseArea.containsMouse
                ? Qt.alpha(Colours.palette.m3primaryContainer, 0.85)
                : "transparent"

            Behavior on color { ColorAnimation { duration: 150 } }

            MaterialIcon {
                anchors.centerIn: parent
                text: pbtn.icon
                fontStyle.pointSize: 16
                color: mouseArea.containsMouse
                    ? Colours.palette.m3onPrimaryContainer
                    : Colours.palette.m3onSurfaceVariant
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: pbtn.act()
            }
        }

        PowerBtn {
            icon: "power_settings_new"
            tip: "Shut Down"
            onAct: SystemPower.poweroff()
        }

        PowerBtn {
            icon: "restart_alt"
            tip: "Reboot"
            onAct: SystemPower.reboot()
        }

        PowerBtn {
            icon: "bedtime"
            tip: "Suspend"
            onAct: SystemPower.suspend()
        }
    }
}
