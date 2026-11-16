import QtQuick
import QtQuick.Layouts
import Astra.Airlock
import "../../../services"
RowLayout {
    id: root

    property var model: []
    property var currentValue: undefined
    property string valueKey: "value"
    property string labelKey: "label"
    property string iconKey: "icon"
    property var isSelected: null // optional custom callback: (modelData, index) => bool
    property bool multiSelect: false
    property int buttonHeight: 40
    property bool showCheckmark: true
    property string checkedIcon: "check"

    property color activeColor: Colours.palette.m3primaryContainer
    property color inactiveColor: Colours.tPalette.m3surfaceContainerHigh
    property color hoverColor: Colours.tPalette.m3surfaceContainerHighest
    property color activeOnColor: Colours.palette.m3onPrimaryContainer
    property color inactiveOnColor: Colours.palette.m3onSurface
    property color activeIconColor: activeOnColor
    property color inactiveIconColor: Colours.palette.m3onSurfaceVariant

    signal selected(var value, int index)

    spacing: 2

    function updateChildPositions() {
        if (repeater.count > 0) return;
        let items = [];
        for (let i = 0; i < root.children.length; i++) {
            let child = root.children[i];
            if (child && child !== repeater && child.visible && ("first" in child) && ("last" in child)) {
                items.push(child);
            }
        }
        for (let i = 0; i < items.length; i++) {
            items[i].first = (i === 0);
            items[i].last = (i === items.length - 1);
        }
    }

    Component.onCompleted: updateChildPositions()
    onChildrenChanged: updateChildPositions()

    Repeater {
        id: repeater
        model: root.model

        delegate: ButtonGroupItem {
            id: itemDelegate
            required property int index
            required property var modelData

            first: index === 0
            last: index === repeater.count - 1
            buttonHeight: root.buttonHeight
            showCheckmark: root.showCheckmark
            checkedIcon: root.checkedIcon

            activeColor: root.activeColor
            inactiveColor: root.inactiveColor
            hoverColor: root.hoverColor
            activeOnColor: root.activeOnColor
            inactiveOnColor: root.inactiveOnColor
            activeIconColor: root.activeIconColor
            inactiveIconColor: root.inactiveIconColor

            checked: {
                if (root.isSelected) {
                    return root.isSelected(modelData, index);
                }
                const val = typeof modelData === "object" && modelData !== null && root.valueKey in modelData
                    ? modelData[root.valueKey]
                    : modelData;
                return root.currentValue === val;
            }

            icon: {
                if (typeof modelData === "object" && modelData !== null && root.iconKey in modelData) {
                    return modelData[root.iconKey] || "";
                }
                return "";
            }

            text: {
                if (typeof modelData === "object" && modelData !== null && root.labelKey in modelData) {
                    return modelData[root.labelKey] || "";
                }
                if (typeof modelData === "string") {
                    return modelData;
                }
                return "";
            }

            onClicked: {
                const val = typeof modelData === "object" && modelData !== null && root.valueKey in modelData
                    ? modelData[root.valueKey]
                    : modelData;
                root.selected(val, index);
            }
        }
    }
}
