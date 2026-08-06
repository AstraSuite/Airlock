pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../services"

// Lockscreen Notifications/Status widget matching Caelestia design
Rectangle {
    id: root

    implicitWidth: 280
    implicitHeight: 280
    radius: 16
    color: Qt.rgba(Colours.palette.m3surfaceContainer.r,
                   Colours.palette.m3surfaceContainer.g,
                   Colours.palette.m3surfaceContainer.b, 0.85)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        Text {
            text: "System Status"
            font.family: "Google Sans Flex"
            font.pointSize: 11
            font.weight: Font.Medium
            color: Colours.palette.m3outline
        }

        // Notification Item 1: Display Manager
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 56
            radius: 12
            color: Qt.alpha(Colours.palette.m3surfaceContainerHigh, 0.5)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 8
                    color: Qt.alpha(Colours.palette.m3primaryContainer, 0.6)

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "lock"
                        fontStyle.pointSize: 16
                        color: Colours.palette.m3primary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Caelestia Greeter"
                        font.family: "Google Sans Flex"
                        font.pointSize: 10
                        font.weight: Font.Bold
                        color: Colours.palette.m3onSurface
                    }

                    Text {
                        text: "Greetd service active & ready"
                        font.family: "Google Sans Flex"
                        font.pointSize: 9
                        color: Colours.palette.m3outline
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // Notification Item 2: Shell theme sync
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 56
            radius: 12
            color: Qt.alpha(Colours.palette.m3surfaceContainerHigh, 0.5)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 8
                    color: Qt.alpha(Colours.palette.m3secondaryContainer, 0.6)

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "palette"
                        fontStyle.pointSize: 16
                        color: Colours.palette.m3secondary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Material 3 Dynamic"
                        font.family: "Google Sans Flex"
                        font.pointSize: 10
                        font.weight: Font.Bold
                        color: Colours.palette.m3onSurface
                    }

                    Text {
                        text: "Synced with Caelestia scheme"
                        font.family: "Google Sans Flex"
                        font.pointSize: 9
                        color: Colours.palette.m3outline
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
