pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../services"

// Active view top-right clock matching Caelestia's DesktopClock background element:
// Google Sans Flex font, luminous M3 typography with high-contrast tonal plate
// for maximum visibility across all wallpapers and background themes.
Item {
    id: root

    implicitWidth: layout.implicitWidth + 32
    implicitHeight: layout.implicitHeight + 16

    // ── High-Contrast Frosted Tonal Surface ─────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 18
        color: Colours.tPalette.m3surfaceContainer
        Behavior on color { CAnim {} }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 14

        // ── Time block ───────────────────────────────────────────────
        RowLayout {
            spacing: 3

            Text {
                text: _hours
                font.family: "Google Sans Flex"
                font.pointSize: 30
                font.weight: Font.Bold
                font.variableAxes: { "wdth": 115 }
                color: Colours.palette.m3primary
            }

            Text {
                text: ":"
                font.family: "Google Sans Flex"
                font.pointSize: 30
                font.weight: Font.Bold
                font.variableAxes: { "wdth": 115 }
                color: Colours.palette.m3primary
                Layout.topMargin: -4
            }

            Text {
                text: _minutes
                font.family: "Google Sans Flex"
                font.pointSize: 30
                font.weight: Font.Bold
                font.variableAxes: { "wdth": 115 }
                color: Colours.palette.m3onSurface
            }

            Text {
                visible: Colours.use12Hour
                text: _ampm
                font.family: "Google Sans Flex"
                font.pointSize: 11
                font.weight: Font.DemiBold
                color: Colours.palette.m3primary
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: 4
                Layout.leftMargin: 2
            }
        }

        // ── Vertical Divider Bar ─────────────────────────────────────
        Rectangle {
            Layout.preferredHeight: 38
            Layout.preferredWidth: 3
            radius: 1.5
            color: Colours.palette.m3primary
        }

        // ── Stacked Date block ───────────────────────────────────────
        ColumnLayout {
            spacing: 0

            Text {
                text: _monthStr
                font.family: "Google Sans Flex"
                font.pointSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 2.5
                color: Colours.palette.m3primary
            }

            Text {
                text: _dayStr
                font.family: "Google Sans Flex"
                font.pointSize: 14
                font.weight: Font.Bold
                font.letterSpacing: 1.5
                color: Colours.palette.m3onSurface
            }

            Text {
                text: _weekdayStr
                font.family: "Google Sans Flex"
                font.pointSize: 9
                font.weight: Font.Medium
                font.letterSpacing: 1.5
                color: Colours.palette.m3primary
            }
        }
    }

    property string _hours: "00"
    property string _minutes: "00"
    property string _ampm: ""
    property string _monthStr: ""
    property string _dayStr: ""
    property string _weekdayStr: ""

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

        const months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                        "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
        _monthStr = months[d.getMonth()];
        _dayStr = String(d.getDate()).padStart(2, "0");

        const days = ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY",
                      "THURSDAY", "FRIDAY", "SATURDAY"];
        _weekdayStr = days[d.getDay()];
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
        function onUse12HourChanged() {
            root._updateTime();
        }
    }
}
