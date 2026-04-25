import Quickshell
import QtQuick
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var targetScreen
    required property string windowNamespace
    required property int reserveSize
    property bool anchorTop: false
    property bool anchorLeft: false
    property bool anchorRight: false
    property bool anchorBottom: false

    screen: targetScreen
    WlrLayershell.layer: WlrLayershell.Top
    WlrLayershell.namespace: windowNamespace

    anchors {
        top: root.anchorTop
        left: root.anchorLeft
        right: root.anchorRight
        bottom: root.anchorBottom
    }

    implicitWidth: root.reserveSize
    implicitHeight: root.reserveSize
    exclusiveZone: root.reserveSize
    focusable: false
    color: "transparent"
    surfaceFormat.opaque: false
}
