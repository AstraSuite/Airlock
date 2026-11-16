import QtQuick
import QtQuick.Layouts
import Astra.Airlock
import "../../../services"
import "../"

Row {
    id: root

    enum Type {
        Filled,
        Tonal,
        Elevated
    }

    property real horizontalPadding: Tokens.padding.medium
    property real verticalPadding: Tokens.padding.small
    property int type: SplitButton.Filled
    property bool disabled
    property string fallbackIcon
    property string fallbackText
    property real minLeftWidth

    property alias menuItems: menu.items
    property alias active: menu.active
    property alias expanded: menu.expanded
    readonly property alias menu: menu
    readonly property alias iconLabel: iconLabel
    readonly property alias label: label
    readonly property alias stateLayer: stateLayer
    readonly property alias textRow: textRow
    readonly property alias expandBtn: expandBtn

    // Contrast fix: Elevate tonal/surface container tokens above the parent surface
    property color colour: {
        switch (type) {
            case SplitButton.Filled: return Colours.palette.m3primary
            case SplitButton.Elevated: return Colours.palette.m3surfaceContainerHighest
            case SplitButton.Tonal:
            default: return Colours.palette.m3secondaryContainer
        }
    }
    property color textColour: {
        switch (type) {
            case SplitButton.Filled: return Colours.palette.m3onPrimary
            case SplitButton.Elevated: return Colours.palette.m3onSurface
            case SplitButton.Tonal:
            default: return Colours.palette.m3onSecondaryContainer
        }
    }
    property color disabledColour: Qt.alpha(Colours.palette.m3onSurface, 0.1)
    property color disabledTextColour: Qt.alpha(Colours.palette.m3onSurface, 0.38)

    spacing: Math.floor(Tokens.spacing.extraSmall / 2)

    // TTY: one bracketed choice, `[ label ▾ ]`, opening the menu wherever it's clicked
    Item {
        id: ttyBtn

        visible: Colours.tty
        implicitWidth: ttyText.implicitWidth
        implicitHeight: ttyText.implicitHeight + 8

        StyledText {
            id: ttyText

            anchors.centerIn: parent
            textFormat: Text.StyledText
            readonly property color edge: root.expanded || ttyArea.containsMouse ? Colours.palette.m3primary : Colours.palette.m3outline
            text: `<font color="${edge}">[</font> ${(root.active?.activeText ?? root.fallbackText).toLowerCase()} <font color="${edge}">${root.expanded ? "▴" : "▾"} ]</font>`
            color: root.disabled ? root.disabledTextColour : Colours.palette.m3onSurface
            font: Tokens.font.body.medium
        }

        MouseArea {
            id: ttyArea

            anchors.fill: parent
            hoverEnabled: true
            enabled: !root.disabled
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }

    StyledRect {
        visible: !Colours.tty
        radius: implicitHeight / 2 * Math.min(1, Tokens.rounding.scale)
        topRightRadius: Tokens.rounding.medium / 2
        bottomRightRadius: Tokens.rounding.medium / 2
        color: root.disabled ? root.disabledColour : root.colour

        implicitWidth: Math.max(root.minLeftWidth, textRow.implicitWidth + root.horizontalPadding * 2)
        implicitHeight: expandBtn.implicitHeight

        StateLayer {
            id: stateLayer

            topRightRadius: parent.topRightRadius
            bottomRightRadius: parent.bottomRightRadius
            color: root.textColour
            disabled: root.disabled
            onClicked: root.active?.clicked()
        }

        RowLayout {
            id: textRow

            anchors.centerIn: parent
            anchors.horizontalCenterOffset: Math.floor(root.verticalPadding / 4)
            spacing: Tokens.spacing.small

            MaterialIcon {
                id: iconLabel

                Layout.alignment: Qt.AlignVCenter
                animate: true
                text: root.active?.activeIcon ?? root.fallbackIcon
                color: root.disabled ? root.disabledTextColour : root.textColour
                fill: 1
            }

            StyledText {
                id: label

                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: implicitWidth
                animate: true
                text: root.active?.activeText ?? root.fallbackText
                color: root.disabled ? root.disabledTextColour : root.textColour
                clip: true

                Behavior on Layout.preferredWidth {
                    Anim {
                        type: Anim.Emphasized
                    }
                }
            }
        }
    }

    StyledRect {
        id: expandBtn

        visible: !Colours.tty

        property real rad: root.expanded ? implicitHeight / 2 * Math.min(1, Tokens.rounding.scale) : Tokens.rounding.medium / 2

        radius: implicitHeight / 2 * Math.min(1, Tokens.rounding.scale)
        topLeftRadius: rad
        bottomLeftRadius: rad
        color: root.disabled ? root.disabledColour : root.colour

        implicitWidth: implicitHeight
        implicitHeight: expandIcon.implicitHeight + root.verticalPadding * 2

        StateLayer {
            id: expandStateLayer

            rect.topLeftRadius: parent.topLeftRadius
            rect.bottomLeftRadius: parent.bottomLeftRadius
            color: root.textColour
            disabled: root.disabled
            onClicked: root.expanded = !root.expanded
        }

        MaterialIcon {
            id: expandIcon

            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.expanded ? 0 : -Math.floor(root.verticalPadding / 4)

            text: "expand_more"
            color: root.disabled ? root.disabledTextColour : root.textColour
            rotation: root.expanded ? 180 : 0

            Behavior on anchors.horizontalCenterOffset {
                Anim {}
            }

            Behavior on rotation {
                Anim {}
            }
        }

        Behavior on rad {
            Anim {}
        }
    }

    Menu {
        id: menu

        attachTo: Colours.tty ? ttyBtn : expandBtn
        marginY: Tokens.spacing.small
    }
}