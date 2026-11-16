import QtQuick
import QtQuick.Layouts
import Astra.Airlock
import "../../services"
// A TTY section header: a rule with its title set into it, `── title ────`.
RowLayout {
    id: root

    property string title

    spacing: 8

    Rectangle {
        Layout.preferredWidth: 10
        Layout.preferredHeight: 1
        color: Colours.palette.m3outlineVariant
    }

    StyledText {
        text: root.title
        color: Colours.palette.m3primary
        font: Tokens.font.body.medium
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Colours.palette.m3outlineVariant
    }
}
