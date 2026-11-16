import QtQuick
import QtQuick.Controls
import Astra.Airlock
import "../../services"
ToolTip {
    id: root

    property color textColor: Colours.palette.m3onSurface
    property color backgroundColor: Colours.palette.m3surfaceContainerHighest
    property color borderColor: Qt.alpha(Colours.palette.m3outlineVariant, 0.4)

    delay: Tokens.anim.durations.normal
    timeout: Tokens.anim.durations.extraLarge * 5

    topPadding: Tokens.padding.extraSmall
    bottomPadding: Tokens.padding.extraSmall
    leftPadding: Tokens.padding.small
    rightPadding: Tokens.padding.small

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    contentItem: StyledText {
        text: root.text
        font: Tokens.font.label.small
        color: root.textColor
    }

    background: StyledRect {
        radius: Tokens.rounding.small
        color: root.backgroundColor
        border.color: root.borderColor
        border.width: 1
    }

    enter: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: Tokens.anim.durations.expressiveFastEffects
            easing: Tokens.anim.expressiveFastEffects
        }
    }

    exit: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1.0
            to: 0.0
            duration: Tokens.anim.durations.expressiveFastEffects
            easing: Tokens.anim.expressiveFastEffects
        }
    }
}
