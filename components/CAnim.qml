import QtQuick

ColorAnimation {
    duration: 300
    easing.type: Easing.BezierSpline
    easing.bezierCurve: [0.34, 0.88, 0.34, 1.0, 1.0, 1.0]
}
