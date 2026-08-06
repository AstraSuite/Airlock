pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Caelestia.Blobs
import Caelestia.Greeter
import "../services"

// Morphing Scheme Picker Modal (Bottom-Right) matching Caelestia Launcher >scheme picker:
// Dual-tone split swatches, consistent left-aligned flavour & name typography, far-right checkmark, and bottom search bar
Item {
    id: root

    property bool isOpen: false

    implicitWidth: 44
    implicitHeight: 44

    property real animDriver: 0
    property string searchText: ""
    property string currentSchemeName: ""
    property string currentFlavour: ""

    // Raw list of schemes from `caelestia scheme list`
    property var allSchemes: []

    // Filtered schemes based on search text
    readonly property var filteredSchemes: {
        const query = searchText.trim().toLowerCase();
        if (query.length === 0) return allSchemes;
        return allSchemes.filter(s =>
            (s.name && s.name.toLowerCase().includes(query)) ||
            (s.flavour && s.flavour.toLowerCase().includes(query))
        );
    }

    function reloadSchemes() {
        listProc.running = true;
        currentProc.running = true;
    }

    Process {
        id: listProc
        running: true
        command: ["caelestia", "scheme", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    const list = [];
                    for (const [name, flavours] of Object.entries(data)) {
                        for (const [flavour, colours] of Object.entries(flavours)) {
                            list.push({
                                name: name,
                                flavour: flavour,
                                colours: colours
                            });
                        }
                    }
                    list.sort((a, b) => String(a.name + a.flavour).localeCompare(String(b.name + b.flavour)));
                    root.allSchemes = list;
                } catch (e) {
                    console.warn("Failed to parse scheme list:", e);
                }
            }
        }
    }

    Process {
        id: currentProc
        running: true
        command: ["caelestia", "scheme", "get", "-nfv"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("\n");
                if (parts.length >= 2) {
                    root.currentSchemeName = parts[0];
                    root.currentFlavour = parts[1];
                }
            }
        }
    }

    Process {
        id: applyProc
    }

    BlobGroup {
        id: blobGroup
        color: Qt.rgba(Colours.palette.m3surfaceContainer.r,
                       Colours.palette.m3surfaceContainer.g,
                       Colours.palette.m3surfaceContainer.b, 0.96)
        smoothing: 24
        cornerFill: false
    }

    // ── Popup Modal Rect (Clean floating card elevated above the button) ───
    BlobRect {
        id: popupRect

        anchors.right: parent.right
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
                popupRect.anchors.rightMargin: 0
                popupRect.implicitWidth: 310
                popupRect.implicitHeight: 430
                root.animDriver: 1
            }
        }

        transitions: Transition {
            NumberAnimation {
                properties: "bottomMargin,rightMargin,implicitWidth,implicitHeight"
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
                anchors.fill: parent
                spacing: 10

                // ── Schemes ListView with Smooth Boundary Fading ─────
                VerticalFadeListView {
                    id: schemeListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: root.filteredSchemes

                    delegate: Rectangle {
                        id: schemeRow
                        required property int index
                        required property var modelData

                        readonly property bool isActive:
                            root.currentSchemeName === modelData.name &&
                            root.currentFlavour === modelData.flavour

                        width: schemeListView.width
                        implicitHeight: 46
                        radius: 12
                        color: rowMouse.containsMouse
                            ? Qt.alpha(Colours.palette.m3primaryContainer, 0.40)
                            : (schemeRow.isActive ? Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.60) : "transparent")

                        Behavior on color { ColorAnimation { duration: 120 } }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.currentSchemeName = schemeRow.modelData.name;
                                root.currentFlavour = schemeRow.modelData.flavour;
                                Colours.setScheme(schemeRow.modelData.name, schemeRow.modelData.flavour);
                            }
                        }

                        // ── Dual-Tone Split Circular Color Swatch ───
                        Item {
                            id: swatchContainer
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: 26
                            implicitHeight: 26

                            Rectangle {
                                id: swatchBase
                                anchors.fill: parent
                                radius: width / 2
                                color: schemeRow.modelData.colours?.surface
                                    ? `#${schemeRow.modelData.colours.surface}`
                                    : Colours.palette.m3surface

                                Item {
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.right: parent.right
                                    width: parent.width / 2
                                    clip: true

                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        anchors.right: parent.right
                                        width: swatchBase.width
                                        radius: width / 2
                                        color: schemeRow.modelData.colours?.primary
                                            ? `#${schemeRow.modelData.colours.primary}`
                                            : Colours.palette.m3primary
                                    }
                                }
                            }
                        }

                        // ── Active Checkmark on Far Right ───────────
                        MaterialIcon {
                            id: currentCheck
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            visible: schemeRow.isActive
                            text: "check"
                            fontStyle.pointSize: 18
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        // ── Consistently Left-Aligned Typography ────
                        Column {
                            anchors.left: swatchContainer.right
                            anchors.leftMargin: 12
                            anchors.right: currentCheck.visible ? currentCheck.left : parent.right
                            anchors.rightMargin: currentCheck.visible ? 8 : 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                width: parent.width
                                text: schemeRow.modelData.flavour ?? ""
                                font.family: "Google Sans Flex"
                                font.pointSize: 11
                                font.weight: Font.Medium
                                color: Colours.palette.m3onSurface
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: schemeRow.modelData.name ?? ""
                                font.family: "Google Sans Flex"
                                font.pointSize: 9
                                color: Colours.palette.m3outline
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                // ── Clean Bottom Search Bar ──────────────────────────
                Rectangle {
                    id: searchBar
                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: 20
                    color: Qt.rgba(Colours.palette.m3surfaceContainerHighest.r,
                                   Colours.palette.m3surfaceContainerHighest.g,
                                   Colours.palette.m3surfaceContainerHighest.b, 0.75)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        spacing: 8

                        MaterialIcon {
                            text: "search"
                            fontStyle.pointSize: 16
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            font.family: "Google Sans Flex"
                            font.pointSize: 11
                            color: Colours.palette.m3onSurface
                            text: root.searchText
                            onTextChanged: root.searchText = text
                            clip: true

                            Text {
                                text: "Search schemes..."
                                visible: !searchInput.text && !searchInput.activeFocus
                                font.family: "Google Sans Flex"
                                font.pointSize: 11
                                color: Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.50)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MaterialIcon {
                            visible: root.searchText.length > 0
                            text: "close"
                            fontStyle.pointSize: 14
                            color: Colours.palette.m3onSurfaceVariant
                            TapHandler {
                                onTapped: {
                                    root.searchText = "";
                                    searchInput.text = "";
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Trigger Button Rect (Bottom-Right, connects with Popup) ──
    BlobRect {
        id: btnRect

        anchors.fill: parent
        group: blobGroup
        radius: root.isOpen ? 22 : 16

        Behavior on radius { NumberAnimation { duration: 150 } }

        MaterialIcon {
            anchors.centerIn: parent
            text: root.isOpen ? "close" : "palette"
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
                if (root.isOpen) {
                    root.reloadSchemes();
                }
            }
        }
    }
}
