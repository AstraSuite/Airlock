pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes
import "../services"
import "../components"

// Password input pill matching Caelestia lock screen (modules/lock/center/PasswordInput.qml).
// Pill dynamically expands when characters are entered and shrinks to snugly wrap placeholder when empty.
// Features MaterialShape morphing arrow submit button and loading state.
StyledRect {
    id: root

    property string buffer: ""
    property bool authenticating: false
    property bool authFailed: false
    property string authPrompt: ""
    property int centerWidth: 360

    signal submitted()

    implicitWidth: {
        const expandedW = centerWidth * 0.84;
        const snugW = inputField.placeholderWidth + iconWrapper.implicitWidth + enterButton.implicitWidth + inputLayout.spacing * 2 + inputLayout.anchors.leftMargin + inputLayout.anchors.rightMargin + 12;
        return root.buffer.length > 0 ? expandedW : Math.min(expandedW, snugW);
    }
    implicitHeight: 42

    color: Colours.tPalette.m3surfaceContainerHigh
    radius: height / 2

    Behavior on implicitWidth {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    onAuthFailedChanged: {
        if (authFailed) failFlash.restart();
    }

    // Error flash overlay
    Rectangle {
        id: errorFlash
        anchors.fill: parent
        radius: parent.radius
        color: Qt.rgba(Colours.palette.m3error.r, Colours.palette.m3error.g, Colours.palette.m3error.b, 0)

        SequentialAnimation {
            id: failFlash
            NumberAnimation {
                target: errorFlash
                property: "color.a"
                to: 0.30
                duration: 60
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: errorFlash
                property: "color.a"
                to: 0
                duration: 400
                easing.type: Easing.OutQuad
            }
        }
    }

    RowLayout {
        id: inputLayout
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 6

        // Left Icon Wrapper (Lock / Morphing Loader)
        Item {
            id: iconWrapper
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 28
            implicitHeight: 28

            LoadingIndicator {
                anchors.centerIn: parent
                implicitSize: 24
                animated: root.authenticating
                opacity: root.authenticating ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: "lock"
                color: root.authFailed ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                fontStyle.pointSize: 16
                opacity: root.authenticating ? 0 : 1

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
            }
        }

        // Center InputField with MaterialShape morphing characters
        InputField {
            id: inputField
            Layout.fillWidth: true
            Layout.fillHeight: true
            buffer: root.buffer
            placeholderText: root.authPrompt.length > 0 ? root.authPrompt : qsTr("Enter your password")
            authenticating: root.authenticating
        }

        // Right Enter Button (MaterialShape Arrow / Circle)
        Item {
            id: enterButton
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 28
            implicitHeight: 28

            MaterialShape {
                anchors.fill: parent
                color: root.buffer.length > 0
                    ? Colours.palette.m3primary
                    : Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.60)
                shape: root.buffer.length > 0 ? MaterialShape.Arrow : MaterialShape.Circle
                scale: root.buffer.length === 0 ? 1 : enterMouse.pressed ? 0.65 : enterMouse.containsMouse ? 0.88 : 0.78
                rotation: 90

                Behavior on scale {
                    NumberAnimation { duration: 150; easing.type: Easing.OutBack }
                }

                Behavior on color {
                    CAnim {}
                }

                MouseArea {
                    id: enterMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: root.buffer.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (root.buffer.length > 0) root.submitted();
                    }
                }
            }

            MaterialIcon {
                id: enterIcon
                anchors.centerIn: parent
                text: "arrow_forward"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle.pointSize: 14
                opacity: root.buffer.length > 0 ? 0 : 1

                Behavior on opacity {
                    NumberAnimation { duration: 120 }
                }
            }
        }
    }
}
