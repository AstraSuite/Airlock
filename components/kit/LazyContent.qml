import QtQuick

// Holds a modal's content so it isn't built while the window is starting up.
// The content is built in the background once the app is running, and right
// away if the modal is opened before that has finished.
Loader {
    property bool expanded: false

    anchors.fill: parent
    asynchronous: !expanded
}
