pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates
import Caelestia.Greeter
import "../services"
import "../components"

Slider {
    id: root

    property int radius: 5
    property bool interactionOnMove: true
    readonly property bool dragging: mouse.pressed

    property color fgColour: enabled ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3onSurface, 0.38)
    property color bgColour: enabled ? Colours.palette.m3secondaryContainer : Qt.alpha(Colours.palette.m3onSurface, 0.1)

    property real pos: visualPosition
    property real filledWidth

    signal interaction(v: real)
    signal released(v: real)

    Component.onCompleted: filledWidth = Qt.binding(() => Math.max(0, (width - handle.implicitWidth - handle.anchors.leftMargin - remaining.anchors.leftMargin) * pos))

    implicitWidth: 200
    implicitHeight: 10

    contentItem: Item {
        anchors.fill: parent

        // Filled track (on left of handle)
        StyledRect {
            id: filled

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: root.filledWidth
            height: root.height

            radius: root.radius
            topRightRadius: 2
            bottomRightRadius: 2
            color: root.fgColour
        }

        // Handle Pill (Morphs height on drag)
        StyledRect {
            id: handle

            anchors.left: filled.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 4

            implicitWidth: 4
            width: 4
            implicitHeight: mouse.pressed ? 34 : 26
            height: implicitHeight

            radius: 999
            color: root.fgColour

            Behavior on implicitHeight {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }

        // Remaining track (unfilled, on right of handle)
        StyledRect {
            id: remaining

            anchors.left: handle.right
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 4

            implicitHeight: parent.height * (parent.height <= 12 ? opacity : Math.min(opacity * 2, 1))
            height: parent.height
            opacity: Math.min(width, 12) / 12

            radius: root.radius
            topLeftRadius: 2
            bottomLeftRadius: 2
            color: root.bgColour
        }

        // Endpoint Dot
        StyledRect {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 4 * remaining.opacity

            implicitWidth: implicitHeight
            implicitHeight: 4 * remaining.opacity
            width: implicitWidth
            height: implicitHeight
            opacity: remaining.opacity

            radius: 999
            color: root.fgColour
        }
    }

    Binding {
        id: posBinding

        target: root
        property: "pos"
        value: Math.max(0, Math.min(1, mouse.pressStartPos + mouse.dragMovement))
        when: mouse.pressed
    }

    MouseArea {
        id: mouse

        property real pressStartX
        property real pressStartPos
        property real dragMovement

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        preventStealing: true
        implicitHeight: handle.implicitHeight
        height: parent.height

        onPressed: e => {
            widthBehavior.enabled = false;
            pressStartX = e.x;
            pressStartPos = root.visualPosition;
        }
        onPositionChanged: e => {
            dragMovement = (e.x - pressStartX) / width;
            if (root.interactionOnMove)
                root.interaction(posBinding.value);
        }
        onReleased: e => {
            const clickPos = e.x / width;
            const finalPos = mouse.dragMovement !== 0 ? posBinding.value : Math.max(0, Math.min(1, clickPos));
            root.interaction(finalPos);
            root.released(finalPos);
            widthBehavior.enabled = true;
            dragMovement = 0;
        }
    }

    Behavior on filledWidth {
        id: widthBehavior

        Anim {}
    }
}
