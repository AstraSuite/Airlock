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

        // ── Left Segment: Action / Label ──────────────────────────────
        Rectangle {
            id: leftBtn
            implicitHeight: 36
            implicitWidth: contentRow.implicitWidth + 24

            topLeftRadius: 18
            bottomLeftRadius: 18
            topRightRadius: 4
            bottomRightRadius: 4

            color: leftMouse.containsMouse
                ? Qt.alpha(Colours.palette.m3secondaryContainer, 0.90)
                : Qt.alpha(Colours.palette.m3surfaceContainerHigh, 0.85)

            Behavior on color { ColorAnimation { duration: 120 } }

            MouseArea {
                id: leftMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (SessionDiscovery.sessions.length > 1) {
                        root.currentIndex = (root.currentIndex + 1) % SessionDiscovery.sessions.length;
                        root.sessionChanged(root.currentIndex);
                    }
                }
            }

            RowLayout {
                id: contentRow
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: 2
                spacing: 6

                MaterialIcon {
                    text: {
                        const s = root.currentSession;
                        if (!s) return "desktop_windows";
                        return s.type === "Wayland" ? "star" : "desktop_windows";
                    }
                    fontStyle.pointSize: 15
                    color: Colours.palette.m3primary
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

            color: rightMouse.containsMouse || root.menuOpen
                ? Qt.alpha(Colours.palette.m3secondaryContainer, 0.90)
                : Qt.alpha(Colours.palette.m3surfaceContainerHigh, 0.85)

            Behavior on color { ColorAnimation { duration: 120 } }

            MouseArea {
                id: rightMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.menuOpen = !root.menuOpen
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

    // ── Dropdown Menu Popup (Opens UPWARDS above split button so it never gets cut off) ───
    Rectangle {
        id: menuPopup
        anchors.bottom: splitRow.top
        anchors.bottomMargin: 8
        anchors.horizontalCenter: splitRow.horizontalCenter
        implicitWidth: 220
        implicitHeight: sessCol.implicitHeight + 16
        radius: 16
        color: Qt.rgba(Colours.palette.m3surfaceContainer.r,
                       Colours.palette.m3surfaceContainer.g,
                       Colours.palette.m3surfaceContainer.b, 0.98)
        z: 10000

        visible: opacity > 0
        opacity: root.menuOpen ? 1 : 0
        scale: root.menuOpen ? 1 : 0.92
        transformOrigin: Item.Bottom

        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }

        // Click catcher inside menuPopup to prevent any click-through
        MouseArea {
            anchors.fill: parent
            enabled: root.menuOpen
            onClicked: {}
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
                    color: itemMouse.containsMouse || root.currentIndex === itemRow.index
                        ? Qt.alpha(Colours.palette.m3primaryContainer, 0.55)
                        : "transparent"

                    Behavior on color { ColorAnimation { duration: 120 } }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
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

                        MaterialIcon {
                            text: itemRow.modelData.type === "Wayland" ? "star" : "desktop_windows"
                            fontStyle.pointSize: 14
                            color: root.currentIndex === itemRow.index
                                ? Colours.palette.m3primary
                                : Colours.palette.m3onSurfaceVariant
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: itemRow.modelData.name ?? ""
                                font.family: "Google Sans Flex"
                                font.pointSize: 10
                                font.weight: Font.Medium
                                color: Colours.palette.m3onSurface
                                elide: Text.ElideRight
                            }

                            Text {
                                text: itemRow.modelData.type ?? ""
                                font.family: "Google Sans Flex"
                                font.pointSize: 8
                                color: Colours.palette.m3outline
                            }
                        }

                        MaterialIcon {
                            visible: root.currentIndex === itemRow.index
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
