pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Greetd
import Caelestia.Greeter
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

    property bool panelVisible: false

    function exitTestMode() {
        root.exitRequested();
    }

    // ── Background Layer (captured by BackdropBlur in modals) ────
    Item {
        id: bgLayer
        anchors.fill: parent

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
            opacity: root.panelVisible ? 0 : 1
            scale: root.panelVisible ? 0.90 : 1
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

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

    // ── Power Actions (Top-Left Corner) ──────────────────────────
    PowerMenu {
        id: powerMenu
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 24
        anchors.topMargin: 24
        z: 2000
    }

    // ── Active Clock & Date (Top-Right Corner) ────────────────────
    ActiveClock {
        id: activeClock
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 28
        anchors.topMargin: 24
        z: 2000
        opacity: root.panelVisible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
    }

    // ── ACTIVE view: Clean Centered Login Panel ───────────────────
    Item {
        anchors.fill: parent
        opacity: root.panelVisible ? 1 : 0
        scale: root.panelVisible ? 1 : 1.05
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

        Center {
            id: centerPanel
            anchors.centerIn: parent
            onDismissed: {
                root.panelVisible = false;
                keyCapture.forceActiveFocus();
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
        }
    }

    // ── Morphing Settings Modal (Bottom-Left) ─────────────────────
    SettingsModal {
        id: settingsModal
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 24
        anchors.bottomMargin: 24
        z: 2000
        onExitRequested: root.exitTestMode()
    }

    // ── Morphing Schemes Modal (Bottom-Right) ────────────────────
    SchemePickerModal {
        id: schemeModal
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 24
        anchors.bottomMargin: 24
        z: 2000
    }

    // ── Dedicated Key Capture Handler ─────────────────────────────
    Item {
        id: keyCapture
        anchors.fill: parent
        focus: true

        Component.onCompleted: forceActiveFocus()

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
            if (root.panelVisible && centerPanel) {
                centerPanel.handleKey(event);
                event.accepted = true;
            }
        }
    }
}
