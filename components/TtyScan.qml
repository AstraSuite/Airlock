pragma ComponentBehavior: Bound

import QtQuick
import "../services"

// TTY's entrance, as KiiteShell's `scan` draws it: what's inside is painted
// in a line at a time from the top, as a CRT's beam draws a frame, with a
// bright beam at the edge and scanlines over what's drawn until it's all
// there. Hiding runs it backwards. It stands in for the fade the Material 3
// look comes in with; outside TTY (`active` false) it draws its content as
// is and leaves the motion to whatever holds it.
Item {
    id: root

    default property alias data: holder.data
    readonly property alias contentItem: holder

    property bool active: Colours.tty
    property bool shown: true
    // How far a TtyBox's title rises above the top edge, so it's drawn too
    property real rise: 0
    // How long to wait before scanning in, so what this replaces can scan
    // out first rather than both drawing over each other
    property int showDelay: 0

    // 0..1 of the way down
    property real t: 0

    // The beam moves down a whole line of TTY text at a time
    readonly property real lineHeight: 20
    // A dark scanline every so many pixels while it draws in
    readonly property real scanline: 3
    readonly property real duration: 300

    readonly property real fullHeight: height + rise
    readonly property bool scanning: active && t > 0 && t < 1
    // The first line is drawn at once
    readonly property real edge: {
        if (!active || t >= 1)
            return fullHeight;
        if (t <= 0)
            return 0;
        const lines = Math.max(1, Math.ceil(fullHeight / lineHeight));
        return Math.min(fullHeight, Math.min(lines, Math.floor(t * lines) + 1) * lineHeight);
    }

    visible: !active || t > 0

    function _run() {
        const to = shown ? 1 : 0;
        scanSeq.stop();
        if (!active) {
            t = to;
            return;
        }
        scanPause.duration = to === 1 && t === 0 ? showDelay : 0;
        scanAnim.from = t;
        scanAnim.to = to;
        scanAnim.duration = duration * Math.abs(to - t);
        scanSeq.start();
    }

    onShownChanged: _run()
    onActiveChanged: _run()
    Component.onCompleted: _run()

    SequentialAnimation {
        id: scanSeq

        PauseAnimation {
            id: scanPause
        }
        NumberAnimation {
            id: scanAnim
            target: root
            property: "t"
        }
    }

    Item {
        id: clipper
        y: -root.rise
        width: root.width
        height: root.edge
        clip: root.scanning

        Item {
            id: holder
            y: root.rise
            width: root.width
            height: root.height
        }

        Repeater {
            model: root.scanning ? Math.ceil(root.edge / root.scanline) : 0

            delegate: Rectangle {
                required property int index
                y: index * root.scanline
                width: root.width
                height: 1
                color: Qt.alpha(Colours.palette.m3background, 0.35)
            }
        }
    }

    // The beam
    Rectangle {
        visible: root.scanning && root.edge < root.fullHeight
        y: -root.rise + root.edge - 6
        width: root.width
        height: 6
        color: Qt.alpha(Colours.palette.m3primary, 0.18)
    }
    Rectangle {
        visible: root.scanning && root.edge < root.fullHeight
        y: -root.rise + root.edge - 2
        width: root.width
        height: 2
        color: Colours.palette.m3primary
    }
}
