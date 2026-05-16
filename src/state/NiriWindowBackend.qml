pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property var windows: []
    property var lookupInFlight: null

    readonly property bool available: NiriIpc.available

    function refresh() {
        if (!root.available || root.lookupInFlight) {
            return
        }

        root.lookupInFlight = NiriIpc.query(["windows"], function(parsed) {
            root.lookupInFlight = null
            root.windows = root.normalizeWindows(parsed)
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

    function focusWindowById(id) {
        if (id === undefined || id === null) {
            return
        }

        NiriIpc.query(["action", "focus-window", "--id", String(id)], function() {
            root.refresh()
        })
    }

    Component.onCompleted: root.refresh()

    Timer {
        interval: 1000
        running: root.available
        repeat: true

        onTriggered: root.refresh()
    }
}
