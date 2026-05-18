import QtQuick

import "../state"

Item {
    id: root

    required property var screen

    readonly property alias slotModel: slotModel
    readonly property alias innerLeft: slotModel.innerLeft
    readonly property alias innerTop: slotModel.innerTop
    readonly property alias innerRight: slotModel.innerRight
    readonly property alias innerBottom: slotModel.innerBottom
    readonly property alias clockNotchWidth: slotModel.clockNotchWidth
    readonly property alias clockNotchLeft: slotModel.clockNotchLeft
    readonly property alias clockNotchRight: slotModel.clockNotchRight
    readonly property alias clockNotchBottom: slotModel.clockNotchBottom
    readonly property alias clockNotchRadius: slotModel.clockNotchRadius
    readonly property alias statusNotchLeft: slotModel.statusNotchLeft
    readonly property alias statusNotchRight: slotModel.statusNotchRight
    readonly property alias statusNotchBottom: slotModel.statusNotchBottom
    readonly property alias statusNotchRadius: slotModel.statusNotchRadius
    readonly property alias dockSlopeStartLeft: slotModel.dockSlopeStartLeft
    readonly property alias dockSlopeStartRight: slotModel.dockSlopeStartRight
    readonly property alias dockTopFlatLeft: slotModel.dockTopFlatLeft
    readonly property alias dockTopFlatRight: slotModel.dockTopFlatRight
    readonly property alias dockPeakY: slotModel.dockPeakY
    readonly property alias dockCurveRun: slotModel.dockCurveRun
    readonly property alias homePanelTop: slotModel.homePanelTop
    readonly property alias homePanelShapeLeft: slotModel.homePanelShapeLeft
    readonly property alias homePanelShapeRight: slotModel.homePanelShapeRight
    readonly property alias homePanelShapeTop: slotModel.homePanelShapeTop
    readonly property alias homePanelShapeBottom: slotModel.homePanelShapeBottom
    readonly property alias homePanelShapeRadius: slotModel.homePanelShapeRadius
    readonly property alias morphingIntensity: slotModel.morphingIntensity
    readonly property alias dockContentItem: dockSlot.contentItem
    readonly property alias dockHoverItem: dockSlot.hoverItem
    readonly property alias homePanelItem: homePanel
    readonly property alias statusNotchItem: statusNotch

    RingSlotModel {
        id: slotModel

        surfaceWidth: root.width
        surfaceHeight: root.height
        dockRevealProgress: dockSlot.revealProgress
        dockRevealVelocity: 0
        dockBumpWidth: dock.bumpWidth
        dockCurrentWidth: dockSlot.currentWidth
        dockCurrentHeight: dockSlot.currentHeight
        homeRevealProgress: homePanel.revealProgress
        homeRevealVelocity: 0
        homeCurrentHeight: homePanel.currentHeight
    }

    DateTimeNotch {
        x: root.clockNotchLeft
        y: ShellGeometry.frameInset
        width: root.clockNotchWidth
        height: ShellGeometry.clockNotchDepth
        visible: root.clockNotchWidth > 0
    }

    StatusNotch {
        id: statusNotch

        screen: root.screen
        x: root.statusNotchLeft
        y: ShellGeometry.frameInset
        width: Math.max(0, root.statusNotchRight - root.statusNotchLeft)
        height: ShellGeometry.statusNotchHeight
        visible: width > 0
    }

    HomePanel {
        id: homePanel

        x: root.width - currentWidth
        y: root.homePanelTop

        transform: Scale {
            origin.x: homePanel.width
            origin.y: homePanel.height / 2
            xScale: 1
            yScale: 1
        }
    }

    HouseIcon {
        x: root.innerRight - (ShellGeometry.homePanelBumpDepth / 2) - (width / 2)
        y: root.homePanelTop + (ShellGeometry.homePanelBumpHeight / 2) - (height / 2)
        width: ShellGeometry.homePanelHandleIconSize
        height: ShellGeometry.homePanelHandleIconSize
        opacity: 1 - Math.min(1, homePanel.revealProgress * 1.35)
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
    }

    ExpandableEdgeWidget {
        id: dockSlot

        anchors.fill: parent
        compactWidth: ShellGeometry.dockRestWidth
        compactHeight: ShellGeometry.dockRestHeight
        expandedWidth: dock.shapeWidth
        expandedHeight: dock.implicitHeight
        compactVisualWidth: ShellGeometry.dockRestWidth - 18
        compactVisualHeight: ShellGeometry.dockRestHeight - 6
        contentBottomMargin: ShellGeometry.frameInset
        compactBottomMargin: ShellGeometry.frameInset + 3
        hoverBottomMargin: 0
        hoverWidth: Math.max(dock.shapeWidth, ShellGeometry.dockMinWidth + 72)
        hoverHeight: ShellGeometry.frameInset + ShellGeometry.dockHoverZoneHeight
        keepExpanded: dock.hovered || dock.contextMenuVisible
        compactContent: Component {
            Item {
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 3
                    width: ShellGeometry.dockRestIconSize
                    height: ShellGeometry.dockRestIconSize

                    Repeater {
                        model: 4

                        delegate: Rectangle {
                            required property int index

                            readonly property real cellSize: 5
                            readonly property real cellGap: 2

                            width: cellSize
                            height: cellSize
                            radius: 1.5
                            x: (index % 2) * (cellSize + cellGap)
                            y: Math.floor(index / 2) * (cellSize + cellGap)
                            color: ShellTheme.glyphColor
                        }
                    }
                }
            }
        }

        AppDock {
            id: dock

            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
            }
            revealProgress: dockSlot.revealProgress
            screen: root.screen

            transform: Scale {
                origin.x: dock.width / 2
                origin.y: dock.height
                xScale: 1
                yScale: 1
            }
        }
    }
}
