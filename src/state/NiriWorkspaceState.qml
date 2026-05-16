pragma Singleton

import Quickshell
import QtQuick

// Etat global derive de l'IPC niri: outputs, workspaces, fenetre focus.
// Le rendu ne doit pas connaitre le backend, il consomme uniquement les
// structures normalisees exposees ici.
Singleton {
    id: root

    property var workspaces: []
    property var outputs: []
    property var focusedWindow: null

    readonly property bool available: NiriIpc.available
    readonly property int focusedWorkspaceId: root.findFocusedWorkspaceId()
    readonly property string focusedOutputName: root.findFocusedOutputName()

    function refresh() {
        if (!root.available) {
            return
        }

        root.refreshWorkspaces()
        root.refreshOutputs()
        root.refreshFocusedWindow()
    }

    function refreshWorkspaces() {
        NiriIpc.query(["workspaces"], function(parsed) {
            root.workspaces = root.normalizeWorkspaces(parsed)
        })
    }

    function refreshOutputs() {
        NiriIpc.query(["outputs"], function(parsed) {
            root.outputs = root.normalizeOutputs(parsed)
        })
    }

    function refreshFocusedWindow() {
        NiriIpc.query(["focused-window"], function(parsed) {
            root.focusedWindow = root.normalizeWindow(parsed)
        })
    }

    function normalizeWorkspaces(parsed) {
        const source = root.unwrap(parsed, "Workspaces")
        const list = Array.isArray(source) ? source : []
        const result = []

        for (let i = 0; i < list.length; i++) {
            const item = list[i] || {}

            result.push({
                id: item.id !== undefined ? item.id : -1,
                idx: item.idx !== undefined ? item.idx : i,
                name: item.name || "",
                output: item.output || "",
                isActive: !!item.is_active,
                isFocused: !!item.is_focused,
                activeWindowId: item.active_window_id !== undefined
                    ? item.active_window_id
                    : null
            })
        }

        return result
    }

    function normalizeOutputs(parsed) {
        const source = root.unwrap(parsed, "Outputs")
        const result = []

        if (source && typeof source === "object" && !Array.isArray(source)) {
            const names = Object.keys(source)

            for (let i = 0; i < names.length; i++) {
                result.push(root.normalizeOutput(names[i], source[names[i]] || {}))
            }

            return result
        }

        const list = Array.isArray(source) ? source : []

        for (let i = 0; i < list.length; i++) {
            const item = list[i] || {}
            result.push(root.normalizeOutput(item.name || "", item))
        }

        return result
    }

    function normalizeOutput(name, item) {
        const currentMode = item.current_mode || null

        return {
            name: name || item.name || "",
            make: item.make || "",
            model: item.model || "",
            serial: item.serial || "",
            currentModeWidth: currentMode ? (currentMode.width || 0) : 0,
            currentModeHeight: currentMode ? (currentMode.height || 0) : 0,
            currentModeRefresh: currentMode ? (currentMode.refresh_rate || 0) : 0,
            logicalX: item.logical ? (item.logical.x || 0) : 0,
            logicalY: item.logical ? (item.logical.y || 0) : 0,
            logicalWidth: item.logical ? (item.logical.width || 0) : 0,
            logicalHeight: item.logical ? (item.logical.height || 0) : 0
        }
    }

    function normalizeWindow(parsed) {
        const source = root.unwrap(parsed, "FocusedWindow")

        if (!source || typeof source !== "object") {
            return null
        }

        return {
            id: source.id !== undefined ? source.id : -1,
            title: source.title || "",
            appId: source.app_id || "",
            workspaceId: source.workspace_id !== undefined ? source.workspace_id : null,
            isFocused: !!source.is_focused
        }
    }

    function unwrap(parsed, key) {
        if (parsed === null || parsed === undefined) {
            return null
        }

        if (Array.isArray(parsed)) {
            return parsed
        }

        if (typeof parsed === "object") {
            if (parsed[key] !== undefined) {
                return parsed[key]
            }

            return parsed
        }

        return null
    }

    function findFocusedWorkspaceId() {
        for (let i = 0; i < root.workspaces.length; i++) {
            if (root.workspaces[i].isFocused) {
                return root.workspaces[i].id
            }
        }

        return -1
    }

    function findFocusedOutputName() {
        for (let i = 0; i < root.workspaces.length; i++) {
            if (root.workspaces[i].isFocused) {
                return root.workspaces[i].output || ""
            }
        }

        return ""
    }

    function action(actionArgs) {
        if (!root.available) {
            return
        }

        const args = Array.isArray(actionArgs) ? actionArgs : [String(actionArgs)]
        NiriIpc.query(["action"].concat(args), function() {})
    }

    function focusWorkspaceUp() { root.action(["focus-workspace-up"]) }
    function focusWorkspaceDown() { root.action(["focus-workspace-down"]) }
    function toggleOverview() { root.action(["toggle-overview"]) }
    function focusWindowById(id) {
        if (id === undefined || id === null) {
            return
        }
        root.action(["focus-window", "--id", String(id)])
    }

    Component.onCompleted: {
        if (root.available) {
            root.refresh()
        }
    }
}
