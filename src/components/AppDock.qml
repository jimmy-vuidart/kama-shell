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
    readonly property bool showMinimap: CompositorState.hasNiriIpc && minimapItem.hasWindows
    readonly property int contentWidth: {
        var width = ShellGeometry.dockItemSize + ShellGeometry.dockSeparatorWidth

        for (var i = 0; i < items.length; i++) {
            width += items[i].kind === "separator"
                ? ShellGeometry.dockSeparatorWidth
                : ShellGeometry.dockItemSize
        }

        // separator after apps + settings item
        width += ShellGeometry.dockSeparatorWidth + ShellGeometry.dockItemSize

        if (actionCount > 0) {
            width += ShellGeometry.dockItemSize
        }

        if (showMinimap) {
            width += minimapItem.totalWidth + ShellGeometry.dockSeparatorWidth
        }

        const totalChildren = 2 + itemCount + 2 + actionCount + (showMinimap ? 2 : 0)
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
    property string draggedPinnedDesktopId: ""
    property string dragTargetDesktopId: ""
    property bool dragInsertAfterTarget: false
    readonly property bool hovered: dockHoverHandler.hovered
    readonly property bool contextMenuVisible: contextMenu.visible
    readonly property bool draggingPinnedItem: draggedPinnedDesktopId.length > 0

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

    function appItemCenterX(item) {
        const point = item.mapToItem(
            root,
            (item.width / 2) + item.dragVisualOffsetX,
            item.height / 2
        )

        return point.x
    }

    function updatePinnedDragTarget(sourceDesktopId, centerX) {
        if (!sourceDesktopId || !dockItemsRepeater) {
            root.dragTargetDesktopId = ""
            return
        }

        const candidates = []

        for (let i = 0; i < dockItemsRepeater.count; i++) {
            const delegateItem = dockItemsRepeater.itemAt(i)

            if (
                !delegateItem
                || !delegateItem.pinnedDesktopId
                || DockState.desktopIdsMatch(delegateItem.pinnedDesktopId, sourceDesktopId)
            ) {
                continue
            }

            candidates.push({
                desktopId: delegateItem.pinnedDesktopId,
                centerX: delegateItem.mapToItem(root, delegateItem.width / 2, delegateItem.height / 2).x
            })
        }

        if (candidates.length === 0) {
            root.dragTargetDesktopId = ""
            return
        }

        let desiredIndex = 0

        for (let i = 0; i < candidates.length; i++) {
            if (centerX > candidates[i].centerX) {
                desiredIndex += 1
            }
        }

        if (desiredIndex <= 0) {
            root.dragTargetDesktopId = candidates[0].desktopId
            root.dragInsertAfterTarget = false
            return
        }

        if (desiredIndex >= candidates.length) {
            root.dragTargetDesktopId = candidates[candidates.length - 1].desktopId
            root.dragInsertAfterTarget = true
            return
        }

        root.dragTargetDesktopId = candidates[desiredIndex].desktopId
        root.dragInsertAfterTarget = false
    }

    function beginPinnedDrag(sourceDesktopId, item) {
        root.closeContextMenu()
        root.draggedPinnedDesktopId = sourceDesktopId
        root.updatePinnedDragTarget(sourceDesktopId, root.appItemCenterX(item))
    }

    function updatePinnedDrag(sourceDesktopId, item) {
        if (!DockState.desktopIdsMatch(root.draggedPinnedDesktopId, sourceDesktopId)) {
            return
        }

        root.updatePinnedDragTarget(sourceDesktopId, root.appItemCenterX(item))
    }

    function finishPinnedDrag(sourceDesktopId, item) {
        root.updatePinnedDrag(sourceDesktopId, item)

        if (root.dragTargetDesktopId.length > 0) {
            DockState.reorderPinnedItem(
                sourceDesktopId,
                root.dragTargetDesktopId,
                root.dragInsertAfterTarget
            )
        }

        root.draggedPinnedDesktopId = ""
        root.dragTargetDesktopId = ""
        root.dragInsertAfterTarget = false
    }

    function cancelPinnedDrag(sourceDesktopId) {
        if (!DockState.desktopIdsMatch(root.draggedPinnedDesktopId, sourceDesktopId)) {
            return
        }

        root.draggedPinnedDesktopId = ""
        root.dragTargetDesktopId = ""
        root.dragInsertAfterTarget = false
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
            id: dockItemsRepeater

            model: root.items

            delegate: Item {
                required property var modelData
                readonly property string pinnedDesktopId: modelData.kind === "app" && modelData.isPinned
                    ? String(modelData.desktopId || "")
                    : ""

                width: modelData.kind === "separator" ? ShellGeometry.dockSeparatorWidth : ShellGeometry.dockItemSize
                height: modelData.kind === "separator" ? ShellGeometry.dockSeparatorHeight : ShellGeometry.dockItemSize
                z: modelData.kind === "app"
                    && DockState.desktopIdsMatch(root.draggedPinnedDesktopId, modelData.desktopId)
                    ? 100
                    : 0

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
                    reorderable: modelData.kind === "app" && modelData.isPinned
                    dragDesktopId: modelData.desktopId || ""
                    onClicked: {
                        root.closeContextMenu()
                        DockState.activateItem(modelData)
                    }
                    onSecondaryClicked: function(x, y) {
                        const point = appItem.mapToItem(root, x, y)
                        root.openContextMenu(modelData, point.x, point.y)
                    }
                    onDragStarted: {
                        root.beginPinnedDrag(dragDesktopId, appItem)
                    }
                    onDragMoved: {
                        root.updatePinnedDrag(dragDesktopId, appItem)
                    }
                    onDragFinished: {
                        root.finishPinnedDrag(dragDesktopId, appItem)
                    }
                    onDragCanceled: {
                        root.cancelPinnedDrag(dragDesktopId)
                    }
                }

                Rectangle {
                    readonly property bool canDropHere: modelData.kind === "app"
                        && modelData.isPinned
                        && DockState.desktopIdsMatch(root.dragTargetDesktopId, modelData.desktopId)

                    x: root.dragInsertAfterTarget ? parent.width - width : 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: parent.height - 10
                    radius: 1.5
                    color: ShellTheme.runningIndicatorActive
                    opacity: 0.95
                    visible: canDropHere
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

        DockWindowMinimap {
            id: minimapItem

            screen: root.screen
            height: ShellGeometry.dockItemSize
            visible: root.showMinimap
        }

        Item {
            width: ShellGeometry.dockSeparatorWidth
            height: ShellGeometry.dockItemSize
            visible: root.showMinimap

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
