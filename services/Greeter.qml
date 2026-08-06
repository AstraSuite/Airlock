pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // Path to optional custom wallpaper image in greeter cache or system backgrounds
    property string wallpaperPath: ""
}
