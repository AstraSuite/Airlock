import QtQuick
import QtQuick.Shapes
import "../"
import Astra.Airlock
import "../../../services"
Item {
    id: root

    property real value: 0
    property int startAngle: -90
    property int sweepAngle: 360
    property int strokeWidth: Tokens.padding.small
    property int padding: 0
    property int spacing: Tokens.spacing.small
    property color fgColour: Colours.palette.m3primary
    property color bgColour: Colours.palette.m3secondaryContainer
    property bool hasEndIndicator: false

    readonly property real size: Math.min(width, height)
    readonly property real arcRadius: Math.max(1, (size - padding - strokeWidth * 2) / 2)
    property real clampedVal: Math.max(1 / 360, Math.min(1, isNaN(value) ? 0 : value))
    readonly property real gapAngle: ((spacing + strokeWidth) / (arcRadius || 1)) * (180 / Math.PI)
    readonly property real dotAngleRad: (startAngle + sweepAngle - gapAngle * (sweepAngle < 360 ? 0 : 1)) * Math.PI / 180

    implicitWidth: Tokens.font.body.medium.pointSize * 3
    implicitHeight: Tokens.font.body.medium.pointSize * 3

    // Background track arc
    Shape {
        id: bgShape
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        asynchronous: true
        opacity: Math.min(1, remainingArc.sweepAngle)

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.bgColour
            strokeWidth: Math.min(1, remainingArc.sweepAngle) * root.strokeWidth
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                id: remainingArc
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                centerX: root.size / 2
                centerY: root.size / 2
                startAngle: root.startAngle + root.clampedVal * root.sweepAngle + root.gapAngle
                sweepAngle: Math.max(1 / 360, root.sweepAngle * (1 - root.clampedVal) - root.gapAngle * (root.sweepAngle < 360 ? 1 : 2))
            }
        }
    }

    // Active foreground arc
    Shape {
        id: fgShape
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        asynchronous: true

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.fgColour
            strokeWidth: root.strokeWidth
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                centerX: root.size / 2
                centerY: root.size / 2
                startAngle: root.startAngle
                sweepAngle: root.clampedVal * root.sweepAngle
            }
        }
    }

    // End indicator dot
    Loader {
        id: dot
        active: root.hasEndIndicator
        x: root.size / 2 + root.arcRadius * Math.cos(root.dotAngleRad) - width / 2
        y: root.size / 2 + root.arcRadius * Math.sin(root.dotAngleRad) - height / 2

        sourceComponent: StyledRect {
            radius: Tokens.rounding.full
            color: root.fgColour
            implicitWidth: Math.min(4, root.strokeWidth)
            implicitHeight: Math.min(4, root.strokeWidth)
        }
    }
}
