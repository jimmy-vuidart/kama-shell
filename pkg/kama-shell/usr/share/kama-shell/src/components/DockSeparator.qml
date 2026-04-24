import QtQuick

Rectangle {
    width: 1
    height: 34
    radius: 1
    color: Qt.rgba(1, 1, 1, 0.18)

    Rectangle {
        anchors {
            fill: parent
            leftMargin: -1
            rightMargin: -1
            topMargin: 6
            bottomMargin: 6
        }
        radius: 2
        color: Qt.rgba(1, 1, 1, 0.08)
    }
}
