pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Astra.Airlock
import "../services"

// On-Screen Virtual Keyboard for touchscreens & accessibility
// Draggable anywhere on the screen, impenetrable click-blocking, standard 5-row US layout with Tab, \, and centered Space
Rectangle {
    id: root

    signal keyClicked(string key)
    signal backspaceClicked()
    signal enterClicked()
    signal clearClicked()
    signal closeClicked()

    property bool shiftActive: false
    property bool capsActive: false

    function getShifted(key: string): string {
        const map = {
            "`": "~", "1": "!", "2": "@", "3": "#", "4": "$", "5": "%",
            "6": "^", "7": "&", "8": "*", "9": "(", "0": ")", "-": "_", "=": "+",
            "[": "{", "]": "}", "\\": "|", ";": ":", "'": "\"", ",": "<", ".": ">", "/": "?"
        };
        if (map[key] !== undefined) return map[key];
        return key.toUpperCase();
    }

    implicitWidth: 880
    implicitHeight: 285
    radius: 28
    color: Colours.tPalette.m3surfaceContainerHigh

    Behavior on color { ColorAnimation { duration: 150 } }

    function resetPosition() {
        if (parent) {
            x = Math.max(10, Math.round((parent.width - width) / 2));
            y = Math.max(10, Math.round(parent.height - height - 32));
        }
    }

    onParentChanged: resetPosition()
    Component.onCompleted: resetPosition()

    Connections {
        target: Colours
        function onOskActiveChanged() {
            if (Colours.oskActive) {
                root.resetPosition();
            }
        }
    }

    // Intercept all mouse and touch events so nothing can click through to items beneath
    MouseArea {
        anchors.fill: parent
        z: -1
        preventStealing: true
        onPressed: mouse => mouse.accepted = true
        onReleased: mouse => mouse.accepted = true
        onClicked: mouse => mouse.accepted = true
        onDoubleClicked: mouse => mouse.accepted = true
        onWheel: wheel => wheel.accepted = true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6

        // Top control bar: Drag Handle + Title + Close Button
        RowLayout {
            id: topBar
            Layout.fillWidth: true
            implicitHeight: 28
            spacing: 8

            // Draggable header area
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.SizeAllCursor
                    drag.target: root
                    drag.minimumX: 0
                    drag.maximumX: root.parent ? Math.max(0, root.parent.width - root.width) : 10000
                    drag.minimumY: 0
                    drag.maximumY: root.parent ? Math.max(0, root.parent.height - root.height) : 10000
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    MaterialIcon {
                        text: "drag_indicator"
                        iconSize: 18
                        color: Colours.palette.m3outline
                    }

                    MaterialIcon {
                        text: "keyboard"
                        iconSize: 18
                        color: Colours.palette.m3primary
                    }

                    Text {
                        text: "Virtual Keyboard (Drag to move)"
                        font.family: "Google Sans Flex"
                        font.pointSize: 11
                        font.weight: Font.Medium
                        color: Colours.palette.m3onSurface
                        Layout.fillWidth: true
                    }
                }
            }

            Rectangle {
                implicitWidth: 26
                implicitHeight: 26
                radius: 13
                color: hClose.hovered ? Colours.tPalette.m3surfaceContainerHighest : "transparent"
                HoverHandler { id: hClose }

                StateLayer {
                    onClicked: root.closeClicked()
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "close"
                    iconSize: 16
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }

        // Row 1: Numbers & symbols (14 keys: ` 1 2 3 4 5 6 7 8 9 0 - = Backspace)
        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            Repeater {
                model: ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="]
                KeyButton {
                    required property string modelData
                    label: root.shiftActive ? root.getShifted(modelData) : modelData
                    onClicked: {
                        root.keyClicked(label);
                        if (root.shiftActive) root.shiftActive = false;
                    }
                }
            }

            KeyButton {
                icon: "backspace"
                Layout.preferredWidth: 68
                isAccent: true
                onClicked: root.backspaceClicked()
            }
        }

        // Row 2: QWERTY + Tab + \ (14 keys: Tab q w e r t y u i o p [ ] \)
        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            KeyButton {
                label: "Tab"
                icon: "keyboard_tab"
                Layout.preferredWidth: 62
                onClicked: root.keyClicked("\t")
            }

            Repeater {
                model: ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]"]
                KeyButton {
                    required property string modelData
                    label: (root.shiftActive || root.capsActive) ? root.getShifted(modelData) : modelData
                    onClicked: {
                        root.keyClicked(label);
                        if (root.shiftActive) root.shiftActive = false;
                    }
                }
            }

            KeyButton {
                label: root.shiftActive ? "|" : "\\"
                Layout.preferredWidth: 54
                onClicked: {
                    root.keyClicked(label);
                    if (root.shiftActive) root.shiftActive = false;
                }
            }
        }

        // Row 3: ASDF + Caps + Enter (13 keys: Caps a s d f g h j k l ; ' Enter)
        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            KeyButton {
                label: "Caps"
                Layout.preferredWidth: 70
                isAccent: root.capsActive
                onClicked: root.capsActive = !root.capsActive
            }

            Repeater {
                model: ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'"]
                KeyButton {
                    required property string modelData
                    label: (root.shiftActive || root.capsActive) ? root.getShifted(modelData) : modelData
                    onClicked: {
                        root.keyClicked(label);
                        if (root.shiftActive) root.shiftActive = false;
                    }
                }
            }

            KeyButton {
                icon: "subdirectory_arrow_left"
                label: "Enter"
                Layout.preferredWidth: 84
                isAccent: true
                onClicked: root.enterClicked()
            }
        }

        // Row 4: ZXCV + Left Shift + Right Shift (12 keys: Shift z x c v b n m , . / Shift)
        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            KeyButton {
                icon: "shift"
                label: "Shift"
                Layout.preferredWidth: 86
                isAccent: root.shiftActive
                onClicked: root.shiftActive = !root.shiftActive
            }

            Repeater {
                model: ["z", "x", "c", "v", "b", "n", "m", ",", ".", "/"]
                KeyButton {
                    required property string modelData
                    label: (root.shiftActive || root.capsActive) ? root.getShifted(modelData) : modelData
                    onClicked: {
                        root.keyClicked(label);
                        if (root.shiftActive) root.shiftActive = false;
                    }
                }
            }

            KeyButton {
                icon: "shift"
                label: "Shift"
                Layout.preferredWidth: 86
                isAccent: root.shiftActive
                onClicked: root.shiftActive = !root.shiftActive
            }
        }

        // Row 5: Bottom Row with Centered Spacebar!
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            KeyButton {
                label: "Hide"
                icon: "keyboard_hide"
                Layout.preferredWidth: 90
                onClicked: root.closeClicked()
            }

            KeyButton {
                label: "Space"
                Layout.fillWidth: true
                Layout.preferredWidth: 420
                onClicked: root.keyClicked(" ")
            }

            KeyButton {
                label: "Clear"
                icon: "clear_all"
                Layout.preferredWidth: 90
                onClicked: root.clearClicked()
            }
        }
    }

    component KeyButton: Rectangle {
        id: kBtn

        property string label: ""
        property string icon: ""
        property bool isAccent: false
        signal clicked()

        Layout.fillWidth: true
        Layout.preferredWidth: 46
        implicitHeight: 38
        radius: 10

        color: isAccent
            ? Colours.palette.m3primary
            : (hKey.hovered ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainer)

        Behavior on color { ColorAnimation { duration: 100 } }
        HoverHandler { id: hKey }

        StateLayer {
            onClicked: kBtn.clicked()
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 4

            MaterialIcon {
                visible: kBtn.icon !== ""
                text: kBtn.icon
                iconSize: 15
                color: kBtn.isAccent ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            }

            Text {
                visible: kBtn.label !== ""
                text: kBtn.label
                font.family: "Google Sans Flex"
                font.pointSize: 11
                font.weight: Font.Medium
                color: kBtn.isAccent ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            }
        }
    }
}
