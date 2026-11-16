import QtQuick
import QtQuick.Layouts
import "../"
import "../containers"
import Astra.Airlock
import "../../../services"
ConnectedRect {
    id: root

    property string icon: ""
    property alias text: label.text
    property alias subtext: subLabel.text
    property bool checked: false
    property bool disabled: false
    property color iconColor: Colours.palette.m3onSurfaceVariant

    signal toggled(bool checked)
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: Math.max(52, row.implicitHeight + Tokens.padding.medium * 2)

    StateLayer {
        id: stateLayer
        anchors.fill: parent
        radius: parent.radius
        disabled: root.disabled
        onClicked: {
            root.checked = !root.checked;
            root.toggled(root.checked);
            root.clicked();
        }
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
            visible: root.icon.length > 0
            text: root.icon
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

        StyledSwitch {
            id: toggleSwitch
            checked: root.checked
            disabled: root.disabled
            onToggled: {
                if (root.checked !== checked) {
                    root.checked = checked;
                    root.toggled(root.checked);
                    root.clicked();
                }
            }
        }
    }
}
