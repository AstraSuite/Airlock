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

    property color activeColor: Colours.palette.m3primaryContainer
    property color inactiveColor: Colours.tPalette.m3surfaceContainerHigh
    property color hoverColor: Colours.tPalette.m3surfaceContainerHighest
    property color activeOnColor: Colours.palette.m3onPrimaryContainer
    property color inactiveOnColor: Colours.palette.m3onSurface
    property color activeIconColor: activeOnColor
    property color inactiveIconColor: Colours.palette.m3onSurfaceVariant

    readonly property string activeIcon: (root.checked && root.showCheckmark)
        ? (root.checkedIcon.length > 0 ? root.checkedIcon : "check")
        : root.icon

    signal clicked()

    Layout.fillWidth: true
    implicitHeight: buttonHeight

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
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.small
        anchors.rightMargin: Tokens.padding.small
        spacing: 6

        Item { Layout.fillWidth: true }

        MaterialIcon {
            visible: root.activeIcon.length > 0
            text: root.activeIcon
            fontStyle: Tokens.font.icon.small
            color: root.checked ? root.activeIconColor : root.inactiveIconColor
            Layout.alignment: Qt.AlignVCenter

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
            Layout.maximumWidth: root.width - (root.icon.length > 0 ? 36 : 16)
            Layout.alignment: Qt.AlignVCenter

            Behavior on color {
                CAnim {
                    duration: Tokens.anim.durations.expressiveFastEffects
                    easing: Tokens.anim.expressiveFastEffects
                }
            }
        }

        Item { Layout.fillWidth: true }
    }
}
