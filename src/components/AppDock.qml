import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls

import "../state"

Item {
    id: root

    property var items: DockState.items
    property real revealProgress: 1

    readonly property int itemCount: items.length
    readonly property int gapCount: Math.max(0, itemCount - 1)
    readonly property int actionCount: logoutAvailable ? 1 : 0
    readonly property int contentWidth: {
        var width = 0

        for (var i = 0; i < items.length; i++) {
            width += items[i].kind === "separator"
                ? ShellGeometry.dockSeparatorWidth
                : ShellGeometry.dockItemSize
        }

        width += gapCount * ShellGeometry.dockItemGap
        if (actionCount > 0) {
            width += ShellGeometry.dockItemGap + 68
        }
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
    property var contextItem: null
    readonly property string sessionId: Quickshell.env("XDG_SESSION_ID") || ""
    readonly property bool logoutAvailable: sessionId.length > 0
    readonly property bool hovered: dockHoverHandler.hovered
    readonly property bool contextMenuVisible: contextMenu.visible

    implicitWidth: Math.max(
        contentWidth + (ShellGeometry.dockSidePadding * 2),
        ShellGeometry.dockMinWidth
    )
    implicitHeight: ShellGeometry.dockHeight
    opacity: revealProgress
    scale: 0.94 + (revealProgress * 0.06)
    transformOrigin: Item.Bottom

    function openContextMenu(item, x, y) {
        contextItem = item
        contextMenu.x = x
        contextMenu.y = y
        contextMenu.open()
    }

    function closeContextMenu() {
        contextMenu.close()
        contextItem = null
    }

    function requestLogout() {
        if (!logoutAvailable || logoutProcess.running) {
            return
        }

        logoutProcess.running = true
    }

    Menu {
        id: contextMenu

        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside | Popup.CloseOnReleaseOutside
        onClosed: root.contextItem = null

        MenuItem {
            readonly property bool isPinnedItem: root.contextItem && root.contextItem.isPinned

            text: isPinnedItem ? "Désépingler" : "Épingler"
            enabled: root.contextItem && DockState.canChangePinState(root.contextItem)

            onTriggered: {
                if (!root.contextItem) {
                    return
                }

                if (root.contextItem.isPinned) {
                    DockState.unpinItem(root.contextItem)
                } else {
                    DockState.pinItem(root.contextItem)
                }

                root.closeContextMenu()
            }
        }
    }

    Process {
        id: logoutProcess

        command: ["loginctl", "terminate-session", root.sessionId]
        running: false
    }

    HoverHandler {
        id: dockHoverHandler
    }

    Row {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: (ShellGeometry.dockPadding - 8) - ((1 - root.revealProgress) * ShellGeometry.dockRevealOffset)
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
                    id: appItem

                    anchors.centerIn: parent
                    width: ShellGeometry.dockItemSize
                    height: ShellGeometry.dockItemSize
                    visible: modelData.kind === "app"
                    label: modelData.label || "?"
                    iconSource: modelData.iconSource || ""
                    pinned: modelData.isPinned || false
                    running: modelData.isRunning || false
                    active: modelData.isActive || false
                    onClicked: {
                        root.closeContextMenu()
                        DockState.activateItem(modelData)
                    }
                    onSecondaryClicked: function(x, y) {
                        const point = appItem.mapToItem(root, x, y)
                        root.openContextMenu(modelData, point.x, point.y)
                    }
                }
            }
        }

        SessionActionButton {
            visible: root.logoutAvailable
            enabled: root.logoutAvailable
            label: "Quitter"
            critical: true
            busy: logoutProcess.running

            onClicked: {
                root.closeContextMenu()
                root.requestLogout()
            }
        }
    }
}
