import QtQuick

Rectangle {
    id: root

    required property string label
    property bool critical: false
    property bool busy: false
    signal clicked

    width: 68
    height: 48
    radius: 24
    color: critical
        ? Qt.rgba(0.72, 0.18, 0.24, busy ? 0.44 : 0.32)
        : Qt.rgba(1, 1, 1, busy ? 0.2 : 0.12)
    border.width: 1
    border.color: critical
        ? Qt.rgba(1, 0.76, 0.8, busy ? 0.55 : 0.4)
        : Qt.rgba(1, 1, 1, 0.2)
    opacity: enabled ? 1 : 0.45

    Text {
        anchors.centerIn: parent
        text: root.busy ? "..." : root.label
        color: Qt.rgba(0.98, 0.98, 1, 0.96)
        font.pixelSize: 13
        font.weight: 700
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled && !root.busy

        onClicked: root.clicked()
    }
}
