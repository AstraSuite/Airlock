import QtQuick
import QtQuick.Templates as T
import "../"
import Astra.Airlock
import "../../../services"
T.Slider {
    id: root

    property int radius: Tokens.rounding.full
    property int trackHeight: 6
    property int handleWidth: 3
    property int handleHeight: 14
    property int handleHeightPressed: 18
    property bool interactionOnMove: true
    readonly property bool dragging: mouse.pressed

    property color fgColour: enabled ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3onSurface, 0.38)
    property color bgColour: enabled ? Colours.palette.m3secondaryContainer : Qt.alpha(Colours.palette.m3onSurface, 0.1)

    property real pos: mouse.pressed
        ? Math.min(Math.max(mouse.pressStartPos + mouse.dragMovement, 0), 1)
        : visualPosition
    property real filledWidth: (width - handle.implicitWidth - handle.anchors.leftMargin) * pos

    signal interaction(real v)
    signal released(real v)

    implicitWidth: 80
    implicitHeight: 8

    contentItem: Item {
        anchors.fill: parent

        // TTY: a bar in text, `████▌░░░`, as many cells as fit
        TtyBar {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            visible: Colours.tty
            cells: Math.max(1, Math.floor(root.width / cellWidth))
            fraction: root.pos
        }

        StyledRect {
            id: remaining
            visible: !Colours.tty

            anchors.left: handle.right
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.spacing.extraSmall

            implicitHeight: root.trackHeight
            opacity: Math.min(width, 10) / 10

            radius: root.radius
            color: root.bgColour
        }

        StyledRect {
            visible: !Colours.tty
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 2

            implicitWidth: 4
            implicitHeight: 4
            opacity: remaining.opacity

            radius: Tokens.rounding.full
            color: root.fgColour
        }

        StyledRect {
            id: handle
            visible: !Colours.tty

            anchors.left: filled.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 2

            implicitWidth: root.handleWidth
            implicitHeight: mouse.pressed ? root.handleHeightPressed : root.handleHeight

            radius: Tokens.rounding.full
            color: root.fgColour

            Behavior on implicitHeight {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }

        StyledRect {
            id: filled
            visible: !Colours.tty

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            implicitWidth: root.filledWidth
            implicitHeight: root.trackHeight

            radius: root.radius
            color: root.fgColour
        }
    }

    MouseArea {
        id: mouse

        property real pressStartX: 0
        property real pressStartPos: 0
        property real dragMovement: 0

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        preventStealing: true
        implicitHeight: Math.max(18, root.handleHeightPressed)

        onPressed: e => {
            widthBehavior.enabled = false;
            pressStartX = e.x;
            const curPos = Math.min(Math.max(e.x / width, 0), 1);
            pressStartPos = curPos;
            dragMovement = 0;
            const actualVal = root.from + curPos * (root.to - root.from);
            root.interaction(actualVal);
        }
        onPositionChanged: e => {
            dragMovement = (e.x - pressStartX) / width;
            const curPos = Math.min(Math.max(pressStartPos + dragMovement, 0), 1);
            const actualVal = root.from + curPos * (root.to - root.from);
            if (root.interactionOnMove)
                root.interaction(actualVal);
        }
        onReleased: e => {
            const finalPos = Math.min(Math.max(pressStartPos + dragMovement, 0), 1);
            const actualVal = root.from + finalPos * (root.to - root.from);
            root.interaction(actualVal);
            root.released(actualVal);
            widthBehavior.enabled = true;
            dragMovement = 0;
        }
    }

    Behavior on filledWidth {
        id: widthBehavior
        enabled: !mouse.pressed
        Anim { type: Anim.FastEffects }
    }
}
