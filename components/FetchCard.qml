pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../services"

// Lockscreen Fetch widget matching Caelestia's caelestiafetch.sh design
Rectangle {
    id: root

    implicitWidth: 260
    implicitHeight: 175
    radius: 16
    color: Qt.rgba(Colours.palette.m3surfaceContainer.r,
                   Colours.palette.m3surfaceContainer.g,
                   Colours.palette.m3surfaceContainer.b, 0.85)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        // Header Row: `> caelestiafetch.sh`
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                implicitWidth: 20
                implicitHeight: 20
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
                font.pointSize: 10
                font.weight: Font.Medium
                color: Colours.palette.m3onSurface
                Layout.fillWidth: true
            }
        }

        // Body: Logo + Info Details
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Distro / Caelestia Logo (Cyan modern triangular emblem)
            Item {
                implicitWidth: 54
                implicitHeight: 54

                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        ctx.fillStyle = Colours.palette.m3primary.toString();
                        ctx.beginPath();
                        ctx.moveTo(27, 4);
                        ctx.lineTo(50, 48);
                        ctx.lineTo(4, 48);
                        ctx.closePath();
                        ctx.fill();

                        // Inner geometric cut
                        ctx.fillStyle = Colours.palette.m3surfaceContainer.toString();
                        ctx.beginPath();
                        ctx.moveTo(27, 20);
                        ctx.lineTo(40, 44);
                        ctx.lineTo(14, 44);
                        ctx.closePath();
                        ctx.fill();
                    }
                }
            }

            // Specs
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    text: `OS   : ${SystemInfo.osName}`
                    font.family: "Monospace"
                    font.pointSize: 9
                    color: Colours.palette.m3onSurface
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: `WM   : ${SystemInfo.wmName}`
                    font.family: "Monospace"
                    font.pointSize: 9
                    color: Colours.palette.m3onSurface
                }
                Text {
                    text: `USER : ${SystemInfo.userName}`
                    font.family: "Monospace"
                    font.pointSize: 9
                    color: Colours.palette.m3onSurface
                }
                Text {
                    text: `UP   : ${SystemInfo.uptimeStr}`
                    font.family: "Monospace"
                    font.pointSize: 9
                    color: Colours.palette.m3onSurface
                }
            }
        }

        // Color Palette Dots Row (8 dots)
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            property var paletteCols: [
                "#333837", "#a7ceca", "#7aa2f7", "#fabd2f",
                "#8ff2dc", "#b6e3fe", "#d0c0e2", "#ebbcba"
            ]

            Repeater {
                model: parent.paletteCols
                Rectangle {
                    required property var modelData
                    implicitWidth: 14
                    implicitHeight: 14
                    radius: 7
                    color: modelData
                }
            }
        }
    }
}
