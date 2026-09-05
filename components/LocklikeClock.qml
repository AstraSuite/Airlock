pragma ComponentBehavior: Bound

import QtQuick
import "../services"

// Lockscreen Clock matching Caelestia modules/lock/center/Clock.qml:
// In 12-hour mode: Large hours on left, stacked minutes and AM/PM pill on right.
// In 24-hour mode: Large hours and minutes side-by-side.
// Uses TextMetrics tightBoundingRect alignment with zero ascender drift and Google Sans Flex wdth: 30.
Item {
    id: root

    property real centerScale: 0.75

    readonly property int hoursPtSize: Math.round(32 * 7 * root.centerScale)
    readonly property int minutesPtSize: Math.round(32 * (Colours.use12Hour ? 3.8 : 7) * root.centerScale)
    readonly property int amPmPtSize: Math.round(24 * 2 * root.centerScale)

    property string _hours: "00"
    property string _minutes: "00"
    property string _ampm: ""

    function _updateTime() {
        const d = new Date();
        const hr = d.getHours();
        const min = d.getMinutes();

        if (Colours.use12Hour) {
            const h12 = hr % 12 || 12;
            _hours = h12 < 10 ? "0" + h12 : String(h12);
            _ampm = hr >= 12 ? "PM" : "AM";
        } else {
            _hours = hr < 10 ? "0" + hr : String(hr);
            _ampm = "";
        }

        _minutes = min < 10 ? "0" + min : String(min);
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._updateTime()
    }

    Connections {
        target: Colours
        function onUse12HourChanged() { root._updateTime(); }
    }

    function calcTopOff(metrics: TextMetrics): real {
        return metrics ? (metrics.tightBoundingRect.y - metrics.boundingRect.y) : 0;
    }

    implicitWidth: hours.implicitWidth + minutes.implicitWidth + 8
    implicitHeight: Math.max(1, hourMetrics.tightBoundingRect.height)

    Text {
        id: hours

        renderType: Text.NativeRendering
        textFormat: Text.PlainText
        y: -root.calcTopOff(hourMetrics)
        text: root._hours
        color: Colours.palette.m3primary
        font.family: "Google Sans Flex"
        font.pointSize: root.hoursPtSize
        font.weight: Font.Medium
        font.variableAxes: ({ "wdth": 30, "opsz": Math.min(144, root.hoursPtSize), "wght": 500 })

        TextMetrics {
            id: hourMetrics
            text: hours.text
            font: hours.font
        }
    }

    Text {
        id: minutes

        renderType: Text.NativeRendering
        textFormat: Text.PlainText
        anchors.right: parent.right
        y: -root.calcTopOff(minuteMetrics)
        text: root._minutes
        color: Colours.palette.m3secondary
        font.family: "Google Sans Flex"
        font.pointSize: root.minutesPtSize
        font.weight: Font.Medium
        font.variableAxes: ({ "wdth": 30, "opsz": Math.min(144, root.minutesPtSize), "wght": 500 })

        TextMetrics {
            id: minuteMetrics
            text: minutes.text
            font: minutes.font
        }
    }

    Loader {
        anchors.left: minutes.left
        anchors.leftMargin: minuteMetrics.tightBoundingRect.x
        y: Math.max(0, hourMetrics.tightBoundingRect.height - implicitHeight)

        active: Colours.use12Hour
        visible: active

        sourceComponent: Rectangle {
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: 14

            implicitWidth: Math.max(32, minuteMetrics.tightBoundingRect.width)
            implicitHeight: amPmMetrics.tightBoundingRect.height + 16

            Text {
                id: amPm

                renderType: Text.NativeRendering
                textFormat: Text.PlainText
                anchors.centerIn: parent
                width: amPmMetrics.tightBoundingRect.width
                height: amPmMetrics.tightBoundingRect.height
                transform: Translate {
                    x: -amPmMetrics.tightBoundingRect.x
                    y: -root.calcTopOff(amPmMetrics)
                }

                text: root._ampm
                color: Colours.palette.m3onSurface
                font.family: "Google Sans Flex"
                font.pointSize: root.amPmPtSize
                font.weight: Font.Medium
                font.variableAxes: ({ "wdth": 30, "opsz": Math.min(144, root.amPmPtSize), "wght": 500 })

                TextMetrics {
                    id: amPmMetrics
                    text: amPm.text
                    font: amPm.font
                }
            }
        }
    }
}
