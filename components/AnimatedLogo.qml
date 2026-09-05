pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import "../services"

// Interactive Animated Logo adapted for Astra Airlock from Foundry
// Features entrance animation, continuous ambient breathing, and interactive click recoil & energy surge
Item {
    id: root

    readonly property real designWidth: 825
    readonly property real designHeight: 1000
    property bool skipIntroAnimation: false

    property real beamProgress: 1.0
    property real badgeProgress: 1.0
    property real glyphProgress: 1.0
    property real clickTilt: 0.0
    property real clickSurge: 0.0

    implicitWidth: 128
    implicitHeight: 128

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

                // Vertical pillar beam expansion
                NumberAnimation {
                    target: root
                    property: "beamProgress"
                    from: 0.0
                    to: 1.0
                    duration: 650
                    easing.type: Easing.OutCubic
                }

                // Shield badge entrance with overshoot
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

                // Central Airlock glyph illumination
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

        // 1. Vertical Airlock Pillar / Beam in the background
        Item {
            id: verticalPillar
            visible: false
            width: root.designWidth
            height: root.designHeight
            z: 0

            opacity: Math.min(1.0, root.beamProgress * 1.5)

            transform: [
                Scale {
                    origin.x: 412.5
                    origin.y: 500
                    xScale: 0.9 + root.clickSurge * 0.15
                    yScale: root.beamProgress
                }
            ]

            Rectangle {
                x: 238
                y: 0
                width: 350
                height: 1000
                radius: 45
                color: Qt.alpha(Colours.palette.m3primary, 0.18 + root.clickSurge * 0.25)
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        // 2. Airlock Shield & Core Emblem Group
        Item {
            id: badgeGroup
            width: root.designWidth
            height: root.designHeight
            z: 1

            opacity: Math.min(1.0, root.badgeProgress * 1.8)

            transform: [
                Rotation {
                    origin.x: 412.5
                    origin.y: 500
                    angle: (1.0 - root.badgeProgress) * -18 + root.clickTilt
                },
                Scale {
                    origin.x: 412.5
                    origin.y: 500
                    xScale: 0.6 + 0.4 * root.badgeProgress + root.clickSurge * 0.06
                    yScale: 0.6 + 0.4 * root.badgeProgress + root.clickSurge * 0.06
                }
            ]

            // Outer dark octagonal capsule rim
            Shape {
                id: outerBadge
                width: root.designWidth
                height: root.designHeight
                z: 1
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: Colours.palette.m3onSurface
                    strokeColor: "transparent"

                    PathSvg {
                        path: "M228.457 100.18C236.896 91.741 248.342 87 260.277 87L564.724 87C576.658 87 588.104 91.7411 596.543 100.18L811.82 315.457C820.259 323.896 825 335.342 825 347.277V651.724C825 663.658 820.259 675.104 811.82 683.543L596.543 898.82C588.104 907.259 576.658 912 564.724 912H260.277C248.342 912 236.896 907.259 228.457 898.82L13.1802 683.543C4.74104 675.104 1.59964e-06 663.658 1.54265e-06 651.724L8.89991e-08 347.277C3.20139e-08 335.342 4.74106 323.896 13.1802 315.457L228.457 100.18Z"
                    }
                }
            }

            // Inner primary octagonal shield
            Shape {
                id: innerBadge
                width: root.designWidth
                height: root.designHeight
                z: 2
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: Colours.palette.m3primary
                    strokeColor: "transparent"

                    PathSvg {
                        path: "M269.878 200.18C278.317 191.741 289.763 187 301.698 187L523.302 187C535.237 187 546.683 191.741 555.122 200.18L711.82 356.878C720.259 365.317 725 376.763 725 388.698V610.302C725 622.237 720.259 633.683 711.82 642.122L555.122 798.82C546.683 807.259 535.237 812 523.302 812H301.698C289.763 812 278.317 807.259 269.878 798.82L113.18 642.122C104.741 633.683 100 622.237 100 610.302L100 388.698C100 376.763 104.741 365.317 113.18 356.878L269.878 200.18Z"
                    }
                }
            }

            // Central Airlock emblem glyph
            Shape {
                id: glyph
                width: root.designWidth
                height: root.designHeight
                z: 3
                opacity: root.glyphProgress
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: Colours.palette.m3tertiary
                    strokeColor: "transparent"

                    PathSvg {
                        path: "M163 671.053V597.368C163 582.456 166.838 568.75 174.513 556.25C182.189 543.75 192.386 534.211 205.105 527.632C232.298 514.035 259.93 503.838 288 497.039C316.07 490.241 344.579 486.842 373.526 486.842C382.298 486.842 391.07 487.171 399.842 487.829C408.614 488.487 417.386 489.474 426.158 490.789C424.404 516.228 429.009 540.241 439.974 562.829C450.939 585.417 466.947 603.947 488 618.421V671.053H163ZM584.053 750L544.579 710.526V588.158C525.281 582.456 509.491 571.601 497.211 555.592C484.93 539.583 478.789 521.053 478.789 500C478.789 474.561 487.781 452.851 505.763 434.868C523.746 416.886 545.456 407.895 570.895 407.895C596.333 407.895 618.044 416.886 636.026 434.868C654.009 452.851 663 474.561 663 500C663 519.737 657.408 537.281 646.224 552.632C635.039 567.982 620.895 578.947 603.789 585.526L636.684 618.421L597.211 657.895L636.684 697.368L584.053 750ZM373.526 460.526C344.579 460.526 319.798 450.219 299.184 429.605C278.57 408.991 268.263 384.211 268.263 355.263C268.263 326.316 278.57 301.535 299.184 280.921C319.798 260.307 344.579 250 373.526 250C402.474 250 427.254 260.307 447.868 280.921C468.482 301.535 478.789 326.316 478.789 355.263C478.789 384.211 468.482 408.991 447.868 429.605C427.254 450.219 402.474 460.526 373.526 460.526ZM589.645 505.592C594.689 500.548 597.211 494.298 597.211 486.842C597.211 479.386 594.689 473.136 589.645 468.092C584.601 463.048 578.351 460.526 570.895 460.526C563.439 460.526 557.189 463.048 552.145 468.092C547.101 473.136 544.579 479.386 544.579 486.842C544.579 494.298 547.101 500.548 552.145 505.592C557.189 510.636 563.439 513.158 570.895 513.158C578.351 513.158 584.601 510.636 589.645 505.592Z"
                    }
                }
            }
        }
    }
}
