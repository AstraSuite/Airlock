import QtQuick
import QtQuick.Layouts
import "../"
import Astra.Airlock
import "../../../services"
Item {
    id: root

    property bool checked: false
    property string text: ""

    signal toggled(bool checked)
    signal clicked()

    implicitWidth: root.text.length > 0 ? (rowLayout.implicitWidth + 4) : 24
    implicitHeight: 24
    opacity: root.enabled ? 1.0 : 0.38

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 6

        // TTY: the box in text, `[x]` or `[ ]`
        StyledText {
            visible: Colours.tty
            Layout.alignment: Qt.AlignVCenter
            text: root.checked ? "[x]" : "[ ]"
            color: root.checked ? Colours.palette.m3primary : checkArea.containsMouse ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3outline
            font: Tokens.font.body.medium
        }

        // Checkbox Touch / Hover Target & Box
        Item {
            visible: !Colours.tty
            implicitWidth: 24
            implicitHeight: 24
            Layout.alignment: Qt.AlignVCenter

            // State Layer
            Rectangle {
                anchors.centerIn: parent
                width: 32
                height: 32
                radius: 16
                color: root.checked ? Colours.palette.m3primary : Colours.palette.m3onSurface
                opacity: checkArea.containsMouse ? (root.checked ? 0.12 : 0.08) : 0.0

                Behavior on opacity {
                    Anim { type: Anim.FastEffects }
                }
                Behavior on color {
                    CAnim {}
                }
            }

            // Box Container
            Rectangle {
                id: box
                anchors.centerIn: parent
                width: 20
                height: 20
                radius: 4
                color: "transparent"
                border.color: root.checked
                    ? Colours.palette.m3primary
                    : (checkArea.containsMouse ? Colours.palette.m3onSurface : Colours.palette.m3outline)
                border.width: 2

                Behavior on border.color {
                    CAnim {}
                }

                // Checked fill background
                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: Colours.palette.m3primary
                    opacity: root.checked ? 1.0 : 0.0
                    Behavior on opacity {
                        Anim { type: Anim.FastEffects }
                    }
                }

                // Checkmark Icon
                MaterialIcon {
                    id: checkIcon
                    anchors.centerIn: parent
                    text: "check"
                    pointSize: 15
                    color: Colours.palette.m3onPrimary
                    scale: root.checked ? 1.0 : 0.2
                    opacity: root.checked ? 1.0 : 0.0

                    Behavior on scale {
                        NumberAnimation {
                            duration: 160
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.4
                        }
                    }
                    Behavior on opacity {
                        Anim { type: Anim.FastEffects }
                    }
                }
            }
        }

        // Optional Text Label
        StyledText {
            id: label
            visible: root.text.length > 0
            text: root.text
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurface
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: checkArea
        anchors.fill: parent
        hoverEnabled: root.enabled
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            root.checked = !root.checked;
            root.toggled(root.checked);
            root.clicked();
        }
    }
}
