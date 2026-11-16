import QtQuick
import "../"
import Astra.Airlock
import "../../../services"
StyledRect {
    id: root

    enum ButtonType {
        Filled,
        Tonal,
        Text,
        Outlined
    }

    property bool checked: false
    property alias disabled: stateLayer.disabled
    property bool isToggle: false
    property bool isRound: false

    property bool radiusMorph: true
    property bool fillWidth: false

    property font font: Tokens.font.label.large
    property int type: ButtonBase.Filled

    property real padding: 0
    property real horizontalPadding: padding
    property real verticalPadding: padding

    readonly property alias pressed: stateLayer.pressed
    readonly property alias hovered: stateLayer.containsMouse
    readonly property alias stateLayer: stateLayer

    property color activeColour: Colours.palette.m3primary
    property color inactiveColour: Colours.palette.m3primary
    property color activeOnColour: Colours.palette.m3onPrimary
    property color inactiveOnColour: Colours.palette.m3onPrimary
    property color disabledColour: Qt.alpha(Colours.palette.m3onSurface, 0.1)
    property color disabledOnColour: Qt.alpha(Colours.palette.m3onSurface, 0.38)

    property bool internalChecked: false
    readonly property color onColour: disabled ? disabledOnColour : (internalChecked ? activeOnColour : inactiveOnColour)

    property real pressedRadius: Tokens.rounding.small
    property real checkedRadius: Tokens.rounding.medium
    property real defaultRadius: Tokens.rounding.large

    signal clicked()

    onCheckedChanged: internalChecked = checked

    radius: {
        if (radiusMorph && pressed)
            return pressedRadius;
        if (internalChecked)
            return checkedRadius;
        if (isRound)
            return (implicitHeight || height) / 2 * Math.min(1, Tokens.rounding.scale);
        return defaultRadius;
    }
    color: type === ButtonBase.Text ? "transparent" : (disabled ? disabledColour : (internalChecked ? activeColour : inactiveColour))
    border.width: type === ButtonBase.Outlined ? 1 : 0
    border.color: type === ButtonBase.Outlined ? (disabled ? disabledColour : Colours.palette.m3outline) : "transparent"

    StateLayer {
        id: stateLayer

        radius: parent.radius
        color: root.internalChecked ? root.activeOnColour : root.inactiveOnColour
        disabled: root.disabled
        onClicked: {
            if (root.isToggle)
                root.internalChecked = !root.internalChecked;
            root.clicked();
        }
    }

    Behavior on radius {
        Anim {
            type: Anim.DefaultEffects
        }
    }
    Behavior on color {
        CAnim {}
    }
}
