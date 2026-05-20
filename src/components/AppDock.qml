import Quickshell
import QtQuick
import QtQuick.Controls

import "../state"

Item {
    id: root

    property var items: DockState.items
    property real revealProgress: 1
    property var screen: null

    readonly property int itemCount: items.length
    readonly property int actionCount: 1
    readonly property int contentWidth: {
        var width = ShellGeometry.dockItemSize + ShellGeometry.dockSeparatorWidth

        for (var i = 0; i < items.length; i++) {
            width += items[i].kind === "separator"
                ? ShellGeometry.dockSeparatorWidth
                : ShellGeometry.dockItemSize
        }

        // settings separator + settings item
        width += ShellGeometry.dockSeparatorWidth + ShellGeometry.dockItemSize

        if (actionCount > 0) {
            width += ShellGeometry.dockItemSize
        }

        const totalChildren = 2 + itemCount + 2 + actionCount
        width += Math.max(0, totalChildren - 1) * ShellGeometry.dockItemGap
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

        AppDockItem {
            width: ShellGeometry.dockItemSize
            height: ShellGeometry.dockItemSize
            label: "⊞"
            iconSource: Qt.resolvedUrl("../assets/icons/fluent/fluent-apps-24-regular.svg").toString()
            onClicked: LauncherState.toggle(root.screen ? root.screen.name : "")
        }

        Item {
            width: ShellGeometry.dockSeparatorWidth
            height: ShellGeometry.dockItemSize

            DockSeparator {
                anchors.centerIn: parent
            }
        }

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
                    launching: modelData.isLaunching || false
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

        Item {
            width: ShellGeometry.dockSeparatorWidth
            height: ShellGeometry.dockItemSize

            DockSeparator {
                anchors.centerIn: parent
            }
        }

        AppDockItem {
            width: ShellGeometry.dockItemSize
            height: ShellGeometry.dockItemSize
            label: "⚙"
            iconSource: Qt.resolvedUrl("../assets/icons/fluent/fluent-settings-24-regular.svg").toString()
            onClicked: SettingsState.toggle(root.screen ? root.screen.name : "")
        }

        SessionActionButton {
            id: sessionButton

            enabled: !SessionActionsState.busy
            label: "Quitter"
            iconSource: Qt.resolvedUrl("../assets/icons/fluent/fluent-sign-out-24-regular.svg").toString()
            critical: true
            busy: SessionActionsState.busy

            onClicked: {
                root.closeContextMenu()
                const win = root.QsWindow.window
                if (!win || !win.contentItem) {
                    return
                }

                const rect = win.contentItem.mapFromItem(
                    sessionButton, 0, 0, sessionButton.width, sessionButton.height
                )
                SessionActionsState.toggle(root.screen ? root.screen.name : "", rect)
            }
        }
    }
}
