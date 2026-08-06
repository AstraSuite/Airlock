pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Greeter
import "../services"
import "../components"

Rectangle {
    id: root

    property alias icon: iconItem.text
    property string label: ""
    property string valueLabel: Math.round(value * 100) + "%"
    property real value: 1.0
    property real step: 0.05

    signal moved(real value)
    signal interaction(real value)
    signal released(real value)

    Layout.fillWidth: true
    implicitHeight: mainCol.implicitHeight + 18
    radius: 4

    color: rowHover.hovered
        ? Colours.tPalette.m3surfaceContainerHighest
        : Colours.tPalette.m3surfaceContainerHigh
    Behavior on color { ColorAnimation { duration: 120 } }
    HoverHandler { id: rowHover }

    ColumnLayout {
        id: mainCol
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialIcon {
                id: iconItem
                visible: text !== ""
                color: Colours.palette.m3onSurfaceVariant
                fontStyle.pointSize: 14
            }

            Text {
                text: root.label
                font.family: "Google Sans Flex"
                font.pointSize: 11
                font.weight: Font.Medium
                color: Colours.palette.m3onSurface
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: root.valueLabel
                font.family: "Google Sans Flex"
                font.pointSize: 11
                font.weight: Font.DemiBold
                color: Colours.palette.m3outline
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 16

            StyledSlider {
                id: slider
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: 10

                radius: 5
                value: root.value
                enabled: root.enabled
                fgColour: root.enabled ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3onSurface, 0.38)
                bgColour: root.enabled ? Colours.tPalette.m3secondaryContainer : Qt.alpha(Colours.palette.m3onSurface, 0.1)

                onInteraction: v => {
                    root.value = v;
                    root.moved(v);
                    root.interaction(v);
                }
                onReleased: v => root.released(v)
            }

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    const delta = event.angleDelta.y > 0 ? root.step : -root.step;
                    const nextVal = Math.max(0.05, Math.min(1.0, Math.round((root.value + delta) * 100) / 100));
                    root.value = nextVal;
                    root.moved(nextVal);
                    root.interaction(nextVal);
                }
            }
        }
    }
}
