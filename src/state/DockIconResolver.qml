pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var iconLookupCache: ({})
    property var iconLookupsInFlight: ({})

    readonly property string userIconsDir: Quickshell.env("HOME")
        ? Quickshell.env("HOME") + "/.local/share/icons"
        : ""
    readonly property string legacyIconsDir: Quickshell.env("HOME")
        ? Quickshell.env("HOME") + "/.icons"
        : ""

    function resolveIconSource(iconName) {
        const raw = String(iconName || "").trim()

        if (!raw.length) {
            return ""
        }

        if (raw.startsWith("file:")) {
            return raw
        }

        if (raw.startsWith("/")) {
            return "file://" + raw
        }

        const normalized = root.basename(raw)

        if (!normalized.length) {
            return ""
        }

        const resolvedPath = Quickshell.iconPath(normalized, true)

        if (resolvedPath && resolvedPath.length) {
            return resolvedPath
        }

        if (root.iconLookupCache[normalized] !== undefined) {
            return root.iconLookupCache[normalized]
        }

        root.startIconLookup(normalized)
        return ""
    }

    function startIconLookup(iconName) {
        if (root.iconLookupsInFlight[iconName]) {
            return
        }

        const lookup = iconLookupComponent.createObject(root, {
            iconName: iconName
        })

        root.iconLookupsInFlight[iconName] = lookup
    }

    function finishIconLookup(iconName, output) {
        const cleaned = String(output || "")
            .split("\n")
            .map(function(line) { return line.trim() })
            .find(function(line) { return line.length > 0 }) || ""
        const nextCache = Object.assign({}, root.iconLookupCache)
        const nextInFlight = Object.assign({}, root.iconLookupsInFlight)

        nextCache[iconName] = cleaned.length ? "file://" + cleaned : ""
        delete nextInFlight[iconName]

        root.iconLookupCache = nextCache
        root.iconLookupsInFlight = nextInFlight
    }

    function basename(value) {
        const normalized = String(value || "").trim()
        const slashIndex = normalized.lastIndexOf("/")

        return slashIndex >= 0 ? normalized.slice(slashIndex + 1) : normalized
    }

    component IconLookupProcess: Process {
        id: process

        required property string iconName
        readonly property string lookupScript: [
            "set -eu",
            "icon_name=\"$1\"",
            "shift",
            "for base in \"$@\"; do",
            "    [ -n \"$base\" ] || continue",
            "    [ -d \"$base\" ] || continue",
            "    result=$(find \"$base\" -type f \\( -iname \"$icon_name.png\" -o -iname \"$icon_name.svg\" -o -iname \"$icon_name.xpm\" -o -iname \"$icon_name-symbolic.png\" -o -iname \"$icon_name-symbolic.svg\" -o -iname \"$icon_name-symbolic.xpm\" \\) -print -quit)",
            "    if [ -n \"$result\" ]; then",
            "        printf '%s\\n' \"$result\"",
            "        exit 0",
            "    fi",
            "done"
        ].join("\n")

        command: [
            "sh",
            "-c",
            lookupScript,
            "qs-icon-lookup",
            iconName,
            root.userIconsDir,
            root.legacyIconsDir,
            "/usr/share/icons",
            "/usr/share/pixmaps"
        ]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                root.finishIconLookup(process.iconName, text)
                process.destroy()
            }
        }
    }

    Component {
        id: iconLookupComponent
        IconLookupProcess {}
    }
}
