import QtQuick
import "components/wirelessPanel" as WirelessPanelComponents

Rectangle {
    id: root

    property bool panelHovered: panelHover.containsMouse
    property int outerRightRadius: 14
    property int topLinkHeight: 12
    property int topLinkWidth: 28
    property int topLinkRadius: 10
    property int panelBorderWidth: 2
    property int panelBodyHeight: 188
    property int concaveRadius: 8
    property color panelBorderColor: "black"
    property color panelColor: "black"

    property bool wirelessEnabled: true
    property bool discovering: true
    property int deviceCount: 0

    property color titleColor: "#d8dbe6"
    property color textColor: "#a7adbf"
    property color secondaryTextColor: "#8f95a8"
    property color switchTrackColor: "#7c84d3"
    property color switchKnobColor: "#f1f2fb"

    opacity: visible ? 1 : 0
    width: 220
    height: root.panelBodyHeight + root.topLinkHeight
    radius: 0
    color: "transparent"
    border.width: 0
    border.color: "transparent"

    WirelessPanelComponents.WirelessPanelShape {
        anchors.fill: parent
        bodyTopInset: root.topLinkHeight
        outerRightRadius: root.outerRightRadius
        topLinkHeight: root.topLinkHeight
        topLinkWidth: root.topLinkWidth
        topLinkRadius: root.topLinkRadius
        panelBorderWidth: root.panelBorderWidth
        panelBorderColor: root.panelBorderColor
        panelColor: root.panelColor
        concaveRadius: root.concaveRadius
    }

    MouseArea {
        id: panelHover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    WirelessPanelComponents.WirelessPanelContent {
        anchors.fill: parent
        anchors.topMargin: root.topLinkHeight
        wirelessEnabled: root.wirelessEnabled
        discovering: root.discovering
        deviceCount: root.deviceCount
        titleColor: root.titleColor
        textColor: root.textColor
        secondaryTextColor: root.secondaryTextColor
        switchTrackColor: root.switchTrackColor
        switchKnobColor: root.switchKnobColor
    }
}