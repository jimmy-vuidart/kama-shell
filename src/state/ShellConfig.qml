pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string configPath: homeDir.length > 0
        ? homeDir + "/.config/kama-shell/kama.conf"
        : ""
    readonly property string ffxivTheme: "ffxiv"
    readonly property string liquidGlassTheme: "liquid-glass"
    readonly property string defaultLauncherShortcut: "Meta"
    readonly property var supportedVisualThemes: [ffxivTheme, liquidGlassTheme]
    readonly property var defaultDockPinnedApps: [
        { desktopId: "zen.desktop", fallbackLabel: "Z" },
        { desktopId: "org.gnome.Console.desktop", fallbackLabel: "T" },
        { desktopId: "org.gnome.Nautilus.desktop", fallbackLabel: "N" },
        { desktopId: "steam.desktop", fallbackLabel: "S" }
    ]

    property string visualTheme: liquidGlassTheme
    property string launcherShortcut: defaultLauncherShortcut
    property string wallpaperPath: ""
    property string homeAssistantUrl: ""
    property string homeAssistantToken: ""
    property var dockPinnedApps: clonePinnedApps(defaultDockPinnedApps)
    property var values: ({})
    property var parseErrors: []
    property bool fileLoaded: false

    function loadLoadedFile() {
        root.applyValues(root.parse(configFile.text()))
        root.fileLoaded = true
    }

    function useDefaults() {
        root.parseErrors = []
        root.applyValues({})
        root.fileLoaded = false
    }

    function applyValues(nextValues) {
        const nextVisualTheme = root.effectiveVisualThemeFor(nextValues)

        if (root.visualTheme !== nextVisualTheme) {
            console.log("kama-shell theme changed", root.visualTheme, "->", nextVisualTheme)
        }

        root.values = nextValues
        root.visualTheme = nextVisualTheme
        root.launcherShortcut = root.effectiveLauncherShortcutFor(nextValues)
        root.wallpaperPath = root.effectiveWallpaperPathFor(nextValues)
        root.homeAssistantUrl = root.effectiveHomeAssistantUrlFor(nextValues)
        root.homeAssistantToken = root.effectiveHomeAssistantTokenFor(nextValues)
        root.dockPinnedApps = root.effectiveDockPinnedAppsFor(nextValues)
    }

    function effectiveVisualTheme() {
        return root.effectiveVisualThemeFor(root.values)
    }

    function effectiveVisualThemeFor(sourceValues) {
        return root.normalizedVisualTheme(
            root.valueFrom(
                sourceValues,
                "appearance.theme",
                root.valueFrom(sourceValues, "visual.theme", root.liquidGlassTheme)
            )
        )
    }

    function effectiveDockPinnedApps() {
        return root.effectiveDockPinnedAppsFor(root.values)
    }

    function effectiveDockPinnedAppsFor(sourceValues) {
        if (root.hasValueFrom(sourceValues, "dock.pinnedApps")) {
            return root.normalizedPinnedApps(root.valueFrom(sourceValues, "dock.pinnedApps", []), [])
        }

        if (root.hasValueFrom(sourceValues, "dock.pinned")) {
            return root.normalizedPinnedApps(root.valueFrom(sourceValues, "dock.pinned", []), [])
        }

        return root.clonePinnedApps(root.defaultDockPinnedApps)
    }

    function effectiveLauncherShortcut() {
        return root.effectiveLauncherShortcutFor(root.values)
    }

    function effectiveLauncherShortcutFor(sourceValues) {
        return root.normalizedShortcut(
            root.valueFrom(sourceValues, "launcher.shortcut", root.defaultLauncherShortcut)
        )
    }

    function effectiveWallpaperPath() {
        return root.effectiveWallpaperPathFor(root.values)
    }

    function effectiveWallpaperPathFor(sourceValues) {
        return root.normalizedWallpaperPath(
            root.valueFrom(sourceValues, "appearance.wallpaper", "")
        )
    }

    function effectiveHomeAssistantUrl() {
        return root.effectiveHomeAssistantUrlFor(root.values)
    }

    function effectiveHomeAssistantUrlFor(sourceValues) {
        return root.normalizedUrl(
            root.valueFrom(sourceValues, "homeAssistant.url", "")
        )
    }

    function effectiveHomeAssistantToken() {
        return root.effectiveHomeAssistantTokenFor(root.values)
    }

    function effectiveHomeAssistantTokenFor(sourceValues) {
        return String(root.valueFrom(sourceValues, "homeAssistant.token", "") || "").trim()
    }

    function normalizedUrl(value) {
        return String(value || "").trim().replace(/\/+$/, "")
    }

    function normalizedWallpaperPath(value) {
        const raw = String(value || "").trim()

        if (!raw.length) {
            return ""
        }

        if (raw.startsWith("~/") && root.homeDir.length > 0) {
            return root.homeDir + raw.slice(1)
        }

        if (raw === "~" && root.homeDir.length > 0) {
            return root.homeDir
        }

        return raw
    }

    function parse(text) {
        const result = {}
        const errors = []
        const lines = String(text || "").split("\n")
        let section = ""

        for (let i = 0; i < lines.length; i++) {
            const rawLine = lines[i].trim()

            if (!rawLine.length || rawLine.startsWith("#") || rawLine.startsWith(";")) {
                continue
            }

            const line = root.stripComments(rawLine).trim()

            if (!line.length) {
                continue
            }

            if (line.startsWith("[") && line.endsWith("]")) {
                section = line.slice(1, -1).trim()
                continue
            }

            const separator = line.indexOf("=")

            if (separator < 0) {
                errors.push("ligne " + (i + 1) + ": clé sans valeur")
                continue
            }

            const key = line.slice(0, separator).trim()
            const rawValue = line.slice(separator + 1).trim()

            if (!key.length) {
                errors.push("ligne " + (i + 1) + ": clé vide")
                continue
            }

            const path = key.indexOf(".") >= 0 || !section.length
                ? key
                : section + "." + key

            root.setValue(result, path, root.parseValue(rawValue))
        }

        root.parseErrors = errors
        return result
    }

    function stripComments(line) {
        let quote = ""

        for (let i = 0; i < line.length; i++) {
            const character = line[i]
            const previous = i > 0 ? line[i - 1] : ""

            if (quote.length > 0) {
                if (character === quote && previous !== "\\") {
                    quote = ""
                }
                continue
            }

            if (character === "\"" || character === "'") {
                quote = character
                continue
            }

            if (
                (character === "#" || character === ";")
                && (i === 0 || /\s/.test(line[i - 1]))
                && (i + 1 >= line.length || /\s/.test(line[i + 1]))
            ) {
                return line.slice(0, i)
            }
        }

        return line
    }

    function parseValue(rawValue) {
        const valueText = String(rawValue || "").trim()

        if (!valueText.length) {
            return ""
        }

        if (valueText.startsWith("[") && valueText.endsWith("]")) {
            return root.splitList(valueText.slice(1, -1))
        }

        if (valueText.indexOf(",") >= 0) {
            return root.splitList(valueText)
        }

        return root.parseScalar(valueText)
    }

    function parseScalar(valueText) {
        const value = String(valueText || "").trim()
        const lowerValue = value.toLowerCase()

        if (
            (value.startsWith("\"") && value.endsWith("\""))
            || (value.startsWith("'") && value.endsWith("'"))
        ) {
            return root.unquote(value)
        }

        if (["true", "yes", "on", "1"].indexOf(lowerValue) >= 0) {
            return true
        }

        if (["false", "no", "off", "0"].indexOf(lowerValue) >= 0) {
            return false
        }

        if (/^-?\d+(\.\d+)?$/.test(value)) {
            return Number(value)
        }

        return value
    }

    function unquote(value) {
        return String(value || "")
            .slice(1, -1)
            .replace(/\\n/g, "\n")
            .replace(/\\t/g, "\t")
            .replace(/\\"/g, "\"")
            .replace(/\\'/g, "'")
            .replace(/\\\\/g, "\\")
    }

    function splitList(valueText) {
        const result = []
        let quote = ""
        let current = ""

        for (let i = 0; i < valueText.length; i++) {
            const character = valueText[i]
            const previous = i > 0 ? valueText[i - 1] : ""

            if (quote.length > 0) {
                current += character
                if (character === quote && previous !== "\\") {
                    quote = ""
                }
                continue
            }

            if (character === "\"" || character === "'") {
                quote = character
                current += character
                continue
            }

            if (character === ",") {
                const item = current.trim()
                if (item.length > 0) {
                    result.push(root.parseScalar(item))
                }
                current = ""
                continue
            }

            current += character
        }

        const lastItem = current.trim()
        if (lastItem.length > 0) {
            result.push(root.parseScalar(lastItem))
        }

        return result
    }

    function setValue(target, path, value) {
        const parts = String(path || "")
            .split(".")
            .map(part => part.trim())
            .filter(part => part.length > 0)

        if (!parts.length) {
            return
        }

        let cursor = target

        for (let i = 0; i < parts.length - 1; i++) {
            const part = parts[i]

            if (
                !Object.prototype.hasOwnProperty.call(cursor, part)
                || cursor[part] === null
                || typeof cursor[part] !== "object"
                || Array.isArray(cursor[part])
            ) {
                cursor[part] = {}
            }

            cursor = cursor[part]
        }

        cursor[parts[parts.length - 1]] = value
    }

    function value(path, fallbackValue) {
        return root.valueFrom(root.values, path, fallbackValue)
    }

    function valueFrom(sourceValues, path, fallbackValue) {
        const parts = String(path || "")
            .split(".")
            .map(part => part.trim())
            .filter(part => part.length > 0)
        let cursor = sourceValues

        for (let i = 0; i < parts.length; i++) {
            if (
                cursor === undefined
                || cursor === null
                || !Object.prototype.hasOwnProperty.call(cursor, parts[i])
            ) {
                return fallbackValue
            }

            cursor = cursor[parts[i]]
        }

        return cursor
    }

    function hasValue(path) {
        return root.hasValueFrom(root.values, path)
    }

    function hasValueFrom(sourceValues, path) {
        const sentinel = ({})
        return root.valueFrom(sourceValues, path, sentinel) !== sentinel
    }

    function stringValue(path, fallbackValue) {
        const resolvedValue = root.value(path, fallbackValue)
        return resolvedValue === undefined || resolvedValue === null
            ? String(fallbackValue || "")
            : String(resolvedValue)
    }

    function boolValue(path, fallbackValue) {
        const resolvedValue = root.value(path, fallbackValue)

        if (typeof resolvedValue === "boolean") {
            return resolvedValue
        }

        const normalized = String(resolvedValue || "").trim().toLowerCase()

        if (["true", "yes", "on", "1"].indexOf(normalized) >= 0) {
            return true
        }

        if (["false", "no", "off", "0"].indexOf(normalized) >= 0) {
            return false
        }

        return !!fallbackValue
    }

    function numberValue(path, fallbackValue) {
        const resolvedValue = Number(root.value(path, fallbackValue))
        return isFinite(resolvedValue) ? resolvedValue : fallbackValue
    }

    function listValue(path, fallbackValue) {
        const resolvedValue = root.value(path, fallbackValue)

        if (Array.isArray(resolvedValue)) {
            return resolvedValue
        }

        if (resolvedValue === undefined || resolvedValue === null) {
            return fallbackValue
        }

        return root.splitList(String(resolvedValue))
    }

    function normalizedVisualTheme(value) {
        const normalized = String(value || "")
            .trim()
            .toLowerCase()

        if (normalized === "current" || normalized === "default") {
            return root.liquidGlassTheme
        }

        if (normalized === "liquid") {
            return root.liquidGlassTheme
        }

        for (let i = 0; i < root.supportedVisualThemes.length; i++) {
            if (normalized === root.supportedVisualThemes[i]) {
                return normalized
            }
        }

        return root.liquidGlassTheme
    }

    function normalizedShortcut(value) {
        const normalized = String(value || "").trim()
        const lowered = normalized.toLowerCase()

        if (!normalized.length || lowered === "super" || lowered === "win" || lowered === "windows") {
            return root.defaultLauncherShortcut
        }

        return normalized
    }

    function normalizedPinnedApps(value, fallbackValue) {
        const source = Array.isArray(value)
            ? value
            : typeof value === "string"
                ? root.splitList(value)
                : []
        const result = []

        for (let i = 0; i < source.length; i++) {
            const item = root.normalizedPinnedApp(source[i])

            if (item) {
                result.push(item)
            }
        }

        return result.length > 0
            ? result
            : root.clonePinnedApps(fallbackValue)
    }

    function normalizedPinnedApp(value) {
        if (value && typeof value === "object" && value.desktopId) {
            const desktopId = String(value.desktopId || "").trim()

            if (!desktopId.length) {
                return null
            }

            return {
                desktopId: desktopId,
                fallbackLabel: String(value.fallbackLabel || root.fallbackLabelForDesktopId(desktopId))
            }
        }

        const text = String(value || "").trim()

        if (!text.length) {
            return null
        }

        const separator = text.indexOf("|")
        const desktopId = separator >= 0
            ? text.slice(0, separator).trim()
            : text

        if (!desktopId.length) {
            return null
        }

        return {
            desktopId: desktopId,
            fallbackLabel: separator >= 0
                ? text.slice(separator + 1).trim()
                : root.fallbackLabelForDesktopId(desktopId)
        }
    }

    function clonePinnedApps(apps) {
        const result = []
        const source = Array.isArray(apps) ? apps : []

        for (let i = 0; i < source.length; i++) {
            const item = root.normalizedPinnedApp(source[i])

            if (item) {
                result.push(item)
            }
        }

        return result
    }

    function fallbackLabelForDesktopId(desktopId) {
        const withoutExtension = String(desktopId || "")
            .replace(/\.desktop$/, "")
            .trim()
        const parts = withoutExtension.split(".")
        const fallbackLabel = parts.length > 0
            ? parts[parts.length - 1]
            : withoutExtension

        return fallbackLabel.slice(0, 1).toUpperCase() || "?"
    }

    function pinnedAppsToConfigValue(apps) {
        const parts = []
        for (let i = 0; i < apps.length; i++) {
            const app = apps[i]
            if (app && app.desktopId) {
                parts.push(app.desktopId + "|" + (app.fallbackLabel || "?"))
            }
        }
        return parts.join(", ")
    }

    function savePinnedApps(apps) {
        if (!root.configPath.length) {
            return
        }

        const value = root.pinnedAppsToConfigValue(apps)
        const proc = configSavePinnedComponent.createObject(root, {
            configPath: root.configPath,
            pinnedAppsValue: value
        })
        proc.running = true
        proc.exited.connect(function() { proc.destroy() })
    }

    function saveTheme(themeName) {
        if (!root.configPath.length) {
            return
        }

        const normalized = root.normalizedVisualTheme(themeName)
        const proc = configSetKeyComponent.createObject(root, {
            configPath: root.configPath,
            sectionDotKey: "appearance.theme",
            keyValue: normalized
        })
        proc.running = true
        proc.exited.connect(function() { proc.destroy() })
    }

    function saveHomeAssistantConfig(url, token) {
        if (!root.configPath.length) {
            return
        }

        root.homeAssistantUrl = root.normalizedUrl(url)
        root.homeAssistantToken = String(token || "").trim()

        const proc = configSetKeyPairComponent.createObject(root, {
            configPath: root.configPath,
            firstSectionDotKey: "homeAssistant.url",
            firstKeyValue: root.homeAssistantUrl,
            secondSectionDotKey: "homeAssistant.token",
            secondKeyValue: root.homeAssistantToken
        })
        proc.running = true
        proc.exited.connect(function() { proc.destroy() })
    }

    component ConfigSavePinnedProcess: Process {
        required property string configPath
        required property string pinnedAppsValue

        command: [
            "python3",
            Quickshell.shellDir + "/../scripts/update-kama-config.py",
            "pinned-apps",
            configPath,
            pinnedAppsValue
        ]
    }

    component ConfigSetKeyProcess: Process {
        required property string configPath
        required property string sectionDotKey
        required property string keyValue

        command: [
            "python3",
            Quickshell.shellDir + "/../scripts/update-kama-config.py",
            "set-key",
            configPath,
            sectionDotKey,
            keyValue
        ]
    }

    component ConfigSetKeyPairProcess: Process {
        required property string configPath
        required property string firstSectionDotKey
        required property string firstKeyValue
        required property string secondSectionDotKey
        required property string secondKeyValue

        command: [
            "python3",
            Quickshell.shellDir + "/../scripts/update-kama-config.py",
            "set-keys",
            configPath,
            firstSectionDotKey,
            firstKeyValue,
            secondSectionDotKey,
            secondKeyValue
        ]
    }

    Component {
        id: configSavePinnedComponent
        ConfigSavePinnedProcess {}
    }

    Component {
        id: configSetKeyComponent
        ConfigSetKeyProcess {}
    }

    Component {
        id: configSetKeyPairComponent
        ConfigSetKeyPairProcess {}
    }

    Component.onCompleted: {
        if (!root.configPath.length || !configFile.waitForJob()) {
            root.useDefaults()
            return
        }

        root.loadLoadedFile()
    }

    FileView {
        id: configFile

        path: root.configPath
        printErrors: false
        blockLoading: true
        watchChanges: root.configPath.length > 0

        onLoaded: root.loadLoadedFile()
        onLoadFailed: root.useDefaults()
        onFileChanged: reload()
    }
}
