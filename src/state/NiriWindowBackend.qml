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
                !!source.is_focused
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
            !!item.is_focused
        )
    }

    function createWindow(id, title, appId, workspaceId, isFocused) {
        return {
            niriWindowId: id,
            desktopId: appId,
            appId: appId,
            resourceClass: appId,
            resourceName: appId,
            iconName: appId,
            title: title || appId || "?",
            workspaceId: workspaceId,
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

            parts.push([
                String(window.niriWindowId),
                appId,
                String(window.workspaceId),
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
            focused
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
