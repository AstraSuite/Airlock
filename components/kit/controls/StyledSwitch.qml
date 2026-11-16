import QtQuick
import QtQuick.Shapes
import QtQuick.Templates as T
import "../"
import Astra.Airlock
import "../../../services"
T.Switch {
    id: root

    property int cLayer: 1
    property bool disabled: false

    enabled: !disabled

    implicitWidth: implicitIndicatorWidth
    implicitHeight: implicitIndicatorHeight

    // TTY: a checkbox in text, `[x]` or `[ ]`, as KiiteShell draws its switches
    indicator: StyledRect {
        radius: Tokens.rounding.full
        color: {
            if (Colours.tty)
                return "transparent";
            if (root.disabled)
                return root.checked ? Qt.alpha(Colours.palette.m3onSurface, 0.12) : Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.38);
            return root.checked ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHighest;
        }

        implicitWidth: Colours.tty ? ttyMark.implicitWidth : implicitHeight * 1.75
        implicitHeight: Colours.tty ? ttyMark.implicitHeight : 28

        StyledText {
            id: ttyMark
            visible: Colours.tty
            text: root.checked ? "[x]" : "[ ]"
            color: root.checked ? Colours.palette.m3primary : root.hovered ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3outline
            opacity: root.disabled ? 0.5 : 1
            font: Tokens.font.body.medium
        }

        Behavior on color {
            CAnim {}
        }

        StyledRect {
            id: thumbRect
            visible: !Colours.tty
            readonly property real nonAnimWidth: root.pressed ? implicitHeight * 1.15 : implicitHeight

            radius: Tokens.rounding.full
            color: {
                if (root.disabled)
                    return root.checked ? Colours.palette.m3surface : Qt.alpha(Colours.palette.m3onSurface, 0.12);
                return root.checked ? Colours.palette.m3onPrimary : Colours.palette.m3outline;
            }

            x: root.checked ? (parent.implicitWidth - nonAnimWidth - 3) : 3
            implicitWidth: nonAnimWidth
            implicitHeight: parent.implicitHeight - 6
            anchors.verticalCenter: parent.verticalCenter

            Behavior on x {
                Anim {
                    type: Anim.FastSpatial
                }
            }
            Behavior on implicitWidth {
                Anim {
                    type: Anim.FastSpatial
                }
            }
            Behavior on color {
                CAnim {}
            }

            StyledRect {
                anchors.fill: parent
                radius: parent.radius
                color: root.checked ? Colours.palette.m3primary : Colours.palette.m3onSurface
                opacity: root.pressed ? 0.12 : (root.hovered ? 0.08 : 0.0)

                Behavior on opacity {
                    Anim {
                        type: Anim.FastEffects
                    }
                }
            }

            Shape {
                id: icon

                property point start1: {
                    if (root.pressed)
                        return Qt.point(width * 0.2, height / 2);
                    if (root.checked)
                        return Qt.point(width * 0.15, height / 2);
                    return Qt.point(width * 0.2, height * 0.2);
                }
                property point end1: {
                    if (root.pressed) {
                        if (root.checked)
                            return Qt.point(width * 0.4, height / 2);
                        return Qt.point(width * 0.8, height / 2);
                    }
                    if (root.checked)
                        return Qt.point(width * 0.4, height * 0.72);
                    return Qt.point(width * 0.8, height * 0.8);
                }
                property point start2: {
                    if (root.pressed) {
                        if (root.checked)
                            return Qt.point(width * 0.4, height / 2);
                        return Qt.point(width * 0.2, height / 2);
                    }
                    if (root.checked)
                        return Qt.point(width * 0.4, height * 0.72);
                    return Qt.point(width * 0.2, height * 0.8);
                }
                property point end2: {
                    if (root.pressed)
                        return Qt.point(width * 0.8, height / 2);
                    if (root.checked)
                        return Qt.point(width * 0.85, height * 0.25);
                    return Qt.point(width * 0.8, height * 0.2);
                }

                anchors.centerIn: parent
                width: 14
                height: 14
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeWidth: 2
                    strokeColor: {
                        if (root.disabled)
                            return root.checked ? Colours.palette.m3outline : Colours.palette.m3surfaceContainer;
                        return root.checked ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHighest;
                    }
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap

                    startX: icon.start1.x
                    startY: icon.start1.y

                    PathLine {
                        x: icon.end1.x
                        y: icon.end1.y
                    }
                    PathMove {
                        x: icon.start2.x
                        y: icon.start2.y
                    }
                    PathLine {
                        x: icon.end2.x
                        y: icon.end2.y
                    }

                    Behavior on strokeColor {
                        CAnim {}
                    }
                }

                Behavior on start1 {
                    PropertyAnimation {
                        duration: Tokens.anim.durations.expressiveFastSpatial
                        easing: Tokens.anim.expressiveFastSpatial
                    }
                }
                Behavior on end1 {
                    PropertyAnimation {
                        duration: Tokens.anim.durations.expressiveFastSpatial
                        easing: Tokens.anim.expressiveFastSpatial
                    }
                }
                Behavior on start2 {
                    PropertyAnimation {
                        duration: Tokens.anim.durations.expressiveFastSpatial
                        easing: Tokens.anim.expressiveFastSpatial
                    }
                }
                Behavior on end2 {
                    PropertyAnimation {
                        duration: Tokens.anim.durations.expressiveFastSpatial
                        easing: Tokens.anim.expressiveFastSpatial
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: false
    }
}
