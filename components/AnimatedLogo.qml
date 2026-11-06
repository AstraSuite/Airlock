pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import "../services"

// Interactive Animated Logo for Astra Airlock: a bolted airlock hatch with a
// porthole window and a user silhouette inside, matching the porthole-hatch
// mark in assets/astra-airlock.svg.
// Features entrance animation, continuous ambient breathing, and interactive click recoil & energy surge
Item {
    id: root

    readonly property real designWidth: 512
    readonly property real designHeight: 512
    property bool skipIntroAnimation: false

    property real beamProgress: 1.0
    property real badgeProgress: 1.0
    property real glyphProgress: 1.0
    property real clickTilt: 0.0
    property real clickSurge: 0.0

    implicitWidth: 128
    implicitHeight: 128

    readonly property var boltAngles: [0, 45, 90, 135, 180, 225, 270, 315]

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!introAnim.running && !clickPulseAnim.running) {
                clickPulseAnim.restart();
            }
        }
    }

    // Interactive recoil & energy surge animation on click
    SequentialAnimation {
        id: clickPulseAnim
        running: false

        ParallelAnimation {
            // Emblem tilts and recoils
            SequentialAnimation {
                NumberAnimation {
                    target: root
                    property: "clickTilt"
                    from: 0
                    to: 12
                    duration: 180
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: root
                    property: "clickTilt"
                    from: 12
                    to: -6
                    duration: 220
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: root
                    property: "clickTilt"
                    from: -6
                    to: 0
                    duration: 280
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.4
                }
            }

            // Energy beam surge
            SequentialAnimation {
                NumberAnimation {
                    target: root
                    property: "clickSurge"
                    from: 0.0
                    to: 1.0
                    duration: 200
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: root
                    property: "clickSurge"
                    from: 1.0
                    to: 0.0
                    duration: 450
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                }
            }

            // Overall subtle bounce
            SequentialAnimation {
                NumberAnimation {
                    target: logo
                    property: "scale"
                    from: Math.min(root.width / root.designWidth, root.height / root.designHeight)
                    to: Math.min(root.width / root.designWidth, root.height / root.designHeight) * 1.10
                    duration: 190
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: logo
                    property: "scale"
                    from: Math.min(root.width / root.designWidth, root.height / root.designHeight) * 1.10
                    to: Math.min(root.width / root.designWidth, root.height / root.designHeight)
                    duration: 420
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.3
                }
            }
        }

        ScriptAction {
            script: {
                root.clickTilt = 0;
                root.clickSurge = 0;
            }
        }
    }

    Item {
        id: logo

        implicitWidth: root.designWidth
        implicitHeight: root.designHeight

        anchors.centerIn: parent
        scale: Math.min(root.width / root.designWidth, root.height / root.designHeight)
        transformOrigin: Item.Center

        rotation: 0.0
        opacity: 1.0

        SequentialAnimation {
            id: introAnim
            running: !root.skipIntroAnimation

            ScriptAction {
                script: {
                    root.beamProgress = 0.0;
                    root.badgeProgress = 0.0;
                    root.glyphProgress = 0.0;
                    root.clickTilt = 0.0;
                    root.clickSurge = 0.0;
                    logo.opacity = 0.0;
                }
            }

            ParallelAnimation {
                // Fade in
                NumberAnimation {
                    target: logo
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: 450
                    easing.type: Easing.InOutQuad
                }

                // Glow bloom expansion behind the hatch
                NumberAnimation {
                    target: root
                    property: "beamProgress"
                    from: 0.0
                    to: 1.0
                    duration: 650
                    easing.type: Easing.OutCubic
                }

                // Hatch rim entrance with overshoot
                SequentialAnimation {
                    PauseAnimation { duration: 150 }
                    NumberAnimation {
                        target: root
                        property: "badgeProgress"
                        from: 0.0
                        to: 1.0
                        duration: 750
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.25
                    }
                }

                // User-in-porthole glyph illumination
                SequentialAnimation {
                    PauseAnimation { duration: 380 }
                    NumberAnimation {
                        target: root
                        property: "glyphProgress"
                        from: 0.0
                        to: 1.0
                        duration: 550
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        // 1. Soft glow bloom behind the hatch
        Item {
            id: glowBloom
            visible: false
            width: root.designWidth
            height: root.designHeight
            z: 0

            opacity: Math.min(1.0, root.beamProgress * 1.5)

            transform: [
                Scale {
                    origin.x: 256
                    origin.y: 256
                    xScale: 0.9 + root.clickSurge * 0.15
                    yScale: root.beamProgress
                }
            ]

            Rectangle {
                anchors.centerIn: parent
                width: 464
                height: 464
                radius: width / 2
                color: Qt.alpha(Colours.palette.m3primary, 0.18 + root.clickSurge * 0.25)
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        // 2. Hatch, bolts, porthole & user glyph
        Item {
            id: badgeGroup
            width: root.designWidth
            height: root.designHeight
            z: 1

            opacity: Math.min(1.0, root.badgeProgress * 1.8)

            transform: [
                Rotation {
                    origin.x: 256
                    origin.y: 256
                    angle: (1.0 - root.badgeProgress) * -18 + root.clickTilt
                },
                Scale {
                    origin.x: 256
                    origin.y: 256
                    xScale: 0.6 + 0.4 * root.badgeProgress + root.clickSurge * 0.06
                    yScale: 0.6 + 0.4 * root.badgeProgress + root.clickSurge * 0.06
                }
            ]

            // Outer hatch rim
            Rectangle {
                id: outerBadge
                anchors.centerIn: parent
                width: 464
                height: 464
                radius: width / 2
                color: Colours.palette.m3onSurface
                z: 1
            }

            // Bolt ring
            Repeater {
                model: root.boltAngles
                delegate: Rectangle {
                    required property real modelData

                    readonly property real rad: modelData * Math.PI / 180
                    readonly property real orbit: 175

                    x: 256 + Math.cos(rad) * orbit - width / 2
                    y: 256 + Math.sin(rad) * orbit - height / 2
                    width: 26
                    height: 26
                    radius: width / 2
                    z: 1
                    color: Qt.darker(Colours.palette.m3onSurface, 1.4)
                }
            }

            // Porthole window
            Rectangle {
                id: innerBadge
                anchors.centerIn: parent
                width: 320
                height: 320
                radius: width / 2
                color: Colours.palette.m3primary
                z: 2
            }

            // User silhouette inside the porthole
            Item {
                id: glyph
                anchors.fill: parent
                z: 3
                opacity: root.glyphProgress

                Rectangle {
                    // Head: circle at (256, 215.8), r=33
                    x: 256 - 33
                    y: 215.8 - 33
                    width: 66
                    height: 66
                    radius: width / 2
                    color: Colours.palette.m3onPrimary
                }

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        fillColor: Colours.palette.m3onPrimary
                        strokeColor: "transparent"

                        PathSvg {
                            path: "M187.8 330.2a68.2 55 0 0 1 136.4 0Z"
                        }
                    }
                }
            }
        }
    }
}
