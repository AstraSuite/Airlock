import QtQuick
import Astra.Airlock
import "../../services"
// TTY's box: a square 1px border with its title set into the top edge, the
// edge breaking for it, as KiiteShell draws its panels. Lay it over a
// surface; it draws nothing outside TTY. The title rises half a line above
// the box, so leave that much room over it.
Item {
    id: root

    property string title
    // An open or focused box: a brighter edge and a blinking cursor
    property bool focused: false
    // The box holding what's being typed into, edged in the accent
    // (Airlock's login; not in Atlas)
    property bool accent: false

    visible: Colours.tty

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 1
        border.color: root.accent ? Colours.palette.m3primary : root.focused ? Qt.tint(Colours.palette.m3outlineVariant, Qt.alpha(Colours.palette.m3onSurface, 0.1)) : Colours.palette.m3outlineVariant
    }

    Rectangle {
        visible: root.title.length > 0
        x: 10
        y: -height / 2
        width: titleText.width + 16
        height: 20
        color: Colours.palette.m3surface

        // A long path keeps its end, the folder's own name
        TtyTitle {
            id: titleText
            anchors.centerIn: parent
            width: Math.min(implicitWidth, Math.max(0, root.width - 44))
            elide: Text.ElideLeft
            title: root.title
            cursor: root.focused
        }
    }
}
