pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Greetd
import Astra.Airlock
import "../services"
import "../components"
import "../modules"

// Full-screen greeter surface matching Caelestia shell design language.
//
// IDLE   — M3 Lava Lamp background (crisp shapes), Titan One chubby stacked clock, power menu top-left, settings bottom-left, schemes bottom-right
// ACTIVE — Lava Lamp softly blurs into bokeh, Titan One clock fades, active clock/date appears in top-right, clean central login card fades in
Rectangle {
    id: root

    signal exitRequested()

    color: Colours.palette.m3background

    property bool panelVisible: Colours.skipClockPage
    property bool wallpaperEnabled: Colours.wallpaperEnabled
    property bool entered: false

    Component.onCompleted: {
        Qt.callLater(() => { root.entered = true; });
    }

    Connections {
        target: Colours
        function onSkipClockPageChanged() {
            root.panelVisible = Colours.skipClockPage;
        }
    }

    function exitTestMode() {
        root.exitRequested();
    }

    property string imageSource: "/var/cache/astra-airlock/wallpapers/" + Colours.currentUser
    onImageSourceChanged: {
        if (wallpaper.active) {
            wallpaper.active = false;
            wallpaperTop.source = imageSource;
        } else {
            wallpaper.active = true;
            wallpaper.source = imageSource;
        }
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: "/var/cache/astra-airlock/wallpapers/" + Colours.currentUser
        fillMode: Image.PreserveAspectCrop
        visible: root.enabled
        opacity: root.wallpaperEnabled ? 1 : 0
        scale: root.panelVisible ? 1 : 1.02
        property bool active: true

        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: root.panelVisible ? 0.7 : 0
            blurMax: 54
            blurMultiplier: 1.0
            Behavior on blur { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        }
    }

    Image {
        id: wallpaperTop
        anchors.fill: parent
        source: "/var/cache/astra-airlock/wallpapers/" + Colours.currentUser
        fillMode: Image.PreserveAspectCrop
        visible: true
        opacity: root.wallpaperEnabled && !wallpaper.active ? 1 : 0
        scale: root.panelVisible ? 1 : 1.02

        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: root.panelVisible ? 0.7 : 0
            blurMax: 54
            blurMultiplier: 1.0
            Behavior on blur { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        }
    }

    // ── Background Layer (captured by BackdropBlur in modals) ────
    Item {
        id: bgLayer
        anchors.fill: parent
        opacity: root.entered ? 1 : 0
        scale: root.entered ? 1 : 0.97
        Behavior on opacity { NumberAnimation { duration: 650; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 650; easing.type: Easing.OutCubic } }

        // Hardware-Accelerated Lava Lamp (blurs only when login panel opens)
        LavaLamp {
            anchors.fill: parent
            blurry: root.panelVisible
            opacity: root.panelVisible ? 0.62 : 0.75
            Behavior on opacity { NumberAnimation { duration: 400 } }
        }

        // IDLE view: Titan One Stacked Clock
        Item {
            anchors.fill: parent
            opacity: root.entered ? (root.panelVisible ? 0 : 1) : 0
            scale: root.entered ? (root.panelVisible ? 0.90 : 1) : 0.92
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

            IdleClock {
                anchors.centerIn: parent
            }

            // "Press enter or any key to unlock" pulsing hint
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 48
                text: "PRESS ENTER OR ANY KEY TO UNLOCK"
                font.family: "Google Sans Flex"
                font.pointSize: 11
                font.weight: Font.DemiBold
                font.variableAxes: { "wdth": 80 }
                color: Colours.palette.m3onSurface
                font.letterSpacing: 2.0
                opacity: 0.60

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.25; duration: 1500; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 0.85; duration: 1500; easing.type: Easing.InOutQuad }
                }
            }
        }
    }

    // Tap/Click anywhere on idle screen to reveal login panel
    MouseArea {
        anchors.fill: parent
        enabled: !root.panelVisible && !settingsModal.isOpen && !schemeModal.isOpen
        onClicked: {
            root.panelVisible = true;
            keyCapture.forceActiveFocus();
        }
    }

    // ── Power Actions + Battery (Top-Left Corner) ────────────────
    Row {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 24
        anchors.topMargin: root.entered ? 24 : 8
        spacing: 10
        z: 2000
        opacity: root.entered ? 1 : 0
        Behavior on opacity          { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on anchors.topMargin { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

        PowerMenu {
            id: powerMenu
            anchors.verticalCenter: parent.verticalCenter
        }

        BatteryIcon {
            id: batteryIcon
            anchors.verticalCenter: parent.verticalCenter
            visible: BatteryState.available
            size: 50
            percentage: BatteryState.percentage / 100
            charging: BatteryState.charging
        }
    }

    // ── Active Clock & Date (Top-Right Corner) ────────────────────
    ActiveClock {
        id: activeClock
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 28
        anchors.topMargin: root.entered ? 24 : 8
        z: 2000
        opacity: root.entered ? (root.panelVisible && !Colours.locklikeEnabled ? 1 : 0) : 0
        Behavior on opacity          { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
        Behavior on anchors.topMargin { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
    }

    // ── ACTIVE view: Login Panel (Standard or Locklike) ───────────
    Item {
        anchors.fill: parent
        opacity: root.entered ? (root.panelVisible ? 1 : 0) : 0
        scale: root.entered ? (root.panelVisible ? 1 : 1.05) : 0.94
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

        Loader {
            id: activePanelLoader
            anchors.centerIn: parent
            sourceComponent: Colours.locklikeEnabled ? locklikeComp : standardComp
        }

        Component {
            id: standardComp
            Center {
                onDismissed: {
                    root.panelVisible = false;
                    keyCapture.forceActiveFocus();
                }
            }
        }

        Component {
            id: locklikeComp
            LocklikePanel {
                onDismissed: {
                    root.panelVisible = false;
                    keyCapture.forceActiveFocus();
                }
            }
        }
    }

    // ── Click-outside backdrop to dismiss open modals ────────────
    MouseArea {
        anchors.fill: parent
        z: 1999
        enabled: settingsModal.isOpen || schemeModal.isOpen
        visible: enabled
        onClicked: {
            settingsModal.isOpen = false;
            schemeModal.isOpen = false;
            keyCapture.forceActiveFocus();
        }
    }

    // ── Morphing Settings Modal (Bottom-Left) ─────────────────────
    SettingsModal {
        id: settingsModal
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 24
        anchors.bottomMargin: root.entered ? 24 : 8
        opacity: root.entered ? 1 : 0
        z: 2000
        onExitRequested: root.exitTestMode()
        onIsOpenChanged: {
            if (!isOpen) keyCapture.forceActiveFocus();
        }
        Behavior on opacity             { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
    }

    // ── Morphing Schemes Modal (Bottom-Right) ────────────────────
    SchemePickerModal {
        id: schemeModal
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 24
        anchors.bottomMargin: root.entered ? 24 : 8
        opacity: root.entered ? 1 : 0
        z: 2000
        onUnfocusRequested: keyCapture.forceActiveFocus()
        onIsOpenChanged: {
            if (!isOpen) keyCapture.forceActiveFocus();
        }
        Behavior on opacity             { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
    }

    // ── On-Screen Virtual Keyboard Overlay (Screen-Wide, Draggable Anywhere) ──
    OnScreenKeyboard {
        id: osk
        z: 3000
        visible: Colours.oskActive
        opacity: Colours.oskActive ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        onKeyClicked: key => {
            if (activePanelLoader.item) {
                root.panelVisible = true;
                activePanelLoader.item.passwordBuffer += key;
            }
        }
        onBackspaceClicked: {
            if (activePanelLoader.item) {
                activePanelLoader.item.passwordBuffer = activePanelLoader.item.passwordBuffer.slice(0, -1);
            }
        }
        onClearClicked: {
            if (activePanelLoader.item) {
                activePanelLoader.item.passwordBuffer = "";
            }
        }
        onEnterClicked: {
            if (activePanelLoader.item) {
                activePanelLoader.item._submit();
            }
        }
        onCloseClicked: Colours.oskActive = false
    }

    // ── Dedicated Key Capture Handler ─────────────────────────────
    Item {
        id: keyCapture
        anchors.fill: parent
        focus: true

        Component.onCompleted: forceActiveFocus()

        onActiveFocusChanged: {
            if (!activeFocus && !schemeModal.isOpen && !settingsModal.isOpen) {
                keyCapture.forceActiveFocus();
            }
        }

        Keys.onPressed: event => {
            // Close modals if open on Escape
            if (settingsModal.isOpen && event.key === Qt.Key_Escape) {
                settingsModal.isOpen = false;
                event.accepted = true;
                return;
            }
            if (schemeModal.isOpen && event.key === Qt.Key_Escape) {
                schemeModal.isOpen = false;
                event.accepted = true;
                return;
            }

            // Test-mode exit
            if (!Greetd.available) {
                if ((event.key === Qt.Key_Q && (event.modifiers & Qt.ControlModifier))
                    || (event.key === Qt.Key_C && (event.modifiers & Qt.ControlModifier))) {
                    root.exitTestMode();
                    event.accepted = true;
                    return;
                }
            }

            // When in IDLE mode: any key press (Enter, Space, etc.) reveals the panel!
            if (!root.panelVisible) {
                if (event.key === Qt.Key_Escape) {
                    if (!Greetd.available) {
                        root.exitTestMode();
                        event.accepted = true;
                        return;
                    }
                }
                root.panelVisible = true;
                event.accepted = true;
                return;
            }

            // When in ACTIVE mode: forward to center login panel
            if (root.panelVisible && activePanelLoader.item) {
                activePanelLoader.item.handleKey(event);
                event.accepted = true;
            }
        }
    }
}
