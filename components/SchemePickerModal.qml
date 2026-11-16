pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Astra.Airlock
import "../services"
import "kit" as Kit

// Scheme picker popup (bottom-right): dual-tone swatches, flavour over scheme
// name, a check on the current one, and a search bar. Under Material 3 it
// morphs out of its trigger as a liquid blob; under TTY it is a square
// bordered card, as KiiteShell's popups are.
Item {
    id: root

    property bool isOpen: false
    signal unfocusRequested()

    implicitWidth: 44
    implicitHeight: 44

    property real animDriver: 0
    property string searchText: ""
    readonly property string currentSchemeName: Colours.schemeName
    readonly property string currentFlavour: Colours.flavour

    // Raw list of schemes from SchemeDiscovery C++ plugin
    property var allSchemes: JSON.parse(SchemeDiscovery.schemesJson)

    // Filtered schemes based on search text
    readonly property var filteredSchemes: {
        const query = searchText.trim().toLowerCase();
        const list = allSchemes || [];
        if (query.length === 0) return list;
        return list.filter(s =>
            (s.name && s.name.toLowerCase().includes(query)) ||
            (s.flavour && s.flavour.toLowerCase().includes(query)) ||
            (s.displayName && s.displayName.toLowerCase().includes(query))
        );
    }

    function reloadSchemes() {
        SchemeDiscovery.reload();
    }

    onIsOpenChanged: {
        if (!isOpen) {
            searchInput.focus = false;
            searchInput.text = "";
            root.searchText = "";
            previewTimer.stop();
            previewTimer.targetName = "";
            previewTimer.targetFlavour = "";
            Colours.stopPreview();
            root.unfocusRequested();
        }
    }

    Component.onDestruction: {
        Colours.stopPreview();
    }

    Timer {
        id: previewTimer
        interval: 40
        property string targetName: ""
        property string targetFlavour: ""
        onTriggered: {
            if (targetName.length > 0 && targetFlavour.length > 0 && root.isOpen) {
                Colours.previewScheme(targetName, targetFlavour);
            } else {
                Colours.stopPreview();
            }
        }
    }

    BlobGroup {
        id: blobGroup
        color: Colours.tPalette.m3surfaceContainer
        smoothing: 24
        cornerFill: false
    }

    // ── Popup Modal Rect (Clean floating card elevated above the button) ───
    BlobRect {
        id: popupRect

        visible: !Colours.tty
        anchors.right: parent.right
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
                popupRect.anchors.rightMargin: 0
                popupRect.implicitWidth: 310
                popupRect.implicitHeight: 430
            }
        }

        transitions: Transition {
            NumberAnimation {
                properties: "bottomMargin,rightMargin,implicitWidth,implicitHeight"
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
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 64
        width: 310
        height: 430

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

        HoverHandler {
            id: modalHover
            onHoveredChanged: {
                if (!hovered) {
                    previewTimer.stop();
                    previewTimer.targetName = "";
                    previewTimer.targetFlavour = "";
                    Colours.stopPreview();
                }
            }
        }

        // Click catcher inside modal so clicking inside doesn't dismiss
        MouseArea {
            anchors.fill: parent
            enabled: root.isOpen
            onClicked: {}
        }

        Item {
            anchors.fill: parent
            anchors.margins: 14
            clip: true
            opacity: Colours.tty ? 1 : root.animDriver
            visible: Colours.tty || opacity > 0

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

                    HoverHandler {
                        id: listHover
                        onHoveredChanged: {
                            if (!hovered) {
                                previewTimer.stop();
                                previewTimer.targetName = "";
                                previewTimer.targetFlavour = "";
                                Colours.stopPreview();
                            }
                        }
                    }

                    delegate: Rectangle {
                        id: schemeRow
                        required property int index
                        required property var modelData

                        readonly property bool isActive:
                            root.currentSchemeName === modelData.name &&
                            root.currentFlavour === modelData.flavour

                        width: schemeListView.width
                        implicitHeight: 46
                        radius: Tokens.rounding.medium
                        color: schemeRow.isActive ? Colours.tPalette.m3surfaceContainerHighest : "transparent"

                        Behavior on color { ColorAnimation { duration: 150 } }



                        StateLayer {
                            id: rowStateLayer
                            onEntered: {
                                previewTimer.targetName = schemeRow.modelData.name;
                                previewTimer.targetFlavour = schemeRow.modelData.flavour;
                                previewTimer.restart();
                            }
                            onClicked: {
                                previewTimer.stop();
                                previewTimer.targetName = "";
                                previewTimer.targetFlavour = "";
                                Colours.setScheme(schemeRow.modelData.name, schemeRow.modelData.flavour, Colours.light ? "light" : "dark");
                                searchInput.focus = false;
                                root.unfocusRequested();
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

                            function safeHex(val, fallback) {
                                if (!val) return fallback;
                                const s = String(val).trim();
                                if (!s) return fallback;
                                return s.startsWith("#") ? s : ("#" + s);
                            }

                            Rectangle {
                                id: swatchBase
                                anchors.fill: parent
                                radius: Colours.tty ? 0 : width / 2
                                color: swatchContainer.safeHex(schemeRow.modelData.colours?.surface, Colours.palette.m3surface)
                                border.width: 1
                                border.color: Qt.alpha(Colours.palette.m3outline, 0.25)

                                Item {
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.right: parent.right
                                    width: parent.width / 2
                                    clip: true

                                    Rectangle {
                                        width: swatchContainer.width
                                        height: swatchContainer.height
                                        radius: Colours.tty ? 0 : width / 2
                                        anchors.right: parent.right
                                        color: swatchContainer.safeHex(schemeRow.modelData.colours?.primary, Colours.palette.m3primary)
                                    }
                                }
                            }
                        }

                        // ── Active Checkmark on Far Right ───────────
                        Kit.MaterialIcon {
                            id: checkIcon
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            visible: schemeRow.isActive
                            text: "check"
                            fontStyle: Tokens.font.icon.medium
                            color: Colours.palette.m3primary
                        }

                        // ── Consistently Left-Aligned Typography ────
                        Column {
                            anchors.left: swatchContainer.right
                            anchors.leftMargin: 12
                            anchors.right: checkIcon.visible ? checkIcon.left : parent.right
                            anchors.rightMargin: checkIcon.visible ? 8 : 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Kit.StyledText {
                                width: parent.width
                                text: {
                                    const d = schemeRow.modelData;
                                    if (d.name === "dynamic" || d.name === "kiite")
                                        return d.displayName || d.name;
                                    return d.flavour ? d.flavour.charAt(0).toUpperCase() + d.flavour.slice(1) : "";
                                }
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurface
                                elide: Text.ElideRight
                            }

                            Kit.StyledText {
                                width: parent.width
                                text: {
                                    const n = schemeRow.modelData.name;
                                    if (n === "dynamic")
                                        return "Synced scheme";
                                    if (n === "kiite")
                                        return "KiiteShell's palette";
                                    return n || "";
                                }
                                font: Tokens.font.label.small
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
                    radius: Tokens.rounding.full
                    color: Colours.tPalette.m3surfaceContainerHighest
                    border.width: Colours.tty ? 1 : 0
                    border.color: Colours.palette.m3outlineVariant
                    Behavior on color { CAnim {} }

                    StateLayer {
                        id: searchStateLayer
                        radius: searchBar.radius
                        showHoverBackground: false
                        cursorShape: Qt.IBeamCursor
                        onPressed: e => searchInput.forceActiveFocus()
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        spacing: 8

                        Kit.MaterialIcon {
                            text: "search"
                            fontStyle: Tokens.font.icon.medium
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            font: Tokens.font.body.medium
                            color: Colours.palette.m3onSurface
                            text: root.searchText
                            onTextChanged: root.searchText = text
                            clip: true
                            selectByMouse: true

                            TapHandler {
                                onTapped: point => {
                                    searchStateLayer.press(point.position.x + searchInput.x, point.position.y + searchInput.y);
                                }
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    if (root.searchText.length > 0) {
                                        root.searchText = "";
                                        searchInput.text = "";
                                    } else {
                                        root.isOpen = false;
                                        searchInput.focus = false;
                                        root.unfocusRequested();
                                    }
                                    event.accepted = true;
                                    return;
                                }

                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (root.filteredSchemes.length > 0) {
                                        const s = root.filteredSchemes[0];
                                        Colours.setScheme(s.name, s.flavour, Colours.light ? "light" : "dark");
                                        root.isOpen = false;
                                        searchInput.focus = false;
                                        root.unfocusRequested();
                                    }
                                    event.accepted = true;
                                    return;
                                }
                            }

                            Text {
                                text: "Search schemes..."
                                visible: !searchInput.text && !searchInput.activeFocus
                                font: Tokens.font.body.medium
                                color: Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.50)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Kit.MaterialIcon {
                            visible: root.searchText.length > 0
                            text: "close"
                            fontStyle: Tokens.font.icon.small
                            color: Colours.palette.m3onSurfaceVariant
                            TapHandler {
                                onTapped: {
                                    root.searchText = "";
                                    searchInput.text = "";
                                    searchInput.focus = false;
                                    root.unfocusRequested();
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

        visible: !Colours.tty
        anchors.fill: parent
        group: blobGroup
        radius: root.isOpen ? 22 : 16

        Behavior on radius { NumberAnimation { duration: 150 } }
    }

    Kit.MaterialIcon {
        anchors.centerIn: parent
        text: root.isOpen ? "close" : "palette"
        fontStyle: Tokens.font.icon.large
        color: root.isOpen ? Colours.palette.m3primary : Colours.palette.m3onSurface
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
