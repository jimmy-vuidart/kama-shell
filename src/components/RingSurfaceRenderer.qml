import QtQuick

Item {
    id: root

    required property Item panels

    RingShapeSurface {
        anchors.fill: parent
        panels: root.panels
    }
}
