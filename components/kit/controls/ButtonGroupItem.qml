import QtQuick
import QtQuick.Layouts
import "../"
import Astra.Airlock
import "../../../services"
StyledRect {
    id: root

    property string icon: ""
    property string checkedIcon: "check"
    property bool showCheckmark: true
    property string text: ""
    property bool checked: false
    property bool disabled: false
    property bool first: false
    property bool last: false
    property bool horizontal: true
    property int buttonHeight: 40

    property color activeColor: (parent && "activeColor" in parent && parent.activeColor !== undefined)
        ? parent.activeColor
        : Colours.palette.m3primaryContainer
    property color inactiveColor: (parent && "inactiveColor" in parent && parent.inactiveColor !== undefined)
        ? parent.inactiveColor
        : Colours.tPalette.m3surfaceContainerHigh
    property color hoverColor: (parent && "hoverColor" in parent && parent.hoverColor !== undefined)
        ? parent.hoverColor
        : Colours.tPalette.m3surfaceContainerHighest
    property color activeOnColor: (parent && "activeOnColor" in parent && parent.activeOnColor !== undefined)
        ? parent.activeOnColor
        : Colours.palette.m3onPrimaryContainer
    property color inactiveOnColor: (parent && "inactiveOnColor" in parent && parent.inactiveOnColor !== undefined)
        ? parent.inactiveOnColor
        : Colours.palette.m3onSurface
    property color activeIconColor: activeOnColor
    property color inactiveIconColor: Colours.palette.m3onSurfaceVariant

    readonly property string activeIcon: (root.checked && root.showCheckmark)
        ? (root.checkedIcon.length > 0 ? root.checkedIcon : "check")
        : root.icon

    signal clicked()

    Layout.fillWidth: true
    Layout.preferredHeight: buttonHeight
    implicitHeight: buttonHeight
    implicitWidth: contentRow.implicitWidth + Tokens.padding.large * 2

    Behavior on implicitWidth {
        Anim {
            duration: Tokens.anim.durations.expressiveFastSpatial
            easing: Tokens.anim.expressiveFastSpatial
        }
    }

    Behavior on width {
        Anim {
            duration: Tokens.anim.durations.expressiveFastSpatial
            easing: Tokens.anim.expressiveFastSpatial
        }
    }

    topLeftRadius: (root.checked || (root.horizontal ? root.first : root.first)) ? Tokens.rounding.large : Tokens.rounding.extraSmall
    topRightRadius: (root.checked || (root.horizontal ? root.last : root.first)) ? Tokens.rounding.large : Tokens.rounding.extraSmall
    bottomLeftRadius: (root.checked || (root.horizontal ? root.first : root.last)) ? Tokens.rounding.large : Tokens.rounding.extraSmall
    bottomRightRadius: (root.checked || (root.horizontal ? root.last : root.last)) ? Tokens.rounding.large : Tokens.rounding.extraSmall

    Behavior on topLeftRadius {
        Anim {
            duration: Tokens.anim.durations.expressiveFastEffects
            easing: Tokens.anim.expressiveFastEffects
        }
    }
    Behavior on topRightRadius {
        Anim {
            duration: Tokens.anim.durations.expressiveFastEffects
            easing: Tokens.anim.expressiveFastEffects
        }
    }
    Behavior on bottomLeftRadius {
        Anim {
            duration: Tokens.anim.durations.expressiveFastEffects
            easing: Tokens.anim.expressiveFastEffects
        }
    }
    Behavior on bottomRightRadius {
        Anim {
            duration: Tokens.anim.durations.expressiveFastEffects
            easing: Tokens.anim.expressiveFastEffects
        }
    }

    color: root.checked
        ? root.activeColor
        : (stateLayer.containsMouse ? root.hoverColor : root.inactiveColor)

    Behavior on color {
        CAnim {
            duration: Tokens.anim.durations.expressiveFastEffects
            easing: Tokens.anim.expressiveFastEffects
        }
    }

    StateLayer {
        id: stateLayer
        anchors.fill: parent
        topLeftRadius: parent.topLeftRadius
        topRightRadius: parent.topRightRadius
        bottomLeftRadius: parent.bottomLeftRadius
        bottomRightRadius: parent.bottomRightRadius
        color: root.checked ? root.activeOnColor : root.inactiveOnColor
        disabled: root.disabled
        onClicked: root.clicked()
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        MaterialIcon {
            id: iconItem
            visible: root.activeIcon.length > 0
            text: root.activeIcon
            fontStyle: Tokens.font.icon.small
            color: root.checked ? root.activeIconColor : root.inactiveIconColor

            Behavior on color {
                CAnim {
                    duration: Tokens.anim.durations.expressiveFastEffects
                    easing: Tokens.anim.expressiveFastEffects
                }
            }
        }

        StyledText {
            visible: root.text.length > 0
            text: root.text
            font: Tokens.font.body.small
            color: root.checked ? root.activeOnColor : root.inactiveOnColor
            elide: Text.ElideRight

            Behavior on color {
                CAnim {
                    duration: Tokens.anim.durations.expressiveFastEffects
                    easing: Tokens.anim.expressiveFastEffects
                }
            }
        }
    }
}
