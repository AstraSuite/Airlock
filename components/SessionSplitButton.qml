pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Caelestia.Greeter
import "../services"

// Caelestia SplitButton matching the rest of the shell:
// Two adjacent asymmetric rounded rectangles with matching inner corner radii, borderless tonal surfaces
Item {
    id: root

    property int currentIndex: SessionDiscovery.defaultIndex
    signal sessionChanged(int index)

    readonly property var currentSession: SessionDiscovery.sessions.length > 0 && currentIndex >= 0 && currentIndex < SessionDiscovery.sessions.length
        ? SessionDiscovery.sessions[currentIndex] : null

    property bool menuOpen: false

    implicitWidth: splitRow.implicitWidth
    implicitHeight: 36

    Row {
        id: splitRow
        anchors.centerIn: parent
        spacing: 3

        // ── Left Segment: Action / Session Toggle ─────────────────────
        Rectangle {
            id: leftBtn
            implicitHeight: 36
            implicitWidth: contentRow.implicitWidth + 24

            topLeftRadius: 18
            bottomLeftRadius: 18
            topRightRadius: 4
            bottomRightRadius: 4

            color: leftHover.hovered
                ? Colours.tPalette.m3secondaryContainer
                : Colours.tPalette.m3surfaceContainer

            Behavior on color { ColorAnimation { duration: 120 } }

            HoverHandler {
                id: leftHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: {
                    if (SessionDiscovery.sessions.length > 1) {
                        root.currentIndex = (root.currentIndex + 1) % SessionDiscovery.sessions.length;
                        root.sessionChanged(root.currentIndex);
                    } else if (SessionDiscovery.sessions.length === 1) {
                        root.menuOpen = !root.menuOpen;
                    }
                }
            }

            RowLayout {
                id: contentRow
                anchors.centerIn: parent
                spacing: 6

                Item {
                    implicitWidth: 18
                    implicitHeight: 18

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: root.currentSession?.type === "Wayland" ? "layers" : "desktop_windows"
                        fontStyle.pointSize: 15
                        color: Colours.palette.m3primary
                    }
                }

                Text {
                    text: root.currentSession ? root.currentSession.name : "Hyprland"
                    font.family: "Google Sans Flex"
                    font.pointSize: 11
                    font.weight: Font.Medium
                    color: Colours.palette.m3onSurface
                }
            }
        }

        // ── Right Segment: Expand / Dropdown Trigger ──────────────────
        Rectangle {
            id: rightBtn
            implicitWidth: 36
            implicitHeight: 36

            topRightRadius: 18
            bottomRightRadius: 18
            topLeftRadius: root.menuOpen ? 18 : 4
            bottomLeftRadius: root.menuOpen ? 18 : 4

            Behavior on topLeftRadius { NumberAnimation { duration: 150 } }
            Behavior on bottomLeftRadius { NumberAnimation { duration: 150 } }

            color: rightHover.hovered || root.menuOpen
                ? Colours.tPalette.m3secondaryContainer
                : Colours.tPalette.m3surfaceContainer

            Behavior on color { ColorAnimation { duration: 120 } }

            HoverHandler {
                id: rightHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: root.menuOpen = !root.menuOpen
            }

            MaterialIcon {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: root.menuOpen ? 0 : -1
                text: "expand_more"
                fontStyle.pointSize: 16
                color: root.menuOpen ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                rotation: root.menuOpen ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
        }
    }

    // ── Dropdown Menu Popup ───────────────────────────────────────────
    Rectangle {
        id: menuPopup
        anchors.top: splitRow.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: splitRow.horizontalCenter
        implicitWidth: 230
        implicitHeight: sessCol.implicitHeight + 16
        radius: 16
        color: Colours.tPalette.m3surfaceContainerHighest
        z: 99999

        visible: opacity > 0
        opacity: root.menuOpen ? 1 : 0
        scale: root.menuOpen ? 1 : 0.92
        transformOrigin: Item.Top

        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 14
            shadowColor: Qt.rgba(0, 0, 0, 0.6)
            shadowVerticalOffset: 4
        }

        TapHandler {
            // Absorb taps on background of popup so they don't dismiss through
        }

        ColumnLayout {
            id: sessCol
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Repeater {
                model: SessionDiscovery.sessions
                delegate: Rectangle {
                    id: itemRow
                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: 10
                    color: itemHover.hovered || root.currentIndex === itemRow.index
                        ? Colours.tPalette.m3primaryContainer
                        : "transparent"

                    Behavior on color { ColorAnimation { duration: 120 } }

                    HoverHandler {
                        id: itemHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: {
                            root.currentIndex = itemRow.index;
                            root.sessionChanged(itemRow.index);
                            root.menuOpen = false;
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Item {
                            implicitWidth: 18
                            implicitHeight: 18

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: itemRow.modelData.type === "Wayland" ? "layers" : "desktop_windows"
                                fontStyle.pointSize: 14
                                color: root.currentIndex === itemRow.index
                                    ? Colours.palette.m3primary
                                    : Colours.palette.m3onSurfaceVariant
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignLeft
                                text: itemRow.modelData.name ?? ""
                                font.family: "Google Sans Flex"
                                font.pointSize: 10
                                font.weight: Font.Medium
                                color: Colours.palette.m3onSurface
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignLeft
                                text: itemRow.modelData.type ?? ""
                                font.family: "Google Sans Flex"
                                font.pointSize: 8
                                color: Colours.palette.m3outline
                            }
                        }

                        Item {
                            implicitWidth: 18
                            implicitHeight: 18
                            visible: root.currentIndex === itemRow.index

                            MaterialIcon {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: "check"
                                fontStyle.pointSize: 14
                                color: Colours.palette.m3primary
                            }
                        }
                    }
                }
            }
        }
    }
}
