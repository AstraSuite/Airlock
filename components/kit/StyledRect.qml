import QtQuick
import Astra.Airlock
import "../../services"
Rectangle {
    id: root

    // Cards that float (dialogs, menus) are drawn as boxes in TTY, where
    // every surface shares one ground and borders, not tones, divide them.
    property bool ttyFrame: false

    color: "transparent"
    border.width: ttyFrame && Colours.tty ? 1 : 0
    border.color: Colours.palette.m3outlineVariant

    Behavior on color {
        CAnim {}
    }
}
