pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import M3Shapes
import "../services"
import "../components"

// Lock screen input field matching Caelestia's modules/lock/center/InputField.qml
// Each typed character pops in as a randomized MaterialShape, pauses for 180ms,
// then smoothly morphs into a small circle.
Item {
    id: root

    property string buffer: ""
    property string placeholderText: qsTr("Enter your password")
    property bool authenticating: false
    readonly property alias placeholder: placeholder
    readonly property alias placeholderWidth: nonAnimPlaceholder.width

    readonly property list<int> shapeQueue: {
        const shapes = [
            MaterialShape.Slanted,
            MaterialShape.Arch,
            MaterialShape.Fan,
            MaterialShape.Arrow,
            MaterialShape.SemiCircle,
            MaterialShape.Triangle,
            MaterialShape.Diamond,
            MaterialShape.ClamShell,
            MaterialShape.Pentagon,
            MaterialShape.Gem,
            MaterialShape.Sunny,
            MaterialShape.VerySunny,
            MaterialShape.Cookie4Sided,
            MaterialShape.Ghostish,
            MaterialShape.SoftBurst
        ];
        for (let i = shapes.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [shapes[i], shapes[j]] = [shapes[j], shapes[i]];
        }
        return shapes;
    }

    clip: true

    onBufferChanged: {
        if (root.buffer.length > prevBuffer.length) {
            charList.bindImWidth();
        } else if (root.buffer.length === 0) {
            charList.implicitWidth = charList.implicitWidth;
            placeholder.animate = true;
        }
        prevBuffer = root.buffer;
    }
    property string prevBuffer: ""

    TextMetrics {
        id: nonAnimPlaceholder
        text: root.authenticating ? qsTr("Authenticating...") : root.placeholderText
        font: placeholder.font
    }

    StyledText {
        id: placeholder
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 1

        text: nonAnimPlaceholder.text
        animate: true
        color: root.authenticating ? Colours.palette.m3secondary : Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.55)
        font.family: "Google Sans Flex"
        font.pointSize: 11

        opacity: root.buffer.length > 0 ? 0 : 1
        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    ListView {
        id: charList

        readonly property int fullWidth: {
            let w = (count - 1) * spacing;
            for (let i = 0; i < count; i++)
                w += ((itemAtIndex(i) as CharItem)?.nonAnimWidthScale ?? 1) * implicitHeight;
            return w + implicitHeight;
        }

        function bindImWidth(): void {
            imWidthBehavior.enabled = false;
            implicitWidth = Qt.binding(() => fullWidth);
            imWidthBehavior.enabled = true;
        }

        anchors.centerIn: parent
        anchors.horizontalCenterOffset: implicitWidth > root.width ? -(implicitWidth - root.width) / 2 : 0

        implicitWidth: fullWidth
        implicitHeight: 14

        orientation: Qt.Horizontal
        spacing: 4
        interactive: false

        model: ScriptModel {
            values: root.buffer.split("")
        }

        delegate: CharItem {}

        Behavior on implicitWidth {
            id: imWidthBehavior
            NumberAnimation { duration: 120 }
        }
    }

    component CharItem: Item {
        id: char

        required property int index
        property real nonAnimWidthScale: 1

        implicitHeight: charList.implicitHeight
        implicitWidth: charList.implicitHeight

        ListView.onRemove: {
            initAnim.stop();
            removeAnim.start();
        }

        MaterialShape {
            id: charShape

            anchors.centerIn: parent
            implicitSize: charList.implicitHeight * 1.5
            shape: root.shapeQueue[char.index % root.shapeQueue.length] ?? MaterialShape.Circle
            color: Colours.palette.m3onSurface

            Behavior on color {
                CAnim {}
            }

            SequentialAnimation {
                id: initAnim
                running: true

                ParallelAnimation {
                    NumberAnimation {
                        target: charShape
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: charShape
                        property: "scale"
                        from: 0
                        to: 1
                        duration: 180
                        easing.type: Easing.OutBack
                    }
                    NumberAnimation {
                        target: char
                        property: "implicitWidth"
                        from: charList.implicitHeight
                        to: charList.implicitHeight * 1.3
                        duration: 120
                    }
                    PropertyAction {
                        target: char
                        property: "nonAnimWidthScale"
                        value: 1.5
                    }
                }
                PauseAnimation {
                    duration: 180
                }
                PropertyAction {
                    target: charShape
                    property: "shape"
                    value: MaterialShape.Circle
                }
                ParallelAnimation {
                    NumberAnimation {
                        target: charShape
                        property: "scale"
                        to: 2 / 3
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: char
                        property: "implicitWidth"
                        to: charList.implicitHeight
                        duration: 120
                    }
                    PropertyAction {
                        target: char
                        property: "nonAnimWidthScale"
                        value: 1
                    }
                }
            }

            SequentialAnimation {
                id: removeAnim

                PropertyAction {
                    target: char
                    property: "ListView.delayRemove"
                    value: true
                }
                ParallelAnimation {
                    NumberAnimation {
                        target: charShape
                        property: "opacity"
                        to: 0
                        duration: 100
                    }
                    NumberAnimation {
                        target: charShape
                        property: "scale"
                        to: 0.5
                        duration: 100
                    }
                }
                PropertyAction {
                    target: char
                    property: "ListView.delayRemove"
                    value: false
                }
            }
        }
    }
}
