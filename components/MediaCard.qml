pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../services"

// Lockscreen Media widget matching Caelestia design
Rectangle {
    id: root

    implicitWidth: 260
    implicitHeight: 110
    radius: 16
    color: Qt.rgba(Colours.palette.m3surfaceContainer.r,
                   Colours.palette.m3surfaceContainer.g,
                   Colours.palette.m3surfaceContainer.b, 0.85)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 4

        Text {
            text: "Nothing playing"
            font.family: "Google Sans Flex"
            font.pointSize: 11
            font.weight: Font.Medium
            color: Colours.palette.m3primary
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: "Try playing some music!"
            font.family: "Google Sans Flex"
            font.pointSize: 9
            color: Colours.palette.m3outline
            Layout.alignment: Qt.AlignHCenter
        }

        // Control buttons row
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
            spacing: 12

            component MediaBtn: Rectangle {
                id: mbtn
                required property string icon
                implicitWidth: 32
                implicitHeight: 32
                radius: 16
                color: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.7)

                MaterialIcon {
                    anchors.centerIn: parent
                    text: mbtn.icon
                    fontStyle.pointSize: 16
                    color: Colours.palette.m3onSurface
                }
            }

            MediaBtn { icon: "skip_previous" }
            MediaBtn { icon: "play_arrow" }
            MediaBtn { icon: "skip_next" }
        }
    }
}
