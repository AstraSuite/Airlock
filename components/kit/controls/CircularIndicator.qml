import QtQuick
import QtQuick.Templates
import "../"
import Astra.Airlock
import "../../../services"
BusyIndicator {
    id: root

    enum AnimType {
        Advance = 0,
        Retreat
    }

    enum AnimState {
        Stopped,
        Running,
        Completing
    }

    property real implicitSize: (Tokens.font.body.medium.pointSize || 12) * 3
    property real strokeWidth: Tokens.padding.extraSmall || 3
    property color fgColour: Colours.palette.m3primary
    property color bgColour: Qt.alpha(Colours.palette.m3secondaryContainer, 0.45)
    property alias color: root.fgColour
    property alias size: root.implicitSize

    property alias type: manager.indeterminateAnimationType
    readonly property alias progress: manager.progress

    property real internalStrokeWidth: strokeWidth
    property int animState: CircularIndicator.Running

    padding: 0
    implicitWidth: implicitSize
    implicitHeight: implicitSize

    Component.onCompleted: {
        if (running) {
            running = false;
            running = true;
        }
    }

    onRunningChanged: {
        if (running) {
            manager.completeEndProgress = 0;
            animState = CircularIndicator.Running;
        } else {
            if (animState == CircularIndicator.Running)
                animState = CircularIndicator.Completing;
        }
    }

    states: State {
        name: "stopped"
        when: !root.running

        PropertyChanges {
            target: root
            opacity: 0
            internalStrokeWidth: root.strokeWidth / 3
        }
    }

    transitions: Transition {
        Anim {
            type: Anim.DefaultEffects
            properties: "opacity,internalStrokeWidth"
            duration: manager.completeEndDuration
        }
    }

    contentItem: CircularProgress {
        anchors.fill: parent
        strokeWidth: root.internalStrokeWidth
        fgColour: root.fgColour
        bgColour: root.bgColour
        padding: root.padding
        rotation: manager.rotation
        startAngle: manager.startFraction * 360
        value: manager.endFraction - manager.startFraction
        hasEndIndicator: false
    }

    CircularIndicatorManager {
        id: manager
    }

    NumberAnimation {
        running: root.animState !== CircularIndicator.Stopped
        loops: Animation.Infinite
        target: manager
        property: "progress"
        from: 0
        to: 1
        duration: manager.duration
    }

    NumberAnimation {
        running: root.animState === CircularIndicator.Completing
        target: manager
        property: "completeEndProgress"
        from: 0
        to: 1
        duration: manager.completeEndDuration
        onFinished: {
            if (root.animState === CircularIndicator.Completing)
                root.animState = CircularIndicator.Stopped;
        }
    }
}
