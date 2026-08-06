pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Caelestia.Greeter
import "../services"

// User selection modal matching Caelestia Nexus DialogSelectButton / Add new entry modal:
// Opaque elevated surface, drop shadow, backdrop dismiss, morphing expansion animation,
// circular profile pictures, left-aligned text, far-right plain checkmark, and Cancel/Switch actions.
Item {
    id: root

    property bool isOpen: false
    property int selectedIndex: 0
    property int tempSelectedIndex: selectedIndex
    signal userSelected(int index)

    implicitWidth: 340
    implicitHeight: 380

    visible: opacity > 0
    opacity: isOpen ? 1.0 : 0.0
    scale: isOpen ? 1.0 : 0.90
    transformOrigin: Item.Center

    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on scale   { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

    onIsOpenChanged: {
        if (isOpen) {
            tempSelectedIndex = selectedIndex;
        }
    }

    // ── Main Dialog Card with Elevation Shadow ──────────────────────
    Rectangle {
        id: card
        anchors.fill: parent
        radius: 24
        color: Colours.tPalette.m3surfaceContainerHighest
        Behavior on color { ColorAnimation { duration: 200 } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 16
            shadowColor: Qt.rgba(0, 0, 0, 0.7)
            shadowVerticalOffset: 4
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // ── Header Row (No Close button, relies on Cancel / Switch) ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    implicitWidth: 34
                    implicitHeight: 34
                    radius: 17
                    color: Qt.alpha(Colours.palette.m3primary, 0.15)

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "manage_accounts"
                        fontStyle.pointSize: 18
                        color: Colours.palette.m3primary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Switch User"
                        font.family: "Google Sans Flex"
                        font.pointSize: 13
                        font.weight: Font.DemiBold
                        color: Colours.palette.m3onSurface
                    }

                    Text {
                        text: "Select an account to sign in"
                        font.family: "Google Sans Flex"
                        font.pointSize: 9
                        color: Colours.palette.m3outline
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Qt.alpha(Colours.palette.m3outlineVariant, 0.30)
            }

            // ── Clean User List View ────────────────────────────────
            VerticalFadeListView {
                id: userList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                model: UserDiscovery.users
                fadeAmount: 0.12

                delegate: Rectangle {
                    id: userRow
                    required property int index
                    required property var modelData

                    width: userList.width
                    implicitHeight: 52
                    radius: 14

                    readonly property bool isSelected: root.tempSelectedIndex === index
                    readonly property bool isCurrentActive: root.selectedIndex === index

                    color: rowHover.hovered || isSelected
                        ? Colours.tPalette.m3primaryContainer
                        : Colours.tPalette.m3surfaceContainerHigh
                    Behavior on color { ColorAnimation { duration: 120 } }
                    HoverHandler { id: rowHover }

                    Item {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 14

                        // 1. Circular Avatar (Masked with MultiEffect)
                        Item {
                            id: avatarContainer
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: 36
                            implicitHeight: 36

                            Rectangle {
                                id: avatarCircleMask
                                anchors.fill: parent
                                radius: width / 2
                                visible: false
                                layer.enabled: true
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: userRow.isSelected
                                    ? Colours.palette.m3primary
                                    : Colours.palette.m3surfaceContainerLowest

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    visible: uImg.status !== Image.Ready
                                    text: "person"
                                    fontStyle.pointSize: 18
                                    color: userRow.isSelected
                                        ? Colours.palette.m3onPrimary
                                        : Colours.palette.m3onSurfaceVariant
                                }
                            }

                            Image {
                                id: uImg
                                anchors.fill: parent
                                source: userRow.modelData?.avatar || ""
                                fillMode: Image.PreserveAspectCrop
                                visible: status === Image.Ready

                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    maskEnabled: true
                                    maskSource: avatarCircleMask
                                    maskSpreadAtMin: 1
                                    maskThresholdMin: 0.5
                                }
                            }
                        }

                        // 2. Left-Aligned Text Column (Display Name + @username)
                        ColumnLayout {
                            anchors.left: avatarContainer.right
                            anchors.leftMargin: 12
                            anchors.right: checkIcon.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: userRow.modelData?.realName || userRow.modelData?.username || "User"
                                font.family: "Google Sans Flex"
                                font.pointSize: 11
                                font.weight: userRow.isSelected ? Font.Bold : Font.Medium
                                color: Colours.palette.m3onSurface
                                horizontalAlignment: Text.AlignLeft
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "@" + (userRow.modelData?.username || "unknown")
                                font.family: "Google Sans Flex"
                                font.pointSize: 9
                                color: Colours.palette.m3outline
                                horizontalAlignment: Text.AlignLeft
                                elide: Text.ElideRight
                            }
                        }

                        // 3. Far-Right Plain Checkmark (NO circle around it)
                        MaterialIcon {
                            id: checkIcon
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            visible: userRow.isSelected
                            text: "check"
                            fontStyle.pointSize: 18
                            color: Colours.palette.m3primary
                        }
                    }

                    StateLayer {
                        onClicked: {
                            root.tempSelectedIndex = userRow.index;
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Qt.alpha(Colours.palette.m3outlineVariant, 0.30)
            }

            // ── Bottom Action Row (Cancel & Switch) ──────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }

                // Cancel Button
                Rectangle {
                    implicitWidth: 80
                    implicitHeight: 34
                    radius: 17
                    color: cancelState.containsMouse
                        ? Qt.alpha(Colours.palette.m3onSurface, 0.12)
                        : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    StateLayer {
                        id: cancelState
                        onClicked: root.isOpen = false
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.family: "Google Sans Flex"
                        font.pointSize: 10
                        font.weight: Font.Medium
                        color: Colours.palette.m3primary
                    }
                }

                // Switch Button
                Rectangle {
                    implicitWidth: 86
                    implicitHeight: 34
                    radius: 17
                    color: switchState.containsMouse
                        ? Qt.darker(Colours.palette.m3primary, 1.1)
                        : Colours.palette.m3primary
                    Behavior on color { ColorAnimation { duration: 120 } }

                    StateLayer {
                        id: switchState
                        color: Colours.palette.m3onPrimary
                        onClicked: {
                            root.selectedIndex = root.tempSelectedIndex;
                            root.userSelected(root.selectedIndex);
                            root.isOpen = false;
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Switch"
                        font.family: "Google Sans Flex"
                        font.pointSize: 10
                        font.weight: Font.DemiBold
                        color: Colours.palette.m3onPrimary
                    }
                }
            }
        }
    }
}
