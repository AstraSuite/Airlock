pragma ComponentBehavior: Bound

import QtQuick
import "../services"

Rectangle {
    id: root

    color: "transparent"

    Behavior on color {
        CAnim {}
    }
}
