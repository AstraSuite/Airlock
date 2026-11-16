pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Astra.Airlock
import "../../../services"
import "../"
import "../effects"

MouseArea {
    id: root

    required property Item attachTo
    property real marginX
    property real marginY

    property list<MenuItem> items
    property MenuItem active: items[0] ?? null
    property bool expanded

    signal itemSelected(item: MenuItem)

    parent: {
        const win = root.Window.window;
        return win ? win.contentItem : null;
    }
    anchors.fill: parent

    enabled: expanded
    hoverEnabled: expanded
    cursorShape: expanded ? Qt.ArrowCursor : undefined
    onClicked: expanded = false

    // Collapse when the attached item or any of its ancestors becomes hidden/invisible
    // (e.g. modal closed or page switched). Polled imperatively to avoid reactive cycles.
    function isAttachShown(): bool {
        let item = attachTo;
        let shown = item !== null;
        while (item && item !== root) {
            if (!item.visible || item.opacity < 0.01)
                shown = false;
            item = item.parent;
        }
        return shown;
    }

    Timer {
        interval: 200
        running: root.expanded
        repeat: true
        onTriggered: {
            if (!root.isAttachShown())
                root.expanded = false;
        }
    }

    readonly property Item scrollParent: {
        let item = attachTo;
        while (item) {
            if (item.contentY !== undefined && item.contentHeight !== undefined)
                return item;
            item = item.parent;
        }
        return null;
    }

    Connections {
        target: root.expanded ? root.scrollParent : null
        ignoreUnknownSignals: true

        function onContentYChanged(): void {
            root.expanded = false;
        }

        function onContentXChanged(): void {
            root.expanded = false;
        }
    }

    // mapToItem is not reactive so this forces updates when ancestor geometry changes (scrolling, moving)
    readonly property real transformSync: {
        let sync = 0;
        let item = attachTo;
        while (item && item !== root) {
            sync += item.x + item.y + item.width + item.height + item.scale + item.rotation;
            item = item.parent;
        }
        return sync;
    }

    opacity: expanded ? 1 : 0
    visible: opacity > 0.01
    layer.enabled: opacity < 1

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    Elevation {
        id: menu

        x: {
            root.transformSync; // force updates
            const item = root.attachTo;
            if (!item || !root.parent)
                return 0;
            return item.mapToItem(root.parent, item.width - width, 0).x + root.marginX;
        }
        y: {
            root.transformSync; // force updates
            const item = root.attachTo;
            if (!item || !root.parent)
                return 0;
            return item.mapToItem(root.parent, 0, item.height).y + root.marginY;
        }

        radius: Tokens.rounding.large
        // TTY draws no shadows
        level: Colours.tty ? 0 : 2

        implicitWidth: Math.max(200, column.implicitWidth + column.anchors.leftMargin * 2)
        implicitHeight: column.implicitHeight + column.anchors.topMargin + column.anchors.bottomMargin

        transform: Scale {
            yScale: root.expanded ? 1 : 0.1
            origin.y: 0

            Behavior on yScale {
                Anim {}
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onWheel: e => e.accepted = true
        }

        StyledRect {
            anchors.fill: parent
            radius: parent.radius
            color: Colours.palette.m3surfaceContainerLow
            ttyFrame: true

            ColumnLayout {
                id: column

                anchors.fill: parent
                anchors.margins: Colours.tty ? 0 : Tokens.padding.extraSmall
                anchors.topMargin: Colours.tty ? 6 : Tokens.padding.extraSmall
                anchors.bottomMargin: Colours.tty ? 6 : Tokens.padding.extraSmall
                spacing: 0

                Repeater {
                    id: repeater

                    model: root.items

                    StyledRect {
                        id: item

                        required property int index
                        required property MenuItem modelData
                        readonly property bool active: modelData === root?.active

                        Layout.fillWidth: true
                        implicitWidth: Colours.tty ? ttyRow.implicitWidth : menuOptionRow.implicitWidth + Tokens.padding.medium * 2
                        implicitHeight: Colours.tty ? ttyRow.implicitHeight : menuOptionRow.implicitHeight + Tokens.padding.medium * 2

                        radius: active ? Tokens.rounding.medium : Tokens.rounding.extraSmall
                        topLeftRadius: index === 0 ? Tokens.rounding.medium : radius
                        topRightRadius: index === 0 ? Tokens.rounding.medium : radius
                        bottomLeftRadius: index === repeater?.count - 1 ? Tokens.rounding.medium : radius
                        bottomRightRadius: index === repeater?.count - 1 ? Tokens.rounding.medium : radius

                        color: Qt.alpha(Colours.palette.m3tertiaryContainer, active && !Colours.tty ? 1 : 0)

                        Behavior on radius {
                            Anim {}
                        }

                        TtyMenuRow {
                            id: ttyRow
                            anchors.fill: parent
                            visible: Colours.tty
                            text: item.modelData?.text ?? ""
                            hovered: itemState.containsMouse
                            checkable: true
                            checked: item.active
                        }

                        StateLayer {
                            id: itemState
                            showHoverBackground: !Colours.tty
                            topLeftRadius: parent.topLeftRadius
                            topRightRadius: parent.topRightRadius
                            bottomLeftRadius: parent.bottomLeftRadius
                            bottomRightRadius: parent.bottomRightRadius

                            color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                            disabled: !root.expanded
                            onClicked: {
                                root.itemSelected(item.modelData);
                                root.active = item.modelData;
                                item.modelData.clicked();
                                root.expanded = false;
                            }
                        }

                        RowLayout {
                            id: menuOptionRow

                            visible: !Colours.tty
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                Layout.alignment: Qt.AlignVCenter
                                text: item.modelData?.icon ?? ""
                                color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.fillWidth: true
                                text: item.modelData?.text ?? ""
                                color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                            }

                            Loader {
                                asynchronous: true
                                Layout.alignment: Qt.AlignVCenter
                                active: item.modelData?.trailingIcon.length > 0
                                visible: active

                                sourceComponent: MaterialIcon {
                                    text: item.modelData.trailingIcon
                                    color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
