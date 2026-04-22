import QtQuick

Rectangle {
    id: root

    required property string label
    property bool active: false
    property bool pinned: false
    property bool running: false

    width: 48
    height: 48
    radius: 24
    color: active ? Qt.rgba(1, 1, 1, 0.24) : Qt.rgba(1, 1, 1, 0.11)
    border.width: 1
    border.color: active ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(1, 1, 1, 0.18)

    Rectangle {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 4
        }
        width: root.running ? (root.active ? 18 : 10) : 0
        height: 3
        radius: 2
        color: root.active ? Qt.rgba(0.86, 0.95, 1, 0.95) : Qt.rgba(0.86, 0.95, 1, 0.5)
        visible: width > 0
    }

    Text {
        anchors.centerIn: parent
        text: root.label
        color: Qt.rgba(0.95, 0.98, 1, 0.96)
        font.pixelSize: 18
        font.weight: 700
    }
}
