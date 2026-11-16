import QtQuick
import Astra.Airlock
import "../../services"
// A Material Symbols glyph by name. Under TTY it is drawn from a Nerd Font
// instead, as KiiteShell draws its symbols, keeping the Material glyph's box
// so layouts don't shift; a symbol the Nerd table lacks stays Material.
Item {
    id: root

    property string text
    property color color: Colours.palette.m3onSurface
    property bool animate: false
    property real fill: 0
    property int grade: Colours.light ? 0 : -25
    property font fontStyle: Tokens.font.icon.small
    property int pointSize: 0

    readonly property string nerdGlyph: Colours.tty ? Colours.nerdGlyph(text) : ""

    implicitWidth: material.implicitWidth
    implicitHeight: material.implicitHeight

    StyledText {
        id: material

        anchors.centerIn: parent
        visible: root.nerdGlyph.length === 0
        animate: root.animate
        text: root.text
        color: root.color
        font: Tokens.font.icon.size(root.pointSize > 0 ? root.pointSize : root.fontStyle.pointSize).weight(root.fontStyle.weight).fill(root.fill.toFixed(1)).grade(root.grade).build()
    }

    StyledText {
        anchors.centerIn: parent
        visible: !material.visible
        text: root.nerdGlyph
        color: root.color
        font.family: Colours.nerdFamily
        font.pointSize: root.pointSize > 0 ? root.pointSize : root.fontStyle.pointSize
    }
}
