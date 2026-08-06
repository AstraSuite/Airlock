pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../services"

// Settings panel anchored to bottom-left.
// Opens a glass card above the gear button with:
//   - 12/24h toggle
//   - List of available caelestia schemes (from `caelestia scheme list`)
Item {
    id: root

    property bool open: false

    implicitWidth: 240
    implicitHeight: gearBtn.height

    // ── Card ──────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.bottom: gearBtn.top
        anchors.bottomMargin: 8
        anchors.left: parent.left
        width: 240
        radius: 16
        height: root.open ? cardCol.implicitHeight + 24 : 0
        clip: true
        color: Qt.rgba(
            Colours.palette.m3surfaceContainer.r,
            Colours.palette.m3surfaceContainer.g,
            Colours.palette.m3surfaceContainer.b,
            0.92
        )
        border.color: Qt.alpha(Colours.palette.m3outline, 0.35)
        border.width: 1

        opacity: root.open ? 1 : 0

        Behavior on height  { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: cardCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 14
            anchors.topMargin: 14
            spacing: 12

            // ── 12/24h toggle ──────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "24-hour clock"
                    font.family: "Google Sans Flex"
                    font.pointSize: 10
                    color: Colours.palette.m3onSurface
                    Layout.fillWidth: true
                }

                Rectangle {
                    id: toggle
                    width: 44; height: 24; radius: 12
                    color: !GreeterState.use12h
                        ? Qt.alpha(Colours.palette.m3primary, 0.88)
                        : Qt.alpha(Colours.palette.m3onSurface, 0.15)
                    Behavior on color { ColorAnimation { duration: 180 } }

                    Rectangle {
                        width: 18; height: 18; radius: 9
                        color: "white"
                        anchors.verticalCenter: parent.verticalCenter
                        x: !GreeterState.use12h ? parent.width - width - 3 : 3
                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: GreeterState.use12h = !GreeterState.use12h
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.alpha(Colours.palette.m3outline, 0.20) }

            // ── Scheme label ──────────────────────────────────
            Text {
                text: "SCHEME"
                font.family: "Google Sans Flex"
                font.pointSize: 8.5
                font.letterSpacing: 1.5
                color: Colours.palette.m3onSurfaceVariant
            }

            // ── Scheme list ───────────────────────────────────
            Column {
                Layout.fillWidth: true
                spacing: 2
                Layout.bottomMargin: 2

                Repeater {
                    model: GreeterState.availableSchemes
                    delegate: Rectangle {
                        id: schemeRow
                        required property string modelData
                        required property int index

                        width: cardCol.width
                        height: 34
                        radius: 8
                        color: GreeterState.currentScheme === schemeRow.modelData
                            ? Qt.alpha(Colours.palette.m3primary, 0.18)
                            : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            // Primary color preview dot
                            Rectangle {
                                width: 10; height: 10; radius: 5
                                color: GreeterState.currentScheme === schemeRow.modelData
                                    ? Colours.palette.m3primary
                                    : Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.5)
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: schemeRow.modelData
                                font.family: "Google Sans Flex"
                                font.pointSize: 10
                                color: GreeterState.currentScheme === schemeRow.modelData
                                    ? Colours.palette.m3primary
                                    : Colours.palette.m3onSurface
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            Text {
                                text: "check"
                                font.family: "Material Symbols Rounded"
                                font.pointSize: 14
                                color: Colours.palette.m3primary
                                visible: GreeterState.currentScheme === schemeRow.modelData
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: GreeterState.setScheme(schemeRow.modelData)
                        }
                    }
                }
            }
        }
    }

    // ── Gear button ───────────────────────────────────────────
    Rectangle {
        id: gearBtn
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: 40; height: 40; radius: 12
        color: root.open
            ? Qt.alpha(Colours.palette.m3primaryContainer, 0.80)
            : Qt.rgba(
                Colours.palette.m3surfaceContainerHigh.r,
                Colours.palette.m3surfaceContainerHigh.g,
                Colours.palette.m3surfaceContainerHigh.b,
                0.72)
        border.color: Qt.alpha(Colours.palette.m3outline, 0.25)
        border.width: 1
        Behavior on color { ColorAnimation { duration: 180 } }

        Text {
            anchors.centerIn: parent
            text: "settings"
            font.family: "Material Symbols Rounded"
            font.pointSize: 18
            color: root.open ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
            rotation: root.open ? 45 : 0
            Behavior on rotation { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 180 } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.open = !root.open
        }
    }
}
