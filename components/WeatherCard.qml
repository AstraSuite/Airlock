pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../services"

// Lockscreen Weather widget matching Caelestia design
Rectangle {
    id: root

    implicitWidth: 260
    implicitHeight: 120
    radius: 16
    color: Qt.rgba(Colours.palette.m3surfaceContainer.r,
                   Colours.palette.m3surfaceContainer.g,
                   Colours.palette.m3surfaceContainer.b, 0.85)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 4

        Text {
            text: "Clear"
            font.family: "Google Sans Flex"
            font.pointSize: 11
            font.weight: Font.Medium
            color: Colours.palette.m3outline
            Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            Text {
                text: "76°F"
                font.family: "Google Sans Flex"
                font.pointSize: 26
                font.weight: Font.Bold
                font.variableAxes: { "wdth": 85 }
                color: Colours.palette.m3onSurface
            }

            MaterialIcon {
                text: "wb_sunny"
                fontStyle.pointSize: 26
                color: Colours.palette.m3primary
            }
        }

        Text {
            text: "Feels like 76°F\nHigh 82°F • Low 65°F"
            font.family: "Google Sans Flex"
            font.pointSize: 9
            font.weight: Font.Normal
            horizontalAlignment: Text.AlignHCenter
            color: Colours.palette.m3outline
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
