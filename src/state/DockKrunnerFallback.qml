pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var windows: []
    property var lookupInFlight: null

    readonly property string lookupHelper: Quickshell.shellDir + "/../scripts/kwin-running-windows.py"
    readonly property bool fallbackEnabled: (Quickshell.env("KAMA_SESSION") || "").length > 0
        || (Quickshell.env("KDE_FULL_SESSION") || "").length > 0
        || (Quickshell.env("XDG_CURRENT_DESKTOP") || "").indexOf("KDE") >= 0
        || (Quickshell.env("XDG_CURRENT_DESKTOP") || "").indexOf("KamaShell") >= 0

    function refresh(nativeToplevelCount) {
        if (!root.fallbackEnabled) {
            return
        }

        if (nativeToplevelCount > 0) {
            if (root.windows.length > 0) {
                root.windows = []
            }
            return
        }

        if (!root.lookupInFlight) {
            root.startLookup()
        }
    }

    function startLookup() {
        const lookup = lookupComponent.createObject(root)

        if (lookup) {
            root.lookupInFlight = lookup
            Qt.callLater(function() {
                if (root.lookupInFlight === lookup) {
                    lookup.exec(root.lookupCommand())
                }
            })
        }
    }

    function finishLookup(lookup, output) {
        if (root.lookupInFlight === lookup) {
            root.lookupInFlight = null
        }

        root.applyOutput(output)
        lookup.destroy()
    }

    function lookupCommand() {
        return [
            "/usr/bin/python3",
            root.lookupHelper
        ]
    }

    function activateCommand(matchId) {
        return [
            "busctl",
            "--user",
            "call",
            "org.kde.KWin",
            "/WindowsRunner",
            "org.kde.krunner1",
            "Run",
            "ss",
            matchId,
            ""
        ]
    }

    function applyOutput(output) {
        const nextWindows = root.windowsFromOutput(output)

        if (nextWindows === null || root.windowsMatch(root.windows, nextWindows)) {
            return
        }

        root.windows = nextWindows
    }

    function windowsFromOutput(output) {
        let parsed

        try {
            parsed = JSON.parse(String(output || ""))
        } catch (error) {
            return null
        }

        if (parsed && Array.isArray(parsed.windows)) {
            return root.compactWindowsFromOutput(parsed.windows)
        }

        const matches = parsed && parsed.data && parsed.data.length > 0
            ? parsed.data[0]
            : []
        const result = []

        for (let i = 0; i < matches.length; i++) {
            const match = matches[i]

            if (!Array.isArray(match) || match.length < 4) {
                continue
            }

            const matchId = String(match[0] || "").trim()
            const title = String(match[1] || "").trim()
            const iconName = String(match[2] || "").trim()

            if (!matchId.length || (!title.length && !iconName.length)) {
                continue
            }

            result.push(root.createWindow(
                matchId,
                title,
                "",
                "",
                "",
                "",
                iconName,
                false
            ))
        }

        return result
    }

    function compactWindowsFromOutput(windows) {
        const result = []

        for (let i = 0; i < windows.length; i++) {
            const windowInfo = windows[i] || {}
            const matchId = String(windowInfo.matchId || "").trim()
            const title = String(windowInfo.title || "").trim()
            const desktopId = String(windowInfo.desktopId || "").trim()
            const appId = String(windowInfo.appId || "").trim()
            const resourceClass = String(windowInfo.resourceClass || "").trim()
            const resourceName = String(windowInfo.resourceName || "").trim()
            const iconName = String(windowInfo.iconName || "").trim()

            if (!matchId.length || (!title.length && !appId.length && !iconName.length)) {
                continue
            }

            result.push(root.createWindow(
                matchId,
                title,
                desktopId,
                appId,
                resourceClass,
                resourceName,
                iconName,
                !!windowInfo.activated
            ))
        }

        return result
    }

    function createWindow(matchId, title, desktopId, appId, resourceClass, resourceName, iconName, activated) {
        const fallbackAppId = appId || desktopId || resourceClass || resourceName || iconName || title
        const fallbackTitle = title || fallbackAppId || iconName

        return {
            matchId: matchId,
            desktopId: desktopId,
            appId: fallbackAppId,
            resourceClass: resourceClass,
            resourceName: resourceName,
            title: fallbackTitle,
            iconName: iconName,
            parent: null,
            activated: activated,
            activate: function() {
                root.activateMatch(matchId)
            }
        }
    }

    function windowsMatch(left, right) {
        if (left.length !== right.length) {
            return false
        }

        for (let i = 0; i < left.length; i++) {
            if (
                left[i].matchId !== right[i].matchId
                || left[i].title !== right[i].title
                || left[i].desktopId !== right[i].desktopId
                || left[i].appId !== right[i].appId
                || left[i].iconName !== right[i].iconName
                || left[i].activated !== right[i].activated
            ) {
                return false
            }
        }

        return true
    }

    function activateMatch(matchId) {
        const normalized = String(matchId || "").trim()

        if (!normalized.length) {
            return
        }

        activateComponent.createObject(root, {
            matchId: normalized
        })
    }

    component LookupProcess: Process {
        id: process

        stdout: StdioCollector {
            onStreamFinished: root.finishLookup(process, text)
        }
    }

    Component {
        id: lookupComponent
        LookupProcess {}
    }

    component ActivateProcess: Process {
        id: process

        required property string matchId

        command: root.activateCommand(matchId)
        Component.onCompleted: process.exec(command)
        onExited: process.destroy()
    }

    Component {
        id: activateComponent
        ActivateProcess {}
    }
}
