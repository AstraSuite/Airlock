pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Astra.Airlock
import "../services"

// Quick Actions & Accessibility Hub (replaces lockscreen notification area)
// Authentic Material 3 Expressive switches without borders, animated thumbs with icons,
// perfectly aligned icons and labels, and real functionality connected to greeter state.
Rectangle {
    id: root

    radius: 28
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10

        // Header: "Accessibility & Actions"
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialIcon {
                text: "accessibility_new"
                iconSize: 18
                color: Colours.palette.m3primary
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: "Accessibility & Actions"
                font.family: "Google Sans Flex"
                font.pointSize: 12 * Colours.fontScale
                font.weight: Font.DemiBold
                color: Colours.palette.m3outline
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Action Item 1: On-Screen Virtual Keyboard
        AccessibilityRow {
            Layout.fillWidth: true
            iconText: "keyboard"
            title: "Virtual Keyboard"
            subtitle: Colours.oskActive ? "On-screen input active" : "Touchscreen keyboard"
            checked: Colours.oskActive
            onToggled: Colours.oskActive = !Colours.oskActive
        }

        // Action Item 2: High Contrast
        AccessibilityRow {
            Layout.fillWidth: true
            iconText: "contrast"
            title: "High Contrast"
            subtitle: Colours.highContrast ? "High contrast active" : "Sharper UI edges & text"
            checked: Colours.highContrast
            onToggled: Colours.highContrast = !Colours.highContrast
        }

        // Action Item 3: Large Text
        AccessibilityRow {
            Layout.fillWidth: true
            iconText: "format_size"
            title: "Large Text"
            subtitle: Colours.largeText ? "125% zoom active" : "Enlarged interface fonts"
            checked: Colours.largeText
            onToggled: Colours.largeText = !Colours.largeText
        }

        // Action Item 4: Touch Assist
        AccessibilityRow {
            Layout.fillWidth: true
            iconText: "touch_app"
            title: "Touch Assist"
            subtitle: Colours.touchAssist ? "Touch mode active" : "Enlarged interaction targets"
            checked: Colours.touchAssist
            onToggled: Colours.touchAssist = !Colours.touchAssist
        }

        Item { Layout.fillHeight: true }

        // System Power Actions Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Suspend button
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Colours.touchAssist ? 52 : 44
                radius: 14
                color: hSusp.hovered ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainerHigh
                Behavior on color { ColorAnimation { duration: 120 } }
                HoverHandler { id: hSusp }

                StateLayer {
                    onClicked: SystemPower.suspend()
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    MaterialIcon {
                        text: "bedtime"
                        iconSize: 15
                        color: Colours.palette.m3primary
                    }
                    Text {
                        text: "Sleep"
                        font.family: "Google Sans Flex"
                        font.pointSize: 10 * Colours.fontScale
                        font.weight: Font.Medium
                        color: Colours.palette.m3onSurface
                    }
                }
            }

            // Reboot button
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Colours.touchAssist ? 52 : 44
                radius: 14
                color: hReb.hovered ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainerHigh
                Behavior on color { ColorAnimation { duration: 120 } }
                HoverHandler { id: hReb }

                StateLayer {
                    onClicked: SystemPower.reboot()
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    MaterialIcon {
                        text: "restart_alt"
                        iconSize: 15
                        color: Colours.palette.m3secondary
                    }
                    Text {
                        text: "Restart"
                        font.family: "Google Sans Flex"
                        font.pointSize: 10 * Colours.fontScale
                        font.weight: Font.Medium
                        color: Colours.palette.m3onSurface
                    }
                }
            }

            // Poweroff button
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Colours.touchAssist ? 52 : 44
                radius: 14
                color: hPwr.hovered ? Qt.alpha(Colours.palette.m3errorContainer, 0.6) : Colours.tPalette.m3surfaceContainerHigh
                Behavior on color { ColorAnimation { duration: 120 } }
                HoverHandler { id: hPwr }

                StateLayer {
                    onClicked: SystemPower.poweroff()
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    MaterialIcon {
                        text: "power_settings_new"
                        iconSize: 15
                        color: hPwr.hovered ? Colours.palette.m3onErrorContainer : Colours.palette.m3error
                    }
                    Text {
                        text: "Power"
                        font.family: "Google Sans Flex"
                        font.pointSize: 10 * Colours.fontScale
                        font.weight: Font.Medium
                        color: hPwr.hovered ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSurface
                    }
                }
            }
        }
    }

    // Material 3 Accessibility Row with aligned icon, text, and switch
    component AccessibilityRow: Rectangle {
        id: rowRoot

        required property string iconText
        required property string title
        required property string subtitle
        required property bool checked
        signal toggled()

        implicitHeight: Colours.touchAssist ? 62 : 54
        radius: 16
        color: rowHover.hovered ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainerHigh
        Behavior on color { ColorAnimation { duration: 120 } }
        HoverHandler { id: rowHover }

        StateLayer {
            onClicked: rowRoot.toggled()
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 14

            // Fixed-width Icon Container ensuring all row text lines up identically
            Item {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                Layout.alignment: Qt.AlignVCenter

                MaterialIcon {
                    anchors.centerIn: parent
                    text: rowRoot.iconText
                    iconSize: 22
                    color: rowRoot.checked ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            // Text column (Title + Subtitle)
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    text: rowRoot.title
                    font.family: "Google Sans Flex"
                    font.pointSize: 11.5 * Colours.fontScale
                    font.weight: Font.Medium
                    color: Colours.palette.m3onSurface
                }

                Text {
                    text: rowRoot.subtitle
                    font.family: "Google Sans Flex"
                    font.pointSize: 9.5 * Colours.fontScale
                    font.weight: Font.Normal
                    color: Colours.palette.m3outline
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Material 3 Expressive Switch (solid pill track, no borders, animated thumb with inner icon)
            Rectangle {
                id: m3Switch
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 48
                implicitHeight: 28
                radius: 14
                color: rowRoot.checked ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainerHighest
                Behavior on color { ColorAnimation { duration: 180 } }

                Rectangle {
                    id: m3Thumb
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    height: 24
                    radius: 12
                    x: rowRoot.checked ? (m3Switch.width - width - 2) : 2
                    color: rowRoot.checked ? Colours.palette.m3onPrimary : Colours.palette.m3outline

                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: rowRoot.checked ? "check" : "close"
                        iconSize: 13
                        color: rowRoot.checked ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHighest
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }
        }
    }
}
