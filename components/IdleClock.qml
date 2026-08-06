pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../services"

// Idle screen clock matching Google's Titan One font style from inspiration image.
// Stacked chunky digits (Hours on top, Minutes on bottom) in dual scheme colours.
Item {
    id: root

    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    FontLoader {
        id: titanFont
        source: Qt.resolvedUrl("../assets/fonts/TitanOne-Regular.ttf")
    }

    readonly property string fontName: titanFont.name || "Titan One"

    property string hrStr: "00"
    property string minStr: "00"
    property string apStr: ""
    property string dateStr: ""

    function updateTime(): void {
        const now = new Date();
        const m = now.getMinutes();
        root.minStr = m < 10 ? "0" + m : "" + m;

        if (Colours.use12Hour) {
            const h = now.getHours();
            const h12 = h % 12 || 12;
            root.hrStr = h12 < 10 ? "0" + h12 : "" + h12;
            root.apStr = h >= 12 ? "PM" : "AM";
        } else {
            const h = now.getHours();
            root.hrStr = h < 10 ? "0" + h : "" + h;
            root.apStr = "";
        }

        root.dateStr = Qt.formatDate(now, "ddd, d MMM");
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updateTime()
    }

    Component.onCompleted: root.updateTime()

    Connections {
        target: Colours
        function onUse12HourChanged() { root.updateTime(); }
    }

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        spacing: -24

        // Stacked Hours and Minutes
        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Math.max(hoursText.implicitWidth, minutesText.implicitWidth) + (root.apStr ? 70 : 0)
            implicitHeight: hoursText.implicitHeight + minutesText.implicitHeight - 40

            // Hours (Top)
            Text {
                id: hoursText
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                text: root.hrStr
                font.family: root.fontName
                font.pointSize: 110
                color: Colours.palette.m3primary
            }

            // Minutes (Bottom)
            Text {
                id: minutesText
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: hoursText.bottom
                anchors.topMargin: -44
                text: root.minStr
                font.family: root.fontName
                font.pointSize: 110
                color: Colours.palette.m3secondary
            }

            // AM/PM Pill (if 12h)
            Rectangle {
                visible: root.apStr.length > 0
                anchors.left: minutesText.right
                anchors.leftMargin: 8
                anchors.bottom: minutesText.bottom
                anchors.bottomMargin: 24
                width: apText.implicitWidth + 16
                height: apText.implicitHeight + 8
                radius: 10
                color: Qt.rgba(Colours.palette.m3surfaceContainerHigh.r,
                               Colours.palette.m3surfaceContainerHigh.g,
                               Colours.palette.m3surfaceContainerHigh.b, 0.85)

                Text {
                    id: apText
                    anchors.centerIn: parent
                    text: root.apStr
                    font.family: "Google Sans Flex"
                    font.pointSize: 13
                    font.weight: Font.Bold
                    color: Colours.palette.m3onSurface
                }
            }
        }

        // Date below clock
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 12
            text: root.dateStr
            font.family: "Google Sans Flex"
            font.pointSize: 14
            font.weight: Font.DemiBold
            font.variableAxes: { "wdth": 85 }
            color: Colours.palette.m3onSurface
            opacity: 0.90
        }
    }
}
