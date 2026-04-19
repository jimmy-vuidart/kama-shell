import QtQuick
import "components/frame" as FrameComponents
import "components/wireless" as WirelessComponents

Item {
    id: root

    property int frameMargin: 48
    property int innerRadius: 12
    property real wirelessDockVerticalRatio: 0.66
    property color frameColor: "black"
    property color panelTitleColor: "#d8dbe6"
    property color panelTextColor: "#a7adbf"
    property color panelSecondaryTextColor: "#8f95a8"
    property color panelSwitchTrackColor: "#7c84d3"
    property color panelSwitchKnobColor: "#f1f2fb"
    property alias centerCutoutItem: centerCutout
    property bool wirelessPanelOpen: wirelessDock.triggerHovered || wirelessPanel.panelHovered

    WirelessComponents.WirelessState {
        id: wirelessState
    }

    FrameComponents.FrameBackground {
        anchors.fill: parent
        frameColor: root.frameColor
        frameMargin: root.frameMargin
        innerRadius: root.innerRadius
    }

    Rectangle {
        id: centerCutout
        anchors.fill: parent
        anchors.margins: root.frameMargin
        radius: root.innerRadius
        color: "transparent"
        opacity: 0
    }

    WirelessComponents.WirelessDock {
        id: wirelessDock
        x: 8
        y: Math.round((root.height * root.wirelessDockVerticalRatio) - (height / 2))
        z: 2
    }

    WirelessPanel {
        id: wirelessPanel
        visible: root.wirelessPanelOpen
        x: wirelessDock.x + wirelessDock.width - 4
        y: wirelessDock.y + wirelessDock.height - height
        z: 1
        panelColor: root.frameColor
        panelBorderColor: root.frameColor
        wirelessEnabled: wirelessState.enabled
        discovering: wirelessState.discovering
        deviceCount: wirelessState.deviceCount
        titleColor: root.panelTitleColor
        textColor: root.panelTextColor
        secondaryTextColor: root.panelSecondaryTextColor
        switchTrackColor: root.panelSwitchTrackColor
        switchKnobColor: root.panelSwitchKnobColor
    }
}