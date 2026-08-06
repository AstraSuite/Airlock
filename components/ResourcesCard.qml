pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes
import "../services"

// Lockscreen Resources widget matching Caelestia's 3-shape chips layout
Rectangle {
    id: root

    implicitWidth: 280
    implicitHeight: 120
    radius: 16
    color: Qt.rgba(Colours.palette.m3surfaceContainer.r,
                   Colours.palette.m3surfaceContainer.g,
                   Colours.palette.m3surfaceContainer.b, 0.85)

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // CPU Chip
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: Qt.alpha(Colours.palette.m3primaryContainer, 0.45)

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 3
                    MaterialIcon {
                        text: "settings"
                        fontStyle.pointSize: 11
                        color: Colours.palette.m3primary
                    }
                    Text {
                        text: `${SystemInfo.cpuTemp}°C`
                        font.family: "Google Sans Flex"
                        font.pointSize: 9
                        color: Colours.palette.m3primary
                    }
                }

                Text {
                    text: `${SystemInfo.cpuPercent}%`
                    font.family: "Google Sans Flex"
                    font.pointSize: 18
                    font.weight: Font.Bold
                    font.variableAxes: { "wdth": 85 }
                    color: Colours.palette.m3onSurface
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // RAM Chip
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: Qt.alpha(Colours.palette.m3secondaryContainer, 0.45)

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2

                MaterialIcon {
                    text: "memory"
                    fontStyle.pointSize: 13
                    color: Colours.palette.m3secondary
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: `${SystemInfo.memPercent}%`
                    font.family: "Google Sans Flex"
                    font.pointSize: 18
                    font.weight: Font.Bold
                    font.variableAxes: { "wdth": 85 }
                    color: Colours.palette.m3onSurface
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // Disk / Battery Chip
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: Qt.alpha(Colours.palette.m3tertiaryContainer, 0.45)

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2

                MaterialIcon {
                    text: "storage"
                    fontStyle.pointSize: 13
                    color: Colours.palette.m3tertiary
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: `${SystemInfo.diskPercent}%`
                    font.family: "Google Sans Flex"
                    font.pointSize: 18
                    font.weight: Font.Bold
                    font.variableAxes: { "wdth": 85 }
                    color: Colours.palette.m3onSurface
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
