pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property var windows: []
    property var lookupInFlight: null
    property string windowsSignature: ""
    property bool receivedStreamSnapshot: false

    readonly property bool available: NiriIpc.available

    function refresh() {
        if (!root.available || root.lookupInFlight) {
            return
        }

        root.lookupInFlight = NiriIpc.query(["windows"], function(parsed) {
            root.lookupInFlight = null
            root.commitWindows(root.normalizeWindows(parsed))
        })
    }

    function normalizeWindows(parsed) {
        const list = Array.isArray(parsed) ? parsed : []
        const result = []

        for (let i = 0; i < list.length; i++) {
            const source = list[i] || {}
            const id = source.id !== undefined ? source.id : null
            const appId = String(source.app_id || "").trim()
            const title = String(source.title || "").trim()

            if (id === null || (!appId.length && !title.length)) {
                continue
            }

            result.push(root.createWindow(
                id,
                title,
                appId,
                source.workspace_id !== undefined ? source.workspace_id : null,
                !!source.is_focused,
                !!source.is_floating,
                root.fullscreenState(source),
                root.normalizeLayout(source.layout)
            ))
        }

        return result
    }

    function normalizeWindow(source) {
        const item = source || {}
        const id = item.id !== undefined ? item.id : null
        const appId = String(item.app_id || "").trim()
        const title = String(item.title || "").trim()

        if (id === null || (!appId.length && !title.length)) {
            return null
        }

        return root.createWindow(
            id,
            title,
            appId,
            item.workspace_id !== undefined ? item.workspace_id : null,
            !!item.is_focused,
            !!item.is_floating,
            root.fullscreenState(item),
            root.normalizeLayout(item.layout)
        )
    }

    function fullscreenState(source) {
        const item = source || {}

        if (item.is_fullscreen === true || item.fullscreened === true) {
            return true
        }

        if (item.fullscreen !== undefined) {
            const value = Number(item.fullscreen)
            return !isNaN(value) && value > 0
        }

        return false
    }

    function finiteNumber(value, fallback) {
        const number = Number(value)
        return isNaN(number) ? fallback : number
    }

    function arrayValue(source, index, fallback) {
        if (!Array.isArray(source) || source.length <= index) {
            return fallback
        }

        return root.finiteNumber(source[index], fallback)
    }

    function normalizeLayout(source) {
        const item = source || {}
        const pos = item.pos_in_scrolling_layout
        const viewPos = item.tile_pos_in_workspace_view

        return {
            windowWidth: root.arrayValue(item.window_size, 0, 0),
            windowHeight: root.arrayValue(item.window_size, 1, 0),
            tileWidth: root.arrayValue(item.tile_size, 0, 0),
            tileHeight: root.arrayValue(item.tile_size, 1, 0),
            offsetX: root.arrayValue(item.window_offset_in_tile, 0, 0),
            offsetY: root.arrayValue(item.window_offset_in_tile, 1, 0),
            columnIndex: (Array.isArray(pos) && pos.length >= 1 && typeof pos[0] === "number") ? pos[0] : -1,
            tileIndex: (Array.isArray(pos) && pos.length >= 2 && typeof pos[1] === "number") ? pos[1] : -1,
            inView: Array.isArray(viewPos) && viewPos.length >= 2
        }
    }

    function createWindow(id, title, appId, workspaceId, isFocused, isFloating, isFullscreen, layout) {
        return {
            niriWindowId: id,
            desktopId: appId,
            appId: appId,
            resourceClass: appId,
            resourceName: appId,
            iconName: appId,
            title: title || appId || "?",
            workspaceId: workspaceId,
            isFloating: isFloating,
            isFullscreen: isFullscreen,
            layout: layout || root.normalizeLayout(null),
            parent: null,
            activated: isFocused,
            activate: function() {
                root.focusWindowById(id)
            }
        }
    }

    function commitWindows(nextWindows) {
        const signature = root.signatureForWindows(nextWindows)

        if (signature === root.windowsSignature) {
            return false
        }

        root.windowsSignature = signature
        root.windows = nextWindows
        return true
    }

    function signatureForWindows(sourceWindows) {
        const parts = []
        const source = Array.isArray(sourceWindows) ? sourceWindows.slice() : []

        source.sort(function(left, right) {
            return Number(left.niriWindowId || 0) - Number(right.niriWindowId || 0)
        })

        for (let i = 0; i < source.length; i++) {
            const window = source[i]
            const appId = String(window.appId || "").trim()
            const titlePart = appId.length ? "" : String(window.title || "").trim()
            const layout = window.layout || {}

            parts.push([
                String(window.niriWindowId),
                appId,
                String(window.workspaceId),
                window.isFloating ? "f" : "",
                window.isFullscreen ? "F" : "",
                String(layout.windowWidth || 0),
                String(layout.windowHeight || 0),
                String(layout.tileWidth || 0),
                String(layout.tileHeight || 0),
                String(layout.offsetX || 0),
                String(layout.offsetY || 0),
                String(layout.columnIndex !== undefined ? layout.columnIndex : -1),
                String(layout.tileIndex !== undefined ? layout.tileIndex : -1),
                layout.inView ? "v" : "",
                window.activated ? "1" : "0",
                titlePart
            ].join("|"))
        }

        return parts.join("\n")
    }

    function upsertWindow(sourceWindow) {
        const window = root.normalizeWindow(sourceWindow)

        if (!window) {
            return
        }

        const next = []
        let replaced = false

        for (let i = 0; i < root.windows.length; i++) {
            const current = root.windows[i]

            if (String(current.niriWindowId) === String(window.niriWindowId)) {
                next.push(window)
                replaced = true
            } else {
                next.push(window.activated ? root.windowWithFocus(current, false) : current)
            }
        }

        if (!replaced) {
            next.push(window)
        }

        root.commitWindows(next)
    }

    function removeWindow(id) {
        if (id === undefined || id === null) {
            return
        }

        const next = []

        for (let i = 0; i < root.windows.length; i++) {
            if (String(root.windows[i].niriWindowId) !== String(id)) {
                next.push(root.windows[i])
            }
        }

        root.commitWindows(next)
    }

    function focusWindow(id) {
        if (id === undefined || id === null) {
            return
        }

        const next = []

        for (let i = 0; i < root.windows.length; i++) {
            const window = root.windows[i]
            next.push(root.windowWithFocus(window, String(window.niriWindowId) === String(id)))
        }

        root.commitWindows(next)
    }

    function windowWithFocus(window, focused) {
        if (!window || window.activated === focused) {
            return window
        }

        return root.createWindow(
            window.niriWindowId,
            window.title,
            window.appId,
            window.workspaceId,
            focused,
            window.isFloating,
            window.isFullscreen,
            window.layout
        )
    }

    function handleEvent(event) {
        if (!event || typeof event !== "object") {
            return
        }

        if (event.WindowsChanged && event.WindowsChanged.windows !== undefined) {
            root.receivedStreamSnapshot = true
            root.commitWindows(root.normalizeWindows(event.WindowsChanged.windows))
            return
        }

        if (event.WindowOpenedOrChanged && event.WindowOpenedOrChanged.window !== undefined) {
            root.upsertWindow(event.WindowOpenedOrChanged.window)
            return
        }

        if (event.WindowClosed !== undefined) {
            root.removeWindow(root.eventWindowId(event.WindowClosed))
            return
        }

        if (event.WindowFocusChanged !== undefined) {
            root.focusWindow(root.eventWindowId(event.WindowFocusChanged))
            return
        }

        if (event.WindowLayoutsChanged !== undefined) {
            const payload = event.WindowLayoutsChanged
            // changes is Vec<(u64, WindowLayout)> serialized as [[id, layout], ...]
            const layoutList = payload && Array.isArray(payload.changes)
                ? payload.changes
                : (Array.isArray(payload) ? payload : null)

            if (layoutList) {
                root.applyLayoutUpdates(layoutList)
            } else {
                root.refresh()
            }
        }
    }

    function eventWindowId(payload) {
        if (payload === undefined || payload === null) {
            return null
        }

        if (typeof payload === "number" || typeof payload === "string") {
            return payload
        }

        if (payload.id !== undefined) {
            return payload.id
        }

        if (payload.window_id !== undefined) {
            return payload.window_id
        }

        if (payload.window && payload.window.id !== undefined) {
            return payload.window.id
        }

        return null
    }

    function applyLayoutUpdates(layoutList) {
        if (!Array.isArray(layoutList) || layoutList.length === 0) {
            return
        }

        const layoutById = {}

        for (let i = 0; i < layoutList.length; i++) {
            const item = layoutList[i]

            // format: [id, layoutObject] (Rust tuple serialized as array)
            if (Array.isArray(item) && item.length >= 2) {
                layoutById[String(item[0])] = item[1]
            } else if (item && item.id !== undefined) {
                layoutById[String(item.id)] = item.layout || item
            }
        }

        const next = []
        let changed = false

        for (let i = 0; i < root.windows.length; i++) {
            const window = root.windows[i]
            const update = layoutById[String(window.niriWindowId)]

            if (update) {
                const newLayout = root.normalizeLayout(update)
                next.push(root.createWindow(
                    window.niriWindowId,
                    window.title,
                    window.appId,
                    window.workspaceId,
                    window.activated,
                    window.isFloating,
                    window.isFullscreen,
                    newLayout
                ))
                changed = true
            } else {
                next.push(window)
            }
        }

        if (changed) {
            root.commitWindows(next)
        }
    }

    function focusWindowById(id) {
        if (id === undefined || id === null) {
            return
        }

        NiriIpc.query(["action", "focus-window", "--id", String(id)], function() {
            root.refresh()
        })
    }

    Component.onCompleted: {
        if (root.available) {
            root.refresh()
            NiriIpc.startEventStream()
        }
    }

    Connections {
        target: NiriIpc

        function onEventReceived(event) {
            root.handleEvent(event)
        }

        function onEventStreamFailed(_reason) {
            if (!root.receivedStreamSnapshot) {
                root.refresh()
            }
        }
    }
}
