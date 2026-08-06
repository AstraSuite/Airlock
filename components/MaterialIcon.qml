pragma ComponentBehavior: Bound

import QtQuick
import "../services"

StyledText {
    id: root

    property real fill: 0
    property int weight: Font.Normal
    property real grade: Colours.light ? 0 : -25
    property font fontStyle
    property real iconSize: (fontStyle && fontStyle.pointSize > 0) ? fontStyle.pointSize : 14

    color: Colours.palette.m3onSurface

    font.family: "Material Symbols Rounded"
    font.pointSize: root.iconSize
    font.variableAxes: ({
        "FILL": root.fill,
        "wght": root.weight <= 0 ? 400 : root.weight,
        "GRAD": root.grade,
        "opsz": root.iconSize
    })
}
