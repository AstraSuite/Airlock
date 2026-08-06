pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../services"

// Clock matching the caelestia lockscreen design:
//   hours (primary colour, large)  minutes (secondary colour, smaller)
// laid out side-by-side, with AM/PM chip below minutes in 12h mode.
// Uses Google Sans Flex variable font with width axis set to 30 (condensed).
Item {
    id: root

    implicitWidth: hours.implicitWidth + minutes.implicitWidth + 4
    implicitHeight: hours.implicitHeight

    readonly property string _font: "Google Sans Flex"
    readonly property real   _size: 86      // base point size for hours
    readonly property real   _wdth: 30      // font-variation width axis (condensed)

    // Clock data
    property int    _hr:  0
    property int    _min: 0
    property string _ap:  "AM"
    property string _date: ""

    function _refresh() {
        const now = new Date();
        _min = now.getMinutes();
        if (GreeterState.use12h) {
            const h = now.getHours();
            _hr = h % 12 || 12;
            _ap = h >= 12 ? "PM" : "AM";
        } else {
            _hr  = now.getHours();
            _ap  = "";
        }
        _date = Qt.formatDate(now, "dddd • d MMM").toUpperCase();
    }

    Timer { interval: 1000; running: true; repeat: true; onTriggered: root._refresh() }
    Component.onCompleted: root._refresh()
    onVisibleChanged: if (visible) root._refresh()
    Connections {
        target: GreeterState
        function onUse12hChanged() { root._refresh() }
    }

    // Hours — primary colour, full size
    Text {
        id: hours
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root._hr < 10 ? "0" + root._hr : "" + root._hr
        color: Colours.palette.m3primary
        font.family: root._font
        font.pointSize: root._size
        font.weight: Font.Normal
        font.variableAxes: { "wdth": root._wdth }
    }

    // Minutes + AM/PM column — secondary colour, slightly smaller
    Column {
        id: minutesCol
        anchors.left: hours.right
        anchors.leftMargin: 4
        anchors.bottom: hours.bottom

        Text {
            id: minutes
            text: root._min < 10 ? "0" + root._min : "" + root._min
            color: Colours.palette.m3secondary
            font.family: root._font
            font.pointSize: GreeterState.use12h ? root._size * 0.54 : root._size
            font.weight: Font.Normal
            font.variableAxes: { "wdth": root._wdth }
        }

        // AM/PM chip — only shown in 12h mode
        Rectangle {
            visible: GreeterState.use12h
            width: minutes.width
            height: amPmText.implicitHeight + 10
            radius: 8
            color: Qt.alpha(Colours.palette.m3surfaceContainerHigh, 0.85)

            Text {
                id: amPmText
                anchors.centerIn: parent
                text: root._ap
                color: Colours.palette.m3onSurface
                font.family: root._font
                font.pointSize: root._size * 0.22
                font.weight: Font.Medium
                font.variableAxes: { "wdth": root._wdth }
            }
        }
    }
}
