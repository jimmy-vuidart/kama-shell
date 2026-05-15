pragma Singleton

import Quickshell
import Quickshell.Wayland
import QtQuick

Singleton {
    id: root

    property var pinnedApps: []
    property var items: []
    readonly property var toplevels: ToplevelManager.toplevels.values

    function queueRebuild() {
        root.rebuildItems()
    }

    function applyPinnedAppsFromConfig() {
        root.pinnedApps = ShellConfig.clonePinnedApps(ShellConfig.dockPinnedApps)
        root.queueRebuild()
    }

    function rebuildItems() {
        const ordered = []
        const byKey = {}

        for (let i = 0; i < root.pinnedApps.length; i++) {
            const pinnedApp = root.pinnedApps[i]
            const entry = root.resolveDesktopEntry(pinnedApp.desktopId)
            const key = entry ? entry.id : "pinned:" + pinnedApp.desktopId
            const item = root.createItem(key, entry, pinnedApp.fallbackLabel)

            item.isPinned = true
            item.desktopId = pinnedApp.desktopId

            ordered.push(item)
            byKey[key] = item
        }

        const toplevels = root.currentToplevels()

        for (let i = 0; i < toplevels.length; i++) {
            const toplevel = toplevels[i]
            const entry = root.resolveDesktopEntryForToplevel(toplevel)
            const key = entry ? entry.id : root.fallbackWindowKey(toplevel)
            let item = byKey[key]

            if (!item) {
                item = root.createItem(key, entry, root.fallbackLabelForToplevel(toplevel))
                item.desktopId = entry ? entry.id : (toplevel.desktopId || "")
                ordered.push(item)
                byKey[key] = item
            }

            item.desktopEntry = item.desktopEntry || entry
            item.iconName = item.iconName || (entry ? entry.icon : "") || (toplevel.iconName || "")
            item.iconSource = item.iconSource || root.resolveIconSource(item.iconName)
            item.appId = item.appId || (toplevel.appId || "")
            item.isRunning = true
            item.isActive = item.isActive || toplevel.activated
            item.windowCount += 1
            item.windows.push(toplevel)
            item.label = root.itemLabel(item.desktopEntry, item.label || root.fallbackLabelForToplevel(toplevel))
        }

        const finalItems = []
        let hasRunningUnpinned = false

        for (let i = 0; i < ordered.length; i++) {
            if (ordered[i].isPinned) {
                finalItems.push(ordered[i])
            } else if (ordered[i].isRunning) {
                hasRunningUnpinned = true
            }
        }

        if (finalItems.length > 0 && hasRunningUnpinned) {
            finalItems.push({
                kind: "separator",
                key: "separator"
            })
        }

        for (let i = 0; i < ordered.length; i++) {
            if (!ordered[i].isPinned && ordered[i].isRunning) {
                finalItems.push(ordered[i])
            }
        }

        root.items = finalItems
    }

    function createItem(key, desktopEntry, fallbackLabel) {
        const iconName = desktopEntry ? desktopEntry.icon : ""

        return {
            kind: "app",
            key: key,
            appId: "",
            desktopId: desktopEntry ? desktopEntry.id : "",
            desktopEntry: desktopEntry,
            iconName: iconName,
            iconSource: root.resolveIconSource(iconName),
            windows: [],
            windowCount: 0,
            isPinned: false,
            isRunning: false,
            isActive: false,
            label: root.itemLabel(desktopEntry, fallbackLabel)
        }
    }

    function nativeToplevels() {
        const result = []

        for (let i = 0; i < root.toplevels.length; i++) {
            const toplevel = root.toplevels[i]

            if (!toplevel || toplevel.parent) {
                continue
            }

            result.push(toplevel)
        }

        return result
    }

    function currentToplevels() {
        const nativeWindows = root.nativeToplevels()

        return nativeWindows.length > 0 ? nativeWindows : DockKrunnerFallback.windows
    }

    function refreshKrunnerWindows() {
        DockKrunnerFallback.refresh(root.nativeToplevels().length)
    }

    function activateItem(item) {
        if (!item || item.kind !== "app") {
            return
        }

        const targetWindow = root.preferredWindow(item.windows || [])

        if (targetWindow && !item.isActive) {
            targetWindow.activate()
            return
        }

        if (!targetWindow) {
            const entry = item.desktopEntry || root.resolveDesktopEntry(root.itemDesktopId(item))

            if (entry) {
                entry.execute()
            }
        }
    }

    function preferredWindow(windows) {
        for (let i = 0; i < windows.length; i++) {
            if (windows[i] && windows[i].activated) {
                return windows[i]
            }
        }

        return windows.length > 0 ? windows[0] : null
    }

    function canChangePinState(item) {
        return root.itemDesktopId(item).length > 0
    }

    function pinItem(item) {
        const desktopId = root.itemDesktopId(item)

        if (!desktopId.length || root.isPinnedDesktopId(desktopId)) {
            return
        }

        root.pinnedApps = root.pinnedApps.concat([{
            desktopId: desktopId,
            fallbackLabel: root.fallbackLabelForItem(item)
        }])
        root.queueRebuild()
        ShellConfig.savePinnedApps(root.pinnedApps)
    }

    function unpinItem(item) {
        const desktopId = root.itemDesktopId(item)

        if (!desktopId.length) {
            return
        }

        const nextPinnedApps = []

        for (let i = 0; i < root.pinnedApps.length; i++) {
            if (!root.desktopIdsMatch(root.pinnedApps[i].desktopId, desktopId)) {
                nextPinnedApps.push(root.pinnedApps[i])
            }
        }

        if (nextPinnedApps.length === root.pinnedApps.length) {
            return
        }

        root.pinnedApps = nextPinnedApps
        root.queueRebuild()
        ShellConfig.savePinnedApps(root.pinnedApps)
    }

    function isPinnedDesktopId(desktopId) {
        for (let i = 0; i < root.pinnedApps.length; i++) {
            if (root.desktopIdsMatch(root.pinnedApps[i].desktopId, desktopId)) {
                return true
            }
        }

        return false
    }

    function desktopIdsMatch(left, right) {
        const normalizedLeft = root.normalizedDesktopId(left)
        const normalizedRight = root.normalizedDesktopId(right)

        return normalizedLeft.length > 0 && normalizedLeft === normalizedRight
    }

    function normalizedDesktopId(value) {
        const normalized = String(value || "").trim()

        if (!normalized.length) {
            return ""
        }

        return normalized.endsWith(".desktop") ? normalized : normalized + ".desktop"
    }

    function itemDesktopId(item) {
        if (!item || item.kind !== "app") {
            return ""
        }

        if (item.desktopEntry && item.desktopEntry.id) {
            return item.desktopEntry.id
        }

        const itemDesktopId = String(item.desktopId || "").trim()

        if (itemDesktopId.length) {
            return itemDesktopId
        }

        const windows = item.windows || []

        for (let i = 0; i < windows.length; i++) {
            const entry = root.resolveDesktopEntryForToplevel(windows[i])

            if (entry && entry.id) {
                return entry.id
            }
        }

        return ""
    }

    function fallbackLabelForItem(item) {
        if (!item || item.kind !== "app") {
            return "?"
        }

        if (item.desktopEntry && item.desktopEntry.name) {
            return item.desktopEntry.name
        }

        const windows = item.windows || []

        for (let i = 0; i < windows.length; i++) {
            const fallbackLabel = root.fallbackLabelForToplevel(windows[i])

            if (fallbackLabel && String(fallbackLabel).trim().length) {
                return fallbackLabel
            }
        }

        return String(item.label || "?")
    }

    function resolveDesktopEntryForToplevel(toplevel) {
        const candidates = root.lookupCandidates(toplevel)

        for (let i = 0; i < candidates.length; i++) {
            const entry = root.resolveDesktopEntry(candidates[i])

            if (entry) {
                return entry
            }
        }

        return null
    }

    function resolveDesktopEntry(value) {
        if (!value) {
            return null
        }

        const normalized = String(value).trim()

        if (!normalized.length) {
            return null
        }

        const exactCandidates = [normalized]

        if (normalized.endsWith(".desktop")) {
            exactCandidates.push(normalized.slice(0, -8))
        } else {
            exactCandidates.push(normalized + ".desktop")
        }

        for (let i = 0; i < exactCandidates.length; i++) {
            const exactEntry = DesktopEntries.byId(exactCandidates[i])

            if (exactEntry) {
                return exactEntry
            }
        }

        for (let i = 0; i < exactCandidates.length; i++) {
            const heuristicEntry = DesktopEntries.heuristicLookup(exactCandidates[i])

            if (heuristicEntry) {
                return heuristicEntry
            }
        }

        return null
    }

    function lookupCandidates(toplevel) {
        const rawCandidates = [
            toplevel.desktopId || "",
            root.basename(toplevel.desktopId || ""),
            toplevel.appId || "",
            root.basename(toplevel.appId || ""),
            toplevel.resourceClass || "",
            toplevel.resourceName || "",
            toplevel.iconName || "",
            (toplevel.title || "").split(" - ")[0],
            (toplevel.title || "").split(" — ")[0]
        ]
        const seen = {}
        const result = []

        for (let i = 0; i < rawCandidates.length; i++) {
            const candidate = String(rawCandidates[i] || "").trim()

            if (!candidate.length || seen[candidate]) {
                continue
            }

            seen[candidate] = true
            result.push(candidate)
        }

        return result
    }

    function fallbackWindowKey(toplevel) {
        const desktopId = String(toplevel.desktopId || "").trim()
        const appId = String(toplevel.appId || "").trim()
        const title = String(toplevel.title || "").trim()

        if (desktopId.length) {
            return "window:" + desktopId
        }

        if (appId.length) {
            return "window:" + appId
        }

        if (title.length) {
            return "window:" + title
        }

        return "window:unknown"
    }

    function fallbackLabelForToplevel(toplevel) {
        const title = String(toplevel.title || "").trim()
        const appId = root.basename(toplevel.appId || "")

        if (title.length) {
            return title
        }

        if (appId.length) {
            return appId
        }

        return "?"
    }

    function itemLabel(desktopEntry, fallbackLabel) {
        const source = desktopEntry && desktopEntry.name
            ? String(desktopEntry.name)
            : String(fallbackLabel || "?")

        return source.trim().slice(0, 1).toUpperCase() || "?"
    }

    function resolveIconSource(iconName) {
        return DockIconResolver.resolveIconSource(iconName)
    }

    function basename(value) {
        return DockIconResolver.basename(value)
    }

    Component.onCompleted: {
        root.applyPinnedAppsFromConfig()
        root.refreshKrunnerWindows()
    }

    Timer {
        interval: 2000
        running: DockKrunnerFallback.fallbackEnabled
        repeat: true

        onTriggered: root.refreshKrunnerWindows()
    }

    Connections {
        target: DockIconResolver

        function onIconLookupCacheChanged() {
            root.queueRebuild()
        }
    }

    Connections {
        target: DockKrunnerFallback

        function onWindowsChanged() {
            root.queueRebuild()
        }
    }

    Connections {
        target: DesktopEntries

        function onApplicationsChanged() {
            root.queueRebuild()
        }
    }

    Connections {
        target: ShellConfig

        function onDockPinnedAppsChanged() {
            root.applyPinnedAppsFromConfig()
        }
    }

    Connections {
        target: ToplevelManager.toplevels

        function onObjectInsertedPost() { root.queueRebuild() }
        function onObjectRemovedPost() { root.queueRebuild() }
        function onValuesChanged() { root.queueRebuild() }
    }

    Connections {
        target: ToplevelManager

        function onActiveToplevelChanged() { root.queueRebuild() }
    }

    Instantiator {
        model: root.toplevels

        delegate: Item {
            required property var modelData

            visible: false
            width: 0
            height: 0

            Connections {
                target: modelData

                function onActivatedChanged() { root.queueRebuild() }
                function onAppIdChanged() { root.queueRebuild() }
                function onParentChanged() { root.queueRebuild() }
                function onTitleChanged() { root.queueRebuild() }
            }
        }

        onObjectAdded: root.queueRebuild()
        onObjectRemoved: root.queueRebuild()
    }
}
