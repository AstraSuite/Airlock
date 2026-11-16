import QtQuick
import QtQuick.Templates as T
import Astra.Airlock
import "../../services"
T.ScrollBar {
    id: root

    required property Flickable flickable
    property bool shouldBeActive: false
    property real nonAnimPosition: 0
    property bool animating: false
    property bool _updatingFromFlickable: false
    property bool _updatingFromUser: false
    property bool animatePosition: true

    readonly property bool isVertical: root.orientation === Qt.Vertical

    onHoveredChanged: {
        if (hovered)
            shouldBeActive = true;
        else
            shouldBeActive = flickable.moving;
    }

    onPositionChanged: {
        if (_updatingFromUser) {
            _updatingFromUser = false;
            return;
        }
        if (position === nonAnimPosition) {
            animating = false;
            return;
        }
        if (!animating && !_updatingFromFlickable && !fullMouse.pressed) {
            nonAnimPosition = position;
        }
    }

    Component.onCompleted: {
        if (flickable) {
            const contentLen = isVertical ? flickable.contentHeight : flickable.contentWidth;
            const len = isVertical ? flickable.height : flickable.width;
            if (contentLen > len) {
                const pos = isVertical ? flickable.contentY : flickable.contentX;
                nonAnimPosition = Math.max(0, Math.min(1, pos / (contentLen - len)));
            }
        }
    }
    
    readonly property int barThickness: Tokens.padding.extraSmall
    readonly property int grabThickness: Tokens.padding.medium

    implicitWidth: isVertical ? grabThickness : 0
    implicitHeight: isVertical ? 0 : grabThickness

    contentItem: Item {

        MouseArea {
            id: mouse

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        StyledRect {
            id: bar

            anchors.right: root.isVertical ? parent.right : undefined
            anchors.left: root.isVertical ? undefined : parent.left
            anchors.top: root.isVertical ? parent.top : undefined
            anchors.bottom: parent.bottom
            width: root.isVertical ? root.barThickness : parent.width
            height: root.isVertical ? parent.height : root.barThickness
            
            opacity: {
                if (root.size === 1)
                    return 0;
                if (fullMouse.pressed)
                    return 1;
                if (mouse.containsMouse)
                    return 0.8;
                if (root.policy === T.ScrollBar.AlwaysOn || root.shouldBeActive)
                    return 0.6;
                return 0;
            }
            radius: Tokens.rounding.full
            color: Colours.palette.m3secondary

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    Connections {
        function onContentYChanged() { if (root.isVertical) updatePos(); }
        function onContentXChanged() { if (!root.isVertical) updatePos(); }

        function updatePos() {
            if (!root.animating && !fullMouse.pressed && root.flickable) {
                root._updatingFromFlickable = true;
                const contentLen = root.isVertical ? root.flickable.contentHeight : root.flickable.contentWidth;
                const len = root.isVertical ? root.flickable.height : root.flickable.width;
                if (contentLen > len) {
                    const pos = root.isVertical ? root.flickable.contentY : root.flickable.contentX;
                    root.nonAnimPosition = Math.max(0, Math.min(1, pos / (contentLen - len)));
                } else {
                    root.nonAnimPosition = 0;
                }
                root._updatingFromFlickable = false;
            }
        }

        target: root.flickable
    }

    Connections {
        function onMovingChanged() {
            if (root.flickable && root.flickable.moving)
                root.shouldBeActive = true;
            else
                hideDelay.restart();
        }

        target: root.flickable
    }

    Timer {
        id: hideDelay

        interval: 600
        onTriggered: root.shouldBeActive = (root.flickable && root.flickable.moving) || root.hovered
    }

    MouseArea {
        id: fullMouse

        anchors.fill: parent
        preventStealing: true

        function updateFlickable(newPos) {
            if (root.flickable) {
                const contentLen = root.isVertical ? root.flickable.contentHeight : root.flickable.contentWidth;
                const len = root.isVertical ? root.flickable.height : root.flickable.width;
                if (contentLen > len) {
                    const maxContentPos = contentLen - len;
                    const maxPos = 1 - root.size;
                    const contentPos = maxPos > 0 ? (newPos / maxPos) * maxContentPos : 0;
                    const finalPos = Math.max(0, Math.min(maxContentPos, contentPos));
                    if (root.isVertical)
                        root.flickable.contentY = finalPos;
                    else
                        root.flickable.contentX = finalPos;
                }
            }
        }

        onPressed: event => {
            root.animating = true;
            root._updatingFromUser = true;
            const evPos = root.isVertical ? event.y : event.x;
            const rLen = root.isVertical ? root.height : root.width;
            const newPos = Math.max(0, Math.min(1 - root.size, evPos / rLen - root.size / 2));
            root.nonAnimPosition = newPos;
            updateFlickable(newPos);
        }

        onPositionChanged: event => {
            root._updatingFromUser = true;
            const evPos = root.isVertical ? event.y : event.x;
            const rLen = root.isVertical ? root.height : root.width;
            const newPos = Math.max(0, Math.min(1 - root.size, evPos / rLen - root.size / 2));
            root.nonAnimPosition = newPos;
            updateFlickable(newPos);
        }
    }

    Behavior on position {
        enabled: root.animatePosition && !fullMouse.pressed

        Anim {}
    }
}
