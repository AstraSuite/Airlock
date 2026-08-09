pragma ComponentBehavior: Bound

import QtQuick
import "../services"

Item {
    id: root

    property real size: 44
    property real percentage: 1.0           // 0..1
    property bool charging: false

    property color shellColour: Qt.alpha(Colours.palette.m3onSurface, 0.28)
    property color whiteFill: Colours.palette.m3onSurface
    property color lowFill: Colours.palette.m3error

    readonly property bool showBadge: root.charging || root.percentage <= 0.15
    implicitWidth: root.showBadge ? root.size * 1.30 : root.size
    implicitHeight: root.size

    readonly property color chargeColour: Qt.hsla(
        Math.max(0, Math.min(1, root.percentage)) * (120 / 360), 0.78, 0.56, 1)

    property color fillColour: root.charging
        ? root.chargeColour
        : (root.percentage <= 0.20 ? root.lowFill : root.whiteFill)

    Behavior on fillColour { CAnim {} }

    readonly property color textColour: root.percentage >= 0.5
        ? Colours.palette.m3surface
        : Colours.palette.m3onSurfaceVariant

    readonly property var glyphFont: ({
        family: "Material Symbols Rounded",
        pixelSize: root.size,
        weight: Font.Normal
    })

    Item {
        id: batteryBody
        width: root.size
        height: root.size
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        Text {
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: "battery_android_full"
            color: root.shellColour
            font.family: root.glyphFont.family
            font.pixelSize: root.glyphFont.pixelSize
            font.variableAxes: ({
                "FILL": 1,
                "wght": 400,
                "GRAD": Colours.light ? 0 : -25,
                "opsz": root.size
            })
        }

        Rectangle {
            id: fillClip
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            
            width: parent.width * Math.max(0, Math.min(1, root.percentage))
            color: "transparent"
            clip: true

            Behavior on width {
                Anim { type: Anim.FastSpatial }
            }

            Text {
                width: batteryBody.width
                height: batteryBody.height
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "battery_android_full"
                color: root.fillColour
                font.family: root.glyphFont.family
                font.pixelSize: root.glyphFont.pixelSize
                font.variableAxes: ({
                    "FILL": 1,
                    "wght": 400,
                    "GRAD": Colours.light ? 0 : -25,
                    "opsz": root.size
                })
            }
        }

        Text {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -root.size * 0.04
            text: Math.round(root.percentage * 100) + "%"
            font.family: "Google Sans Flex"
            font.pixelSize: text.length >= 4 ? root.size * 0.24 : root.size * 0.28
            font.weight: Font.DemiBold
            color: root.textColour
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter

            Behavior on color { CAnim {} }
            Behavior on font.pixelSize { CAnim {} }
        }
    }

    Text {
        anchors.left: batteryBody.right
        anchors.leftMargin: -root.size * 0.04
        anchors.verticalCenter: batteryBody.verticalCenter
        visible: root.showBadge
        
        text: root.charging ? "bolt" : "priority_high"
        color: root.fillColour
        font.family: root.glyphFont.family
        font.pixelSize: root.charging ? root.size * 0.45 : root.size * 0.40
        font.variableAxes: ({
            "wght": 600,
            "GRAD": Colours.light ? 0 : -25,
            "opsz": root.size
        })

        Behavior on color { CAnim {} }
    }
}