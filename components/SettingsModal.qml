pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import Caelestia.Blobs
import Caelestia.Greeter
import M3Shapes
import "../services"

// Morphing Settings Modal (Bottom-Left) matching Caelestia Nexus Settings layout:
// Section headers, connected M3 rounded cards, avatar shape scrollable split button,
// and perfectly aligned toggle switches with check/cross icons.
Item {
    id: root

    property bool isOpen: false
    property bool shapeMenuOpen: false
    signal exitRequested()

    implicitWidth: 44
    implicitHeight: 44

    property real animDriver: 0

    readonly property var shapeOptions: [
        { name: "Cookie 9-Sided", value: MaterialShape.Cookie9Sided },
        { name: "Clamshell",      value: MaterialShape.ClamShell },
        { name: "Cookie 4-Sided", value: MaterialShape.Cookie4Sided },
        { name: "Cookie 6-Sided", value: MaterialShape.Cookie6Sided },
        { name: "Cookie 7-Sided", value: MaterialShape.Cookie7Sided },
        { name: "Cookie 12-Sided",value: MaterialShape.Cookie12Sided },
        { name: "Sunny",          value: MaterialShape.Sunny },
        { name: "Very Sunny",     value: MaterialShape.VerySunny },
        { name: "Soft Burst",     value: MaterialShape.SoftBurst },
        { name: "Circle",         value: MaterialShape.Circle },
        { name: "Pentagon",       value: MaterialShape.Pentagon },
        { name: "Gem",            value: MaterialShape.Gem },
        { name: "Arch",           value: MaterialShape.Arch },
        { name: "Arrow",          value: MaterialShape.Arrow },
        { name: "Pill",           value: MaterialShape.Pill },
        { name: "Triangle",       value: MaterialShape.Triangle },
        { name: "Fan",            value: MaterialShape.Fan },
        { name: "Oval",           value: MaterialShape.Oval }
    ]

    Process {
        id: modeProc
    }

    BlobGroup {
        id: blobGroup
        color: Colours.tPalette.m3surfaceContainer
        smoothing: 24
        cornerFill: false
    }

    // ── Popup Modal Rect (Elevated above bottom-left button) ──────
    BlobRect {
        id: popupRect

        anchors.left: parent.left
        anchors.bottom: parent.bottom

        implicitWidth: parent.width
        implicitHeight: parent.height

        group: blobGroup
        radius: 20
        deformScale: 0.00001

        states: State {
            name: "open"
            when: root.isOpen

            PropertyChanges {
                popupRect.anchors.bottomMargin: 64
                popupRect.anchors.leftMargin: 0
                popupRect.implicitWidth: 350
                popupRect.implicitHeight: contentCol.implicitHeight + 28
                root.animDriver: 1
            }
        }

        transitions: Transition {
            NumberAnimation {
                properties: "bottomMargin,leftMargin,implicitWidth,implicitHeight"
                duration: 260
                easing.type: Easing.OutBack
                easing.overshoot: 1.10
            }
            NumberAnimation {
                property: "animDriver"
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        // Click catcher inside modal so clicking inside doesn't dismiss
        MouseArea {
            anchors.fill: parent
            enabled: root.isOpen
            onClicked: {}
        }

        // Popup Content
        Item {
            anchors.fill: parent
            anchors.margins: 14
            clip: true
            opacity: root.animDriver
            visible: opacity > 0

            ColumnLayout {
                id: contentCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 2

                // ── Section 1 Header: Appearance & Display ────────
                Text {
                    text: "Appearance & Display"
                    font.family: "Google Sans Flex"
                    font.pointSize: 9
                    font.weight: Font.DemiBold
                    color: Colours.palette.m3onSurfaceVariant
                    Layout.leftMargin: 4
                    Layout.topMargin: 2
                    Layout.bottomMargin: 4
                }

                // ── Row 1: Avatar Shape (Scrollable Split-Button Dropdown) ──
                Rectangle {
                    id: rowShape
                    Layout.fillWidth: true
                    implicitHeight: root.shapeMenuOpen ? (48 + shapeDropdownDrawer.implicitHeight) : 48
                    topLeftRadius: 14
                    topRightRadius: 14
                    bottomLeftRadius: 4
                    bottomRightRadius: 4
                    clip: true

                    Behavior on implicitHeight {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }

                    color: hShapeHover.hovered || root.shapeMenuOpen
                        ? Colours.tPalette.m3surfaceContainerHighest
                        : Colours.tPalette.m3surfaceContainerHigh
                    Behavior on color { ColorAnimation { duration: 120 } }
                    HoverHandler { id: hShapeHover }

                    // Main Row Header Bar
                    Item {
                        id: shapeHeaderBar
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 48

                        // Left Label Column
                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.right: splitBtnContainer.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                width: parent.width
                                text: "Avatar shape"
                                font.family: "Google Sans Flex"
                                font.pointSize: 11
                                font.weight: Font.Medium
                                color: Colours.palette.m3onSurface
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: "Profile picture mask geometry"
                                font.family: "Google Sans Flex"
                                font.pointSize: 8
                                color: Colours.palette.m3outline
                                elide: Text.ElideRight
                            }
                        }

                        // Right Split Button Control
                        Row {
                            id: splitBtnContainer
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            // Left Button: Label & Mini Shape Preview
                            Rectangle {
                                implicitHeight: 28
                                implicitWidth: shapeBtnRow.implicitWidth + 16
                                topLeftRadius: 14
                                bottomLeftRadius: 14
                                topRightRadius: 4
                                bottomRightRadius: 4
                                color: Colours.tPalette.m3primaryContainer

                                RowLayout {
                                    id: shapeBtnRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    MaterialShape {
                                        implicitSize: 14
                                        shape: Colours.avatarShape
                                        color: Colours.palette.m3onPrimaryContainer
                                    }

                                    Text {
                                        text: Colours.avatarShapeName
                                        font.family: "Google Sans Flex"
                                        font.pointSize: 9
                                        font.weight: Font.Medium
                                        color: Colours.palette.m3onPrimaryContainer
                                    }
                                }

                                TapHandler {
                                    onTapped: root.shapeMenuOpen = !root.shapeMenuOpen
                                }
                            }

                            // Right Button: Arrow Indicator
                            Rectangle {
                                implicitHeight: 28
                                implicitWidth: 26
                                topLeftRadius: 4
                                bottomLeftRadius: 4
                                topRightRadius: 14
                                bottomRightRadius: 14
                                color: Colours.tPalette.m3primaryContainer

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "expand_more"
                                    fontStyle.pointSize: 16
                                    color: Colours.palette.m3onPrimaryContainer
                                    rotation: root.shapeMenuOpen ? 180 : 0
                                    Behavior on rotation { NumberAnimation { duration: 180 } }
                                }

                                TapHandler {
                                    onTapped: root.shapeMenuOpen = !root.shapeMenuOpen
                                }
                            }
                        }
                    }

                    // Dropdown Drawer List
                    Item {
                        id: shapeDropdownDrawer
                        anchors.top: shapeHeaderBar.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        anchors.bottomMargin: 8
                        implicitHeight: 140
                        visible: root.shapeMenuOpen

                        VerticalFadeListView {
                            id: shapeListView
                            anchors.fill: parent
                            clip: true
                            model: root.shapeOptions
                            spacing: 2
                            fadeAmount: 0.15

                            delegate: Rectangle {
                                id: shapeItem
                                required property var modelData
                                required property int index

                                width: shapeListView.width
                                implicitHeight: 32
                                radius: 8

                                readonly property bool isSelected: Colours.avatarShape === modelData.value

                                color: shapeItem.isSelected
                                    ? Colours.tPalette.m3primaryContainer
                                    : (itemHover.hovered ? Qt.alpha(Colours.palette.m3onSurface, 0.08) : "transparent")
                                Behavior on color { ColorAnimation { duration: 100 } }
                                HoverHandler { id: itemHover }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    MaterialShape {
                                        implicitSize: 16
                                        shape: shapeItem.modelData.value
                                        color: shapeItem.isSelected
                                            ? Colours.palette.m3onPrimaryContainer
                                            : Colours.palette.m3primary
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: shapeItem.modelData.name
                                        font.family: "Google Sans Flex"
                                        font.pointSize: 9
                                        font.weight: shapeItem.isSelected ? Font.Bold : Font.Normal
                                        color: shapeItem.isSelected
                                            ? Colours.palette.m3onPrimaryContainer
                                            : Colours.palette.m3onSurface
                                    }

                                    MaterialIcon {
                                        visible: shapeItem.isSelected
                                        text: "check"
                                        fontStyle.pointSize: 14
                                        color: Colours.palette.m3onPrimaryContainer
                                    }
                                }

                                TapHandler {
                                    onTapped: {
                                        Colours.avatarShape = shapeItem.modelData.value;
                                        Colours.avatarShapeName = shapeItem.modelData.name;
                                        root.shapeMenuOpen = false;
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Row 2: 12-Hour Clock (Middle in Group) ──────────
                Rectangle {
                    id: row12h
                    Layout.fillWidth: true
                    implicitHeight: 48
                    radius: 4

                    color: h12Hover.hovered
                        ? Colours.tPalette.m3surfaceContainerHighest
                        : Colours.tPalette.m3surfaceContainerHigh
                    Behavior on color { ColorAnimation { duration: 120 } }
                    HoverHandler { id: h12Hover }

                    // Left Text Column
                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.right: switch12h.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            width: parent.width
                            text: "12-hour clock"
                            font.family: "Google Sans Flex"
                            font.pointSize: 11
                            font.weight: Font.Medium
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: "Use AM/PM format instead of 24h"
                            font.family: "Google Sans Flex"
                            font.pointSize: 8
                            color: Colours.palette.m3outline
                            elide: Text.ElideRight
                        }
                    }

                    // M3 Switch with Check/Cross Icon (Strictly Far Right)
                    Rectangle {
                        id: switch12h
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 42
                        implicitHeight: 24
                        radius: 12
                        color: Colours.use12Hour
                            ? Colours.palette.m3primary
                            : Colours.tPalette.m3surfaceContainerHighest
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Rectangle {
                            id: thumb12h
                            width: 18
                            height: 18
                            radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            x: Colours.use12Hour ? parent.width - width - 3 : 3
                            color: Colours.use12Hour ? Colours.palette.m3onPrimary : Colours.palette.m3outline
                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: Colours.use12Hour ? "check" : "close"
                                fontStyle.pointSize: 11
                                color: Colours.use12Hour
                                    ? Colours.palette.m3primary
                                    : Colours.palette.m3surfaceContainerHigh
                            }
                        }
                    }

                    TapHandler {
                        onTapped: Colours.use12Hour = !Colours.use12Hour
                    }
                }

                // ── Row 3: Light Mode (Middle in Group) ────────────
                Rectangle {
                    id: rowTheme
                    Layout.fillWidth: true
                    implicitHeight: 48
                    radius: 4

                    color: hThemeHover.hovered
                        ? Colours.tPalette.m3surfaceContainerHighest
                        : Colours.tPalette.m3surfaceContainerHigh
                    Behavior on color { ColorAnimation { duration: 120 } }
                    HoverHandler { id: hThemeHover }

                    // Left Text Column
                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.right: switchTheme.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            width: parent.width
                            text: "Light theme"
                            font.family: "Google Sans Flex"
                            font.pointSize: 11
                            font.weight: Font.Medium
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: "Use light color palette for greeter"
                            font.family: "Google Sans Flex"
                            font.pointSize: 8
                            color: Colours.palette.m3outline
                            elide: Text.ElideRight
                        }
                    }

                    // M3 Switch with Check/Cross Icon (Strictly Far Right)
                    Rectangle {
                        id: switchTheme
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 42
                        implicitHeight: 24
                        radius: 12
                        color: Colours.light
                            ? Colours.palette.m3primary
                            : Colours.tPalette.m3surfaceContainerHighest
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Rectangle {
                            id: thumbTheme
                            width: 18
                            height: 18
                            radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            x: Colours.light ? parent.width - width - 3 : 3
                            color: Colours.light ? Colours.palette.m3onPrimary : Colours.palette.m3outline
                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: Colours.light ? "check" : "close"
                                fontStyle.pointSize: 11
                                color: Colours.light
                                    ? Colours.palette.m3primary
                                    : Colours.palette.m3surfaceContainerHigh
                            }
                        }
                    }

                    TapHandler {
                        onTapped: {
                            const newMode = Colours.light ? "dark" : "light";
                            Colours.setMode(newMode);
                        }
                    }
                }

                // ── Row 4: Lava Lamp Animation (Last in Appearance Group) ────
                Rectangle {
                    id: rowAnim
                    Layout.fillWidth: true
                    implicitHeight: 48
                    radius: 4
                    topLeftRadius: 4
                    topRightRadius: 4
                    bottomLeftRadius: 14
                    bottomRightRadius: 14

                    color: hAnimHover.hovered
                        ? Colours.tPalette.m3surfaceContainerHighest
                        : Colours.tPalette.m3surfaceContainerHigh
                    Behavior on color { ColorAnimation { duration: 120 } }
                    HoverHandler { id: hAnimHover }

                    // Left Text Column
                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.right: switchAnim.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            width: parent.width
                            text: "Lava lamp background"
                            font.family: "Google Sans Flex"
                            font.pointSize: 11
                            font.weight: Font.Medium
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: "Animate blobs on idle screen"
                            font.family: "Google Sans Flex"
                            font.pointSize: 8
                            color: Colours.palette.m3outline
                            elide: Text.ElideRight
                        }
                    }

                    // M3 Switch with Check/Cross Icon (Strictly Far Right)
                    Rectangle {
                        id: switchAnim
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 42
                        implicitHeight: 24
                        radius: 12
                        color: Colours.lavaLampEnabled
                            ? Colours.palette.m3primary
                            : Colours.tPalette.m3surfaceContainerHighest
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Rectangle {
                            id: thumbAnim
                            width: 18
                            height: 18
                            radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            x: Colours.lavaLampEnabled ? parent.width - width - 3 : 3
                            color: Colours.lavaLampEnabled ? Colours.palette.m3onPrimary : Colours.palette.m3outline
                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: Colours.lavaLampEnabled ? "check" : "close"
                                fontStyle.pointSize: 11
                                color: Colours.lavaLampEnabled
                                    ? Colours.palette.m3primary
                                    : Colours.palette.m3surfaceContainerHigh
                            }
                        }
                    }

                    TapHandler {
                        onTapped: Colours.lavaLampEnabled = !Colours.lavaLampEnabled
                    }
                }

                // ── Section 2 Header: Session (Visible in test mode) ─
                Text {
                    visible: !Greetd.available
                    text: "Session"
                    font.family: "Google Sans Flex"
                    font.pointSize: 9
                    font.weight: Font.DemiBold
                    color: Colours.palette.m3onSurfaceVariant
                    Layout.leftMargin: 4
                    Layout.topMargin: 8
                    Layout.bottomMargin: 4
                }

                // ── Row 5: Exit Test Mode (Single Group) ───────────
                Rectangle {
                    visible: !Greetd.available
                    Layout.fillWidth: true
                    implicitHeight: 46
                    radius: 14
                    color: hExitHover.hovered
                        ? Qt.alpha(Colours.palette.m3errorContainer, 0.70)
                        : Qt.alpha(Colours.palette.m3errorContainer, 0.40)
                    Behavior on color { ColorAnimation { duration: 120 } }
                    HoverHandler { id: hExitHover }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        MaterialIcon {
                            text: "logout"
                            fontStyle.pointSize: 16
                            color: Colours.palette.m3onErrorContainer
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: "Exit test mode"
                                font.family: "Google Sans Flex"
                                font.pointSize: 11
                                font.weight: Font.Medium
                                color: Colours.palette.m3onErrorContainer
                            }

                            Text {
                                text: "Close greeter preview window"
                                font.family: "Google Sans Flex"
                                font.pointSize: 8
                                color: Qt.alpha(Colours.palette.m3onErrorContainer, 0.75)
                            }
                        }

                        MaterialIcon {
                            text: "chevron_right"
                            fontStyle.pointSize: 16
                            color: Colours.palette.m3onErrorContainer
                        }
                    }

                    TapHandler {
                        onTapped: root.exitRequested()
                    }
                }
            }
        }
    }

    // ── Trigger Button Rect (Bottom-Left, connects with Popup) ───
    BlobRect {
        id: btnRect

        anchors.fill: parent
        group: blobGroup
        radius: root.isOpen ? 22 : 16

        Behavior on radius { NumberAnimation { duration: 150 } }

        MaterialIcon {
            anchors.centerIn: parent
            text: root.isOpen ? "close" : "tune"
            fontStyle.pointSize: 18
            color: root.isOpen
                ? Colours.palette.m3primary
                : Colours.palette.m3onSurface
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: {
                root.isOpen = !root.isOpen;
                if (!root.isOpen) root.shapeMenuOpen = false;
            }
        }
    }
}
