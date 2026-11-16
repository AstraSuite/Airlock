import QtQuick
import Astra.Airlock
import "../../services"
// A bar drawn in text, `████████▌░░░░`: `cells` wide, filled to `fraction` in
// half cells. The filled part is one solid run, since █ glyphs side by side
// leave hairline seams.
Row {
    id: root

    property real fraction: 0
    property int cells: 12

    readonly property int halves: Math.round(Math.max(0, Math.min(1, fraction)) * cells * 2)
    readonly property real cellWidth: cellMetrics.advanceWidth

    TextMetrics {
        id: cellMetrics
        font: Tokens.font.body.medium
        text: "░"
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: root.halves / 2 * root.cellWidth
        height: cellMetrics.height
        color: Colours.palette.m3primary
    }

    StyledText {
        text: "░".repeat(root.cells - Math.ceil(root.halves / 2))
        color: Colours.palette.m3outlineVariant
        font: Tokens.font.body.medium
    }
}
