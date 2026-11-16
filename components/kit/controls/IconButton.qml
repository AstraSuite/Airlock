import QtQuick
import "../"
import Astra.Airlock
import "../../../services"
ButtonBase {
    id: root

    property alias icon: iconLabel.text
    property alias fontStyle: iconLabel.fontStyle
    readonly property alias iconLabel: iconLabel

    padding: Tokens.padding.small
    isRound: true
    implicitWidth: 36
    implicitHeight: 36

    activeColour: type === ButtonBase.Filled ? Colours.palette.m3primary : Colours.palette.m3secondary
    inactiveColour: {
        if (!isToggle && type === ButtonBase.Filled)
            return Colours.palette.m3primary;
        if (type === ButtonBase.Tonal)
            return Colours.palette.m3secondaryContainer;
        if (type === ButtonBase.Outlined)
            return "transparent";
        return Colours.tPalette.m3surfaceContainer;
    }
    activeOnColour: {
        if (type === ButtonBase.Text || type === ButtonBase.Outlined)
            return Colours.palette.m3primary;
        return type === ButtonBase.Filled ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondary;
    }
    inactiveOnColour: {
        if (!isToggle && type === ButtonBase.Filled)
            return Colours.palette.m3onPrimary;
        if (type === ButtonBase.Text || type === ButtonBase.Outlined)
            return Colours.palette.m3onSurfaceVariant;
        return type === ButtonBase.Filled ? Colours.palette.m3onSurface : Colours.palette.m3onSecondaryContainer;
    }

    MaterialIcon {
        id: iconLabel

        anchors.centerIn: parent
        color: root.onColour
        fontStyle: Tokens.font.icon.small
    }
}
