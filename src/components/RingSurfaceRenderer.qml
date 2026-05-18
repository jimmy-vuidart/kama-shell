import QtQuick

Item {
    id: root

    required property Item panels
    property string backend: "shape"
    readonly property bool useSdf: backend === "sdf"

    RingShapeSurface {
        anchors.fill: parent
        panels: root.panels
        visible: !root.useSdf
    }

    RingSdfSurface {
        anchors.fill: parent
        panels: root.panels
        visible: root.useSdf
    }
}
