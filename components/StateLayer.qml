pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import "../services"

// Material 3 StateLayer / Ripple Click Effect matching Caelestia shell (components/StateLayer.qml)
MouseArea {
    id: root

    property bool disabled: false
    property bool showHoverBackground: true
    property bool manualPressOverride: false
    property bool manualHoverOverride: false
    readonly property alias rect: base

    property bool shapeMorph: false
    property real stateOpacity: (containsMouse || manualHoverOverride) && showHoverBackground ? 0.08 : 0

    property real pressX: width / 2
    property real pressY: height / 2
    property real circleRadius: 0

    property alias color: base.color
    property alias radius: base.radius
    property alias topLeftRadius: base.topLeftRadius
    property alias topRightRadius: base.topRightRadius
    property alias bottomLeftRadius: base.bottomLeftRadius
    property alias bottomRightRadius: base.bottomRightRadius

    readonly property real endRadius: {
        const d1 = distSq(0, 0);
        const d2 = distSq(width, 0);
        const d3 = distSq(0, height);
        const d4 = distSq(width, height);
        return (Math.sqrt(Math.max(d1, d2, d3, d4)) + (shapeMorph ? 24 : 0)) * 1.3;
    }
    property real endRadiusAtPress: 0

    function distSq(x, y) {
        return (pressX - x) ** 2 + (pressY - y) ** 2;
    }

    function clamp(r) {
        return Math.max(0, Math.min(r, width / 2, height / 2));
    }

    function clampVal(val, minVal, maxVal) {
        return Math.max(minVal, Math.min(val, maxVal));
    }

    function press(x, y) {
        pressX = x;
        pressY = y;
        fadeAnim.complete();
        circleRadius = 0;
        circle.opacity = 0.1;
        rippleAnim.restart();
        endRadiusAtPress = endRadius;
    }

    anchors.fill: parent
    enabled: !disabled
    cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
    hoverEnabled: true

    onPressed: e => press(e.x, e.y)

    onPressedChanged: {
        if (!(pressed || manualPressOverride) && !rippleAnim.running && circle.opacity > 0)
            fadeAnim.start();
    }

    onManualPressOverrideChanged: {
        if (!(pressed || manualPressOverride) && circleRadius > endRadiusAtPress * 0.99 && !fadeAnim.running)
            fadeAnim.start();
    }

    onCircleRadiusChanged: {
        if (!(pressed || manualPressOverride) && circleRadius > endRadiusAtPress * 0.99 && !fadeAnim.running)
            fadeAnim.start();
    }

    NumberAnimation {
        id: rippleAnim
        alwaysRunToEnd: true
        target: root
        property: "circleRadius"
        to: root.endRadius
        duration: 400
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: fadeAnim
        target: circle
        property: "opacity"
        to: 0
        duration: 350
        easing.type: Easing.OutQuad
    }

    StyledRect {
        id: base
        anchors.fill: parent
        opacity: root.stateOpacity
        color: Colours.palette.m3onSurface
        radius: root.parent && root.parent.radius !== undefined ? root.parent.radius : 0
        topLeftRadius: root.parent && root.parent.topLeftRadius !== undefined ? root.parent.topLeftRadius : (radius || 0)
        topRightRadius: root.parent && root.parent.topRightRadius !== undefined ? root.parent.topRightRadius : (radius || 0)
        bottomLeftRadius: root.parent && root.parent.bottomLeftRadius !== undefined ? root.parent.bottomLeftRadius : (radius || 0)
        bottomRightRadius: root.parent && root.parent.bottomRightRadius !== undefined ? root.parent.bottomRightRadius : (radius || 0)

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    }

    Shape {
        id: circle
        anchors.fill: parent
        opacity: 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: base.color
            fillGradient: RadialGradient {
                centerX: root.pressX
                centerY: root.pressY
                centerRadius: root.circleRadius
                focalX: centerX
                focalY: centerY

                GradientStop {
                    position: 0
                    color: Qt.alpha(base.color, 1)
                }
                GradientStop {
                    position: root.clampVal(1 - 0.2 * root.endRadius / Math.max(0.001, root.circleRadius), 0.01, 0.99)
                    color: Qt.alpha(base.color, 1)
                }
                GradientStop {
                    position: 1
                    color: Qt.alpha(base.color, root.clampVal((root.circleRadius / Math.max(0.001, root.endRadius) - 0.9) / 0.1, 0, 1))
                }
            }

            startX: root.clamp(base.topLeftRadius)
            startY: 0

            PathLine {
                x: root.width - root.clamp(base.topRightRadius)
                y: 0
            }
            PathArc {
                relativeX: root.clamp(base.topRightRadius)
                relativeY: root.clamp(base.topRightRadius)
                radiusX: root.clamp(base.topRightRadius)
                radiusY: root.clamp(base.topRightRadius)
            }
            PathLine {
                x: root.width
                y: root.height - root.clamp(base.bottomRightRadius)
            }
            PathArc {
                relativeX: -root.clamp(base.bottomRightRadius)
                relativeY: root.clamp(base.bottomRightRadius)
                radiusX: root.clamp(base.bottomRightRadius)
                radiusY: root.clamp(base.bottomRightRadius)
            }
            PathLine {
                x: root.clamp(base.bottomLeftRadius)
                y: root.height
            }
            PathArc {
                relativeX: -root.clamp(base.bottomLeftRadius)
                relativeY: -root.clamp(base.bottomLeftRadius)
                radiusX: root.clamp(base.bottomLeftRadius)
                radiusY: root.clamp(base.bottomLeftRadius)
            }
            PathLine {
                x: 0
                y: root.clamp(base.topLeftRadius)
            }
            PathArc {
                x: root.clamp(base.topLeftRadius)
                y: 0
                radiusX: root.clamp(base.topLeftRadius)
                radiusY: root.clamp(base.topLeftRadius)
            }
        }
    }
}
