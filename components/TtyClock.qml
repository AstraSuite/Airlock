pragma ComponentBehavior: Bound

import QtQuick
import Astra.Airlock
import "../services"
import "kit" as Kit

// The TTY look's clock: the time over a spaced-out date line, in the mono
// face. Large and centred for the idle screen (with the host name, as a
// console login banner has it), small and right-aligned beside the login.
Column {
    id: root

    property bool large: true

    property date now: new Date()

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    spacing: large ? 18 : 2

    Kit.StyledText {
        anchors.horizontalCenter: root.large ? parent.horizontalCenter : undefined
        anchors.right: root.large ? undefined : parent.right
        text: Qt.formatTime(root.now, Colours.use12Hour ? "h:mm AP" : "hh:mm")
        color: Colours.palette.m3inverseOnSurface
        font.family: Tokens.font.body.medium.family
        font.pixelSize: root.large ? 108 : 26
        font.weight: Font.DemiBold
        font.letterSpacing: root.large ? -2 : -1
    }

    Kit.StyledText {
        anchors.horizontalCenter: root.large ? parent.horizontalCenter : undefined
        anchors.right: root.large ? undefined : parent.right
        text: {
            const parts = [Qt.formatDate(root.now, "ddd"), Qt.formatDate(root.now, "MMM dd")];
            if (root.large && SystemInfo.hostName.length > 0)
                parts.push(SystemInfo.hostName);
            return parts.join(" · ").toUpperCase();
        }
        color: root.large ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3outline
        font.family: Tokens.font.body.medium.family
        font.pixelSize: root.large ? 16 : 12
        font.weight: Font.Medium
        font.letterSpacing: root.large ? 3 : 2
    }
}
