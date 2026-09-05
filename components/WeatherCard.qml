pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../services"

// Lockscreen Weather widget matching Caelestia modules/lock/WeatherInfo.qml
Rectangle {
    id: root

    implicitHeight: 185
    radius: 28
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: "Clear"
            font.family: "Google Sans Flex"
            font.pointSize: 14
            font.weight: Font.Normal
            color: Colours.palette.m3onSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            Text {
                text: "76°F"
                font.family: "Google Sans Flex"
                font.pointSize: 44
                font.weight: Font.DemiBold
                font.variableAxes: { "wdth": 80, "opsz": 44 }
                color: Colours.palette.m3primary
            }

            MaterialIcon {
                text: "wb_sunny"
                fontStyle.pointSize: 44
                color: Colours.palette.m3secondary
            }
        }

        Text {
            text: "Feels like 76°F"
            font.family: "Google Sans Flex"
            font.pointSize: 14
            font.weight: Font.Normal
            color: Colours.palette.m3onSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: "High 82°F \u2022 Low 65°F"
            font.family: "Google Sans Flex"
            font.pointSize: 12
            font.weight: Font.Normal
            color: Colours.palette.m3onSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
