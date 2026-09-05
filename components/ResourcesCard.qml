pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import M3Shapes
import "../services"

// Lockscreen Resources widget matching Caelestia modules/lock/Resources.qml
// Displays CPU (Pentagon with temp bubble), RAM (Slanted with memory_alt), and Storage (Gem with hard_disk)
Rectangle {
    id: root

    implicitHeight: Math.round((root.width > 0 ? (root.width - 32 - 32) / 3 : 109) + 32)
    radius: 28
    color: Colours.tPalette.m3surfaceContainer
    clip: true

    RowLayout {
        id: resRow
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // 1. CPU Resource: Pentagon with temp circle bubble
        Resource {
            id: cpu

            icon: "memory"
            value: `${SystemInfo.cpuPercent || 15}%`
            fillValue: (SystemInfo.cpuPercent || 15) / 100
            colour: Colours.palette.m3primary
            shapeColour: Colours.palette.m3primaryContainer
            fillColour: Qt.alpha(Colours.palette.m3secondary, 0.3)
            shape: MaterialShape.Pentagon

            MaterialShape {
                id: tempBubble

                x: cpu.mShape.pointAtAngle(45).x - implicitSize / 2 + 8
                y: cpu.mShape.pointAtAngle(45).y - implicitSize / 2
                shape: (SystemInfo.cpuTemp > 90) ? MaterialShape.SoftBurst : MaterialShape.Circle
                color: (SystemInfo.cpuTemp > 90) ? Colours.palette.m3errorContainer : Colours.palette.m3secondaryContainer
                implicitSize: 30
                z: 10

                Text {
                    id: tempLabel
                    anchors.centerIn: parent
                    text: `${SystemInfo.cpuTemp || 64}°C`
                    color: (SystemInfo.cpuTemp > 90) ? Colours.palette.m3onErrorContainer : Colours.palette.m3secondary
                    font.family: "Google Sans Flex"
                    font.pointSize: 9
                    font.weight: Font.DemiBold
                    font.variableAxes: ({ "wdth": 50, "opsz": 9 })
                    renderType: Text.NativeRendering
                }
            }
        }

        // 2. RAM Resource: Slanted with memory_alt icon and wave fill
        Resource {
            id: ram

            icon: "memory_alt"
            value: `${SystemInfo.memPercent || 24}%`
            fillValue: (SystemInfo.memPercent || 24) / 100
            colour: Colours.palette.m3tertiary
            shapeColour: Colours.palette.m3onTertiary
            fillColour: Qt.alpha(Colours.palette.m3tertiary, 0.3)
            shape: MaterialShape.Slanted
        }

        // 3. Storage Resource: Gem with hard_disk icon and wave fill
        Resource {
            id: storage

            icon: "hard_disk"
            value: `${SystemInfo.diskPercent || 48}%`
            fillValue: (SystemInfo.diskPercent || 48) / 100
            colour: Colours.palette.m3secondary
            shapeColour: Colours.palette.m3secondaryContainer
            fillColour: Qt.alpha(Colours.palette.m3secondary, 0.4)
            shape: MaterialShape.Gem
        }
    }

    component Resource: Item {
        id: res

        required property string icon
        required property string value
        required property color colour
        required property color shapeColour
        property color fillColour
        property real fillValue: -1
        property alias shape: shapeItem.shape
        readonly property alias mShape: shapeItem

        Layout.fillWidth: true
        Layout.preferredHeight: width
        implicitHeight: width

        MaterialShape {
            id: shapeItem

            anchors.fill: parent
            implicitSize: res.width
            color: Qt.alpha(res.shapeColour, 1)
            opacity: res.shapeColour.a
            layer.enabled: true
        }

        Item {
            anchors.fill: shapeItem
            layer.enabled: res.fillValue >= 0
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: shapeItem
            }

            WavyTopRect {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Math.max(12, shapeItem.height * res.fillValue)
                color: res.fillColour
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: -2

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: res.icon
                color: Colours.palette.m3secondary
                iconSize: 18
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: res.value
                color: res.colour
                font.family: "Google Sans Flex"
                font.pointSize: Math.round(21 * Colours.fontScale)
                font.weight: Font.Medium
                font.variableAxes: ({ "wdth": 50, "opsz": 21 })
                renderType: Text.NativeRendering
            }
        }
    }
}
