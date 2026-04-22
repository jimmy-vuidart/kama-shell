import QtQuick

import "../state"

Item {
    id: root

    property var items: [
        { kind: "app", label: "F", pinned: true, running: false, active: false },
        { kind: "app", label: "W", pinned: true, running: true, active: true },
        { kind: "app", label: "T", pinned: true, running: false, active: false },
        { kind: "separator" },
        { kind: "app", label: "S", pinned: false, running: true, active: false },
        { kind: "app", label: "C", pinned: false, running: true, active: false }
    ]

    readonly property int itemCount: items.length
    readonly property int gapCount: Math.max(0, itemCount - 1)
    readonly property int contentWidth: {
        var width = 0

        for (var i = 0; i < items.length; i++) {
            width += items[i].kind === "separator"
                ? ShellGeometry.dockSeparatorWidth
                : ShellGeometry.dockItemSize
        }

        width += gapCount * ShellGeometry.dockItemGap
        return width
    }
    readonly property int bumpWidth: Math.max(
        contentWidth + (ShellGeometry.dockBumpContentPadding * 2),
        ShellGeometry.dockMinWidth - 16
    )
    readonly property int shapeWidth: Math.max(
        contentWidth + (ShellGeometry.dockShapeSidePadding * 2),
        bumpWidth + ShellGeometry.dockShapeExtraWidth
    )

    implicitWidth: Math.max(
        contentWidth + (ShellGeometry.dockSidePadding * 2),
        ShellGeometry.dockMinWidth
    )
    implicitHeight: ShellGeometry.dockHeight

    Row {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: ShellGeometry.dockPadding - 8
        }
        spacing: ShellGeometry.dockItemGap

        Repeater {
            model: root.items

            delegate: Item {
                required property var modelData

                width: modelData.kind === "separator" ? ShellGeometry.dockSeparatorWidth : ShellGeometry.dockItemSize
                height: modelData.kind === "separator" ? ShellGeometry.dockSeparatorHeight : ShellGeometry.dockItemSize

                DockSeparator {
                    anchors.centerIn: parent
                    visible: parent.width === ShellGeometry.dockSeparatorWidth
                }

                AppDockItem {
                    anchors.centerIn: parent
                    width: ShellGeometry.dockItemSize
                    height: ShellGeometry.dockItemSize
                    visible: modelData.kind === "app"
                    label: modelData.label || "?"
                    pinned: modelData.pinned || false
                    running: modelData.running || false
                    active: modelData.active || false
                }
            }
        }
    }
}
