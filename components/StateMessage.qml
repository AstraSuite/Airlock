pragma ComponentBehavior: Bound

import QtQuick
import "../services"

// Feedback / Error State Message matching Caelestia lockscreen (modules/lock/center/StateMessage.qml).
// Features entrance scale+fade, double pulse flash, 4s auto-dismiss timeout, and smooth exit collapse.
Item {
    id: root

    property string msg: ""
    property string infoMsg: ""
    property bool infoMsgShouldBeVisible: false

    // Auto-dismiss timer (4000ms matching Caelestia lockscreen pwdStateReset)
    Timer {
        id: resetTimer
        interval: 4000
        repeat: false
        onTriggered: {
            root.msg = "";
        }
    }

    function triggerFailure(text) {
        root.msg = text || qsTr("Incorrect password. Please try again.");
        resetTimer.restart();
    }

    function showInfo(text) {
        root.infoMsg = text || "";
        root.infoMsgShouldBeVisible = (text || "").length > 0;
    }

    function clear() {
        resetTimer.stop();
        root.msg = "";
        root.infoMsg = "";
        root.infoMsgShouldBeVisible = false;
    }

    onMsgChanged: {
        if (msg) {
            if (errorMessage.opacity > 0) {
                errorMessage.text = msg;
                exitAnim.stop();
                if (errorMessage.scale < 1)
                    appearAnim.restart();
                else
                    flashAnim.restart();
            } else {
                errorMessage.text = msg;
                exitAnim.stop();
                appearAnim.restart();
            }
        } else {
            appearAnim.stop();
            flashAnim.stop();
            exitAnim.start();
        }
    }

    onInfoMsgChanged: {
        if (infoMsg) {
            infoMessage.text = infoMsg;
            infoMsgShouldBeVisible = true;
        } else {
            infoMsgShouldBeVisible = false;
        }
    }

    implicitWidth: parent ? parent.width : 320
    implicitHeight: Math.max(
        (root.msg.length > 0 || errorMessage.opacity > 0) ? (errorMessage.implicitHeight + 4) : 0,
        (root.infoMsgShouldBeVisible && !root.msg) ? (infoMessage.implicitHeight + 4) : 0
    )

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 300
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.34, 0.88, 0.34, 1.0, 1.0, 1.0]
        }
    }

    // Informational state message (e.g. Starting session...)
    Text {
        id: infoMessage

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        scale: root.infoMsgShouldBeVisible && !root.msg ? 1 : 0.7
        opacity: root.infoMsgShouldBeVisible && !root.msg ? 1 : 0
        color: Colours.palette.m3onSurfaceVariant

        font.family: "Google Sans Flex"
        font.pointSize: 10
        font.weight: Font.Medium
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        lineHeight: 1.2

        Behavior on scale {
            NumberAnimation {
                duration: 300
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.34, 0.88, 0.34, 1.0, 1.0, 1.0]
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
    }

    // Error message (Incorrect password. Please try again.)
    Text {
        id: errorMessage

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        scale: 0.7
        opacity: 0
        color: Colours.palette.m3error

        font.family: "Google Sans Flex"
        font.pointSize: 10
        font.weight: Font.Medium
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        lineHeight: 1.2

        ParallelAnimation {
            id: appearAnim

            NumberAnimation {
                target: errorMessage
                property: "scale"
                to: 1.0
                duration: 200
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: errorMessage
                property: "opacity"
                to: 1.0
                duration: 200
                easing.type: Easing.OutCubic
            }
            onFinished: flashAnim.restart()
        }

        SequentialAnimation {
            id: flashAnim
            loops: 2

            NumberAnimation {
                target: errorMessage
                property: "opacity"
                to: 0.3
                duration: 100
                easing.type: Easing.Linear
            }
            NumberAnimation {
                target: errorMessage
                property: "opacity"
                to: 1.0
                duration: 100
                easing.type: Easing.Linear
            }
        }

        ParallelAnimation {
            id: exitAnim

            NumberAnimation {
                target: errorMessage
                property: "scale"
                to: 0.7
                duration: 300
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.34, 0.88, 0.34, 1.0, 1.0, 1.0]
            }
            NumberAnimation {
                target: errorMessage
                property: "opacity"
                to: 0
                duration: 300
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.34, 0.88, 0.34, 1.0, 1.0, 1.0]
            }
        }
    }
}
