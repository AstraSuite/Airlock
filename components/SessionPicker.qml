pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Astra.Airlock
import "../services"

// Session picker dropdown — accent-color aware, matches the panel design
Item {
    id: root

    required property var sessions
    required property int currentIndex
    signal indexChanged(int index)

    property bool expanded: false

    implicitWidth: 220
    implicitHeight: 40

    // Selector pill
    Rectangle {
        id: selector
        anchors.fill: parent
        radius: 20
        color: Qt.rgba(0, 0, 0, 0.32)
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 8
            spacing: 6

            Text {
                text: {
                    const s = root.sessions[root.currentIndex];
                    return s && s.type === "Wayland" ? "monitor" : "desktop_windows";
                }
                font.family: "Material Symbols Rounded"
                font.pointSize: 15
                color: Colours.palette.m3primary
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            Text {
                Layout.fillWidth: true
                text: root.sessions.length > 0 && root.currentIndex >= 0
                    ? (root.sessions[root.currentIndex].name ?? "")
                    : qsTr("No sessions")
                font.pointSize: 10
                color: "white"
                elide: Text.ElideRight
            }

            Text {
                text: "expand_more"
                font.family: "Material Symbols Rounded"
                font.pointSize: 14
                color: Qt.rgba(1, 1, 1, 0.45)
                rotation: root.expanded ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }

    // Dropdown popup
    Rectangle {
        id: dropdown
        anchors.top: selector.bottom
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        radius: 14
        color: Qt.rgba(0.06, 0.09, 0.09, 0.92)
        border.color: Qt.alpha(Colours.palette.m3primary, 0.20)
        border.width: 1
        visible: root.expanded
        z: 999
        clip: true
        height: visible ? sessionList.implicitHeight + 8 : 0
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Column {
            id: sessionList
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 4
            spacing: 2

            Repeater {
                model: root.sessions
                delegate: Rectangle {
                    id: sessRow
                    required property int index
                    required property var modelData

                    width: parent.width
                    height: 38
                    radius: 8
                    color: root.currentIndex === sessRow.index
                        ? Qt.alpha(Colours.palette.m3primary, 0.18)
                        : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: sessRow.modelData.type === "Wayland" ? "monitor" : "desktop_windows"
                            font.family: "Material Symbols Rounded"
                            font.pointSize: 14
                            color: root.currentIndex === sessRow.index
                                ? Colours.palette.m3primary
                                : Qt.rgba(1, 1, 1, 0.45)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: sessRow.modelData.name ?? ""
                            font.pointSize: 10
                            color: root.currentIndex === sessRow.index
                                ? "white"
                                : Qt.rgba(1, 1, 1, 0.70)
                        }

                        Text {
                            text: sessRow.modelData.type ?? ""
                            font.pointSize: 8
                            color: Qt.rgba(1, 1, 1, 0.28)
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.indexChanged(sessRow.index);
                            root.expanded = false;
                        }
                    }
                }
            }
        }
    }
}
