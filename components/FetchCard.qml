pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../services"

// Lockscreen Fetch widget matching Caelestia modules/lock/Fetch.qml
Rectangle {
    id: root

    implicitHeight: 220
    radius: 24
    color: Colours.tPalette.m3surfaceContainer

    readonly property string distroLogoPath: {
        // Use user's installed distro icon
        return "file:///usr/share/icons/artix/artixlinux-logo-only.svg";
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // Header Row: `> caelestiafetch.sh`
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                implicitWidth: 22
                implicitHeight: 22
                radius: 6
                color: Colours.palette.m3primary

                Text {
                    anchors.centerIn: parent
                    text: ">"
                    font.family: "Monospace"
                    font.pointSize: 11
                    font.weight: Font.Bold
                    color: Colours.palette.m3onPrimary
                }
            }

            Text {
                text: "caelestiafetch.sh"
                font.family: "Monospace"
                font.pointSize: 12
                font.weight: Font.Medium
                color: Colours.palette.m3onSurface
                Layout.fillWidth: true
            }
        }

        // Body: Distro Logo + Info Details
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 18

            // Distro Logo (Artix Linux SVG recolored to bright primary, matching Caelestia scale)
            Item {
                implicitWidth: 104
                implicitHeight: 104
                Layout.preferredWidth: 104
                Layout.preferredHeight: 104
                Layout.alignment: Qt.AlignVCenter

                Image {
                    id: logoImg
                    anchors.fill: parent
                    source: root.distroLogoPath
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: 256
                    sourceSize.height: 256
                    mipmap: true
                    smooth: true

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        brightness: 0.35
                        contrast: 0.15
                        colorization: 1.0
                        colorizationColor: Colours.palette.m3primary
                    }
                }
            }

            // Live System Specs in exact Caelestia monospace layout
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    text: `OS  : ${SystemInfo.osPrettyName || SystemInfo.osName}`
                    font.family: "Monospace"
                    font.pointSize: 11
                    font.weight: Font.Normal
                    color: Colours.palette.m3onSurface
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: `WM  : ${SystemInfo.wmName}`
                    font.family: "Monospace"
                    font.pointSize: 11
                    font.weight: Font.Normal
                    color: Colours.palette.m3onSurface
                }
                Text {
                    text: `USER: ${SystemInfo.userName}`
                    font.family: "Monospace"
                    font.pointSize: 11
                    font.weight: Font.Normal
                    color: Colours.palette.m3onSurface
                }
                Text {
                    text: `UP  : ${SystemInfo.uptimeStr}`
                    font.family: "Monospace"
                    font.pointSize: 11
                    font.weight: Font.Normal
                    color: Colours.palette.m3onSurface
                }
            }
        }

        // Terminal Color Palette Row (8 rounded squircle shapes, matching Caelestia)
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            Repeater {
                model: 8

                Rectangle {
                    required property int index
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: 8
                    color: Colours.palette[`term${index}`] || "#9bd0cc"
                }
            }
        }
    }
}
