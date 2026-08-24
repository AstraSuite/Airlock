pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Astra.Airlock
import "../services"
import "../components"

// Avatar / profile picture display
// Looks for ~/.face, falls back to a generic person icon
Item {
    id: root

    required property string username
    required property string avatarPath

    readonly property int size: 120

    implicitWidth: size
    implicitHeight: size

    // Circular clip container
    Rectangle {
        id: avatarCircle

        anchors.centerIn: parent
        width: root.size
        height: root.size
        radius: root.size / 2
        color: Colours.palette.m3surfaceContainerHighest

        // Accent ring
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 4
            height: parent.height + 4
            radius: (parent.width + 4) / 2
            color: "transparent"
            border.color: Qt.alpha(Colours.palette.m3primary, 0.6)
            border.width: 2
        }

        // User avatar image
        Image {
            id: avatarImage
            anchors.fill: parent
            source: root.avatarPath
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
            smooth: true
            layer.enabled: true
            layer.smooth: true
        }

        // Fallback person icon when no avatar
        MaterialIcon {
            anchors.centerIn: parent
            text: "person"
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: 42
            visible: avatarImage.status !== Image.Ready
        }
    }
}
