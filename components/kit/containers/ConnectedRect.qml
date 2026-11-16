import QtQuick
import "../"
import Astra.Airlock
import "../../../services"
StyledRect {
    id: root

    property bool first: false
    property bool last: false
    property bool horizontal: false

    color: Colours.tPalette.m3surfaceContainer
    topLeftRadius: (horizontal ? first : first) ? Tokens.rounding.large : Tokens.rounding.extraSmall
    topRightRadius: (horizontal ? last : first) ? Tokens.rounding.large : Tokens.rounding.extraSmall
    bottomLeftRadius: (horizontal ? first : last) ? Tokens.rounding.large : Tokens.rounding.extraSmall
    bottomRightRadius: (horizontal ? last : last) ? Tokens.rounding.large : Tokens.rounding.extraSmall
}
