import QtQuick
import QtQuick.Layouts
import "../"
import "../containers"
import Astra.Airlock
import "../../../services"
ConnectedRect {
    id: root

    property alias icon: iconLabel.text
    property alias text: label.text
    property alias subtext: subLabel.text
    property string trailingIcon: ""
    property alias disabled: stateLayer.disabled
    property color iconColor: Colours.palette.m3onSurfaceVariant

    readonly property alias iconLabel: iconLabel
    readonly property alias label: label
    readonly property alias subLabel: subLabel

    signal clicked()

    Layout.fillWidth: true
    implicitHeight: Math.max(48, row.implicitHeight + Tokens.padding.medium * 2)

    StateLayer {
        id: stateLayer
        anchors.fill: parent
        radius: parent.radius
        onClicked: root.clicked()
    }

    RowLayout {
        id: row

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.large

        spacing: Tokens.spacing.medium
        opacity: root.disabled ? 0.45 : 1.0

        Behavior on opacity {
            Anim {}
        }

        MaterialIcon {
            id: iconLabel
            visible: text.length > 0
            color: root.iconColor
            fontStyle: Tokens.font.icon.medium
        }

        ColumnLayout {
            id: column
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                id: label
                Layout.fillWidth: true
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurface
                elide: Text.ElideRight
            }

            StyledText {
                id: subLabel
                Layout.fillWidth: true
                visible: text.length > 0
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        MaterialIcon {
            id: trailingIconItem
            visible: root.trailingIcon.length > 0
            text: root.trailingIcon
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.small
        }
    }
}
