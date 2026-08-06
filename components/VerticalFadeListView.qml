pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects

// ListView with smooth gradient alpha fade at the top and bottom scroll boundaries
ListView {
    id: root

    property real fadeAmount: 0.18
    property real topFadeOpacity: fadeShouldBeActive(true) ? 0.0 : 1.0
    property real bottomFadeOpacity: fadeShouldBeActive(false) ? 0.0 : 1.0

    function fadeShouldBeActive(isStart: bool): bool {
        if (contentHeight <= height) return false;
        if (isStart)
            return visibleArea.yPosition > 0.001;
        return (visibleArea.yPosition + visibleArea.heightRatio) < 0.999;
    }

    flickableDirection: Flickable.VerticalFlick
    orientation: ListView.Vertical
    boundsBehavior: Flickable.StopAtBounds

    layer.enabled: true
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: maskItem
        maskSpreadAtMin: 1
        maskThresholdMin: 0.5
    }

    Item {
        id: maskItem
        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, root.topFadeOpacity) }
                GradientStop { position: root.fadeAmount; color: Qt.rgba(0, 0, 0, 1.0) }
                GradientStop { position: 1.0 - root.fadeAmount; color: Qt.rgba(0, 0, 0, 1.0) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, root.bottomFadeOpacity) }
            }
        }
    }

    Behavior on topFadeOpacity { NumberAnimation { duration: 180 } }
    Behavior on bottomFadeOpacity { NumberAnimation { duration: 180 } }
}
