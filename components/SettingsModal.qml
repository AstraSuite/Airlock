pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Astra.Airlock
import M3Shapes
import "../services"
import "kit" as Kit
import "kit/containers" as Kit
import "kit/controls" as Kit

// Settings popup (bottom-left). Under Material 3 it morphs out of its
// trigger button as a liquid blob; under TTY it is a square bordered card
// over the shared ground, as KiiteShell's popups are. The rows inside are
// Atlas's controls either way, which draw themselves for TTY on their own.
Item {
    id: root

    property bool isOpen: false
    property bool shapeMenuOpen: false
    signal exitRequested()

    implicitWidth: 44
    implicitHeight: 44

    property real animDriver: 0

    readonly property int popupWidth: 350
    readonly property real popupHeight: contentCol.implicitHeight + 28

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

    // Index = GreeterState.uiStyle
    readonly property var styleOptions: [
        { value: 0, label: "KiiteShell", icon: "sync" },
        { value: 1, label: "Material 3", icon: "palette" },
        { value: 2, label: "TTY", icon: "terminal" }
    ]

    component SectionHeader: Kit.StyledText {
        Layout.leftMargin: 4
        Layout.topMargin: 6
        Layout.bottomMargin: 4
        color: Colours.palette.m3primary
        font: Tokens.font.label.large
    }

    component Toggle: Kit.ToggleRow {
        color: Colours.tPalette.m3surfaceContainerHigh
    }

    BlobGroup {
        id: blobGroup
        color: Colours.tPalette.m3surfaceContainer
        smoothing: 24
        cornerFill: false
    }

    // ── Material 3: popup blob, elevated above the trigger ───────
    BlobRect {
        id: popupRect

        visible: !Colours.tty
        anchors.left: parent.left
        anchors.bottom: parent.bottom

        implicitWidth: parent.width
        implicitHeight: parent.height

        group: blobGroup
        radius: 20
        deformScale: 0.00001

        states: State {
            name: "open"
            when: root.isOpen && !Colours.tty

            PropertyChanges {
                popupRect.anchors.bottomMargin: 64
                popupRect.anchors.leftMargin: 0
                popupRect.implicitWidth: root.popupWidth
                popupRect.implicitHeight: root.popupHeight
            }
        }

        transitions: Transition {
            NumberAnimation {
                properties: "bottomMargin,leftMargin,implicitWidth,implicitHeight"
                duration: 260
                easing.type: Easing.OutBack
                easing.overshoot: 1.10
            }
        }
    }

    // ── TTY: square bordered card in the same place, scanning in and
    // out as KiiteShell's popups do instead of morphing ────────────
    TtyScan {
        id: cardScan

        active: true
        shown: Colours.tty && root.isOpen
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 64
        width: root.popupWidth
        height: root.popupHeight

        Kit.StyledRect {
            anchors.fill: parent
            ttyFrame: true
            color: Colours.palette.m3surface
        }
    }

    states: State {
        name: "open"
        when: root.isOpen
        PropertyChanges { root.animDriver: 1 }
    }
    transitions: Transition {
        NumberAnimation {
            property: "animDriver"
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    // Popup content, inside whichever surface is showing
    Item {
        parent: Colours.tty ? cardScan.contentItem : popupRect
        anchors.fill: parent
        anchors.margins: 14
        clip: true
        opacity: Colours.tty ? 1 : root.animDriver
        visible: Colours.tty || opacity > 0

        // Click catcher so clicks inside don't dismiss
        MouseArea {
            anchors.fill: parent
            anchors.margins: -14
            enabled: root.isOpen
            onClicked: {}
        }

        ColumnLayout {
            id: contentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 2

            SectionHeader {
                Layout.topMargin: 2
                text: "Appearance & Display"
            }

            // ── Style: follow KiiteShell, Material 3, or TTY ─────
            Kit.ConnectedRect {
                Layout.fillWidth: true
                first: true
                color: Colours.tPalette.m3surfaceContainerHigh
                implicitHeight: styleCol.implicitHeight + Tokens.padding.medium * 2

                ColumnLayout {
                    id: styleCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Tokens.padding.large
                    anchors.rightMargin: Tokens.padding.large
                    spacing: Tokens.spacing.small

                    Kit.StyledText {
                        Layout.fillWidth: true
                        text: "Style"
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurface
                    }

                    Kit.StyledText {
                        Layout.fillWidth: true
                        text: {
                            if (TtyMode.forced)
                                return "Forced to TTY by --tty";
                            if (Colours.style !== 0)
                                return "Material 3 Expressive, or drawn like a terminal";
                            if (!Colours.kiiteAvailable)
                                return "KiiteShell isn't set up, so Material 3";
                            return Colours.tty ? "KiiteShell is using TTY" : "KiiteShell is using Material 3";
                        }
                        font: Tokens.font.label.small
                        color: Colours.palette.m3outline
                        elide: Text.ElideRight
                    }

                    Kit.SlidingSelector {
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        buttonHeight: 34
                        inactiveColor: Colours.tPalette.m3surfaceContainerHighest
                        model: root.styleOptions
                        currentValue: Colours.style
                        onSelected: value => Colours.setStyle(value)
                    }
                }
            }

            // ── Avatar shape (scrollable dropdown) ───────────────
            Kit.ConnectedRect {
                id: rowShape
                Layout.fillWidth: true
                implicitHeight: root.shapeMenuOpen ? (52 + shapeDropdownDrawer.implicitHeight) : 52
                color: shapeHover.hovered || root.shapeMenuOpen
                    ? Colours.tPalette.m3surfaceContainerHighest
                    : Colours.tPalette.m3surfaceContainerHigh
                clip: true

                Behavior on implicitHeight {
                    Kit.Anim { type: Kit.Anim.DefaultSpatial }
                }
                HoverHandler { id: shapeHover }

                Item {
                    id: shapeHeaderBar
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 52

                    Kit.StateLayer {
                        anchors.fill: parent
                        onClicked: root.shapeMenuOpen = !root.shapeMenuOpen
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.large
                        anchors.rightMargin: Tokens.padding.large
                        spacing: Tokens.spacing.medium

                        Kit.MaterialIcon {
                            text: "face"
                            color: Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.medium
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Kit.StyledText {
                                Layout.fillWidth: true
                                text: "Avatar shape"
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurface
                                elide: Text.ElideRight
                            }
                            Kit.StyledText {
                                Layout.fillWidth: true
                                text: Colours.avatarShapeName
                                font: Tokens.font.label.small
                                color: Colours.palette.m3outline
                                elide: Text.ElideRight
                            }
                        }

                        MaterialShape {
                            visible: !Colours.tty
                            implicitSize: 18
                            shape: Colours.avatarShape
                            color: Colours.palette.m3primary
                        }

                        Kit.MaterialIcon {
                            text: "expand_more"
                            color: Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.small
                            rotation: root.shapeMenuOpen && !Colours.tty ? 180 : 0
                            Behavior on rotation { Kit.Anim { type: Kit.Anim.FastSpatial } }
                        }
                    }
                }

                Item {
                    id: shapeDropdownDrawer
                    anchors.top: shapeHeaderBar.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    implicitHeight: 140
                    visible: root.shapeMenuOpen

                    Kit.VerticalFadeListView {
                        id: shapeListView
                        anchors.fill: parent
                        clip: true
                        model: root.shapeOptions
                        spacing: 2

                        delegate: Kit.StyledRect {
                            id: shapeItem
                            required property var modelData
                            required property int index

                            readonly property bool isSelected: Colours.avatarShape === modelData.value

                            width: shapeListView.width
                            implicitHeight: 32
                            radius: Tokens.rounding.small
                            color: shapeItem.isSelected ? Colours.tPalette.m3primaryContainer : "transparent"

                            Kit.StateLayer {
                                anchors.fill: parent
                                radius: parent.radius
                                onClicked: {
                                    Colours.avatarShape = shapeItem.modelData.value;
                                    Colours.avatarShapeName = shapeItem.modelData.name;
                                    root.shapeMenuOpen = false;
                                }
                            }

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

                                Kit.StyledText {
                                    Layout.fillWidth: true
                                    text: shapeItem.modelData.name
                                    font: Tokens.font.body.small
                                    color: shapeItem.isSelected
                                        ? Colours.palette.m3onPrimaryContainer
                                        : Colours.palette.m3onSurface
                                }

                                Kit.MaterialIcon {
                                    visible: shapeItem.isSelected
                                    text: "check"
                                    fontStyle: Tokens.font.icon.small
                                    color: Colours.palette.m3onPrimaryContainer
                                }
                            }
                        }
                    }
                }
            }

            Toggle {
                icon: "schedule"
                text: "12-hour clock"
                subtext: "Use AM/PM format instead of 24h"
                checked: Colours.use12Hour
                onToggled: v => Colours.use12Hour = v
            }

            Toggle {
                icon: "light_mode"
                text: "Light theme"
                subtext: Colours.tty ? "TTY is always dark" : "Use light color palette for greeter"
                disabled: Colours.tty
                checked: Colours.light
                onToggled: v => Colours.setMode(v ? "light" : "dark")
            }

            Toggle {
                icon: "bubble_chart"
                text: "Lava lamp animation"
                subtext: "Dynamic fluid background shapes"
                checked: Colours.lavaLampEnabled
                onToggled: v => Colours.lavaLampEnabled = v
            }

            Toggle {
                icon: "wallpaper"
                text: "Dynamic wallpaper"
                subtext: "Show synced wallpaper from caelestia"
                checked: Colours.wallpaperEnabled
                onToggled: v => Colours.wallpaperEnabled = v
            }

            Toggle {
                icon: "skip_next"
                text: "Skip clock screen"
                subtext: "Open login card immediately on startup"
                checked: Colours.skipClockPage
                onToggled: v => Colours.skipClockPage = v
            }

            Toggle {
                last: true
                icon: "dashboard"
                text: "Locklike layout"
                subtext: "Show full lockscreen widgets & dashboard"
                checked: Colours.locklikeEnabled
                onToggled: v => Colours.locklikeEnabled = v
            }

            // ── Session (test mode only) ─────────────────────────
            SectionHeader {
                visible: !Greetd.available
                Layout.topMargin: 8
                text: "Session"
            }

            Kit.ConnectedRect {
                visible: !Greetd.available
                Layout.fillWidth: true
                first: true
                last: true
                implicitHeight: 52
                color: Colours.tty ? Colours.palette.m3errorContainer : Qt.alpha(Colours.palette.m3errorContainer, 0.4)

                Kit.StateLayer {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Colours.palette.m3onErrorContainer
                    onClicked: root.exitRequested()
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.padding.large
                    anchors.rightMargin: Tokens.padding.large
                    spacing: Tokens.spacing.medium

                    Kit.MaterialIcon {
                        text: "logout"
                        fontStyle: Tokens.font.icon.medium
                        color: Colours.palette.m3onErrorContainer
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Kit.StyledText {
                            Layout.fillWidth: true
                            text: "Exit test mode"
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onErrorContainer
                        }
                        Kit.StyledText {
                            Layout.fillWidth: true
                            text: "Close greeter preview window"
                            font: Tokens.font.label.small
                            color: Qt.alpha(Colours.palette.m3onErrorContainer, 0.75)
                        }
                    }

                    Kit.MaterialIcon {
                        text: "chevron_right"
                        fontStyle: Tokens.font.icon.medium
                        color: Colours.palette.m3onErrorContainer
                    }
                }
            }

            // ── Battery simulation (test mode only) ──────────────
            SectionHeader {
                visible: !Greetd.available
                Layout.topMargin: 8
                text: "Battery"
            }

            Toggle {
                visible: !Greetd.available
                first: true
                icon: "bolt"
                text: "Charging"
                subtext: "Simulate plugged-in power"
                checked: BatteryState.simCharging
                onToggled: v => BatteryState.simCharging = v
            }

            SliderRow {
                visible: !Greetd.available
                Layout.fillWidth: true
                topLeftRadius: Tokens.rounding.extraSmall
                topRightRadius: Tokens.rounding.extraSmall
                bottomLeftRadius: Tokens.rounding.large
                bottomRightRadius: Tokens.rounding.large

                icon: "battery_full"
                label: "Battery level"
                value: BatteryState.simPercentage / 100
                onMoved: v => BatteryState.simPercentage = v * 100
            }
        }
    }

    // ── Trigger button (bottom-left, connects with the popup) ────
    BlobRect {
        id: btnRect

        visible: !Colours.tty
        anchors.fill: parent
        group: blobGroup
        radius: root.isOpen ? 22 : 16

        Behavior on radius { NumberAnimation { duration: 150 } }
    }

    Kit.MaterialIcon {
        anchors.centerIn: parent
        text: root.isOpen ? "close" : "tune"
        fontStyle: Tokens.font.icon.large
        color: root.isOpen ? Colours.palette.m3primary : Colours.palette.m3onSurface
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
