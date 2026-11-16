import QtQuick
import QtQuick.Layouts
import "../"
import Astra.Airlock
import "../../../services"
ButtonBase {
    id: root

    property alias icon: iconLabel.text
    property alias text: label.text
    property alias spacing: row.spacing

    readonly property alias iconLabel: iconLabel
    readonly property alias label: label

    horizontalPadding: Tokens.padding.medium
    verticalPadding: Tokens.padding.small
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
            return Colours.palette.m3primary;
        return type === ButtonBase.Filled ? Colours.palette.m3onSurface : Colours.palette.m3onSecondaryContainer;
    }

    implicitWidth: Math.max(80, row.implicitWidth + horizontalPadding * 2)

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        MaterialIcon {
            id: iconLabel

            Layout.alignment: Qt.AlignVCenter
            color: root.onColour
            fontStyle: Tokens.font.icon.small
        }

        StyledText {
            id: label

            Layout.alignment: Qt.AlignVCenter
            color: root.onColour
            font: root.font
        }
    }
}
