pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property bool visible: false
    property string query: ""
    property int selectedIndex: 0
    property string targetScreenName: ""

    readonly property int resultLimit: 80

    function show(screenName) {
        root.targetScreenName = root.effectiveScreenName(screenName)
        root.query = ""
        root.selectedIndex = 0
        root.visible = true
    }

    function hide() {
        root.visible = false
    }

    function toggle(screenName) {
        const nextScreenName = root.effectiveScreenName(screenName)

        if (root.visible && root.targetScreenName === nextScreenName) {
            root.hide()
            return
        }

        root.show(nextScreenName)
    }

    function moveSelection(delta, count) {
        if (count <= 0) {
            root.selectedIndex = 0
            return
        }

        root.selectedIndex = (root.selectedIndex + delta + count) % count
    }

    function selectIndex(index, count) {
        if (count <= 0) {
            root.selectedIndex = 0
            return
        }

        root.selectedIndex = Math.max(0, Math.min(count - 1, index))
    }

    function clampSelection(count) {
        root.selectIndex(root.selectedIndex, count)
    }

    function launchEntry(entry) {
        if (!entry) {
            return
        }

        entry.execute()
        root.hide()
        DockState.queueRebuild()
    }

    function filteredApplications(applications, queryText) {
        const normalizedQuery = root.normalizedSearch(queryText)
        const source = Array.isArray(applications) ? applications : []
        const scored = []

        for (let i = 0; i < source.length; i++) {
            const entry = source[i]

            if (!entry) {
                continue
            }

            const score = root.matchScore(entry, normalizedQuery)

            if (score >= 0) {
                scored.push({
                    entry: entry,
                    score: score
                })
            }
        }

        scored.sort(function(left, right) {
            if (right.score !== left.score) {
                return right.score - left.score
            }

            return root.entryName(left.entry).localeCompare(root.entryName(right.entry))
        })

        const result = []
        const limit = Math.min(root.resultLimit, scored.length)

        for (let i = 0; i < limit; i++) {
            result.push(scored[i].entry)
        }

        return result
    }

    function matchScore(entry, normalizedQuery) {
        const name = root.normalizedSearch(root.entryName(entry))
        const genericName = root.normalizedSearch(entry.genericName || "")
        const id = root.normalizedSearch(entry.id || "")
        const keywords = root.normalizedSearch(root.listText(entry.keywords))
        const categories = root.normalizedSearch(root.listText(entry.categories))
        const comment = root.normalizedSearch(entry.comment || "")
        const searchable = [
            name,
            genericName,
            id,
            keywords,
            categories,
            comment
        ].join(" ")

        if (!normalizedQuery.length) {
            return 100 - Math.min(60, name.length)
        }

        const tokens = normalizedQuery.split(/\s+/).filter(token => token.length > 0)

        for (let i = 0; i < tokens.length; i++) {
            if (searchable.indexOf(tokens[i]) < 0) {
                return -1
            }
        }

        let score = 0

        if (name === normalizedQuery) {
            score += 1200
        } else if (name.startsWith(normalizedQuery)) {
            score += 950
        } else if (root.hasWordPrefix(name, normalizedQuery)) {
            score += 760
        } else if (name.indexOf(normalizedQuery) >= 0) {
            score += 620
        }

        if (genericName.indexOf(normalizedQuery) >= 0) {
            score += 260
        }

        if (keywords.indexOf(normalizedQuery) >= 0) {
            score += 220
        }

        if (id.indexOf(normalizedQuery) >= 0) {
            score += 120
        }

        return score + Math.max(0, 80 - name.length)
    }

    function hasWordPrefix(text, prefix) {
        const words = String(text || "").split(/[\s._-]+/)

        for (let i = 0; i < words.length; i++) {
            if (words[i].startsWith(prefix)) {
                return true
            }
        }

        return false
    }

    function normalizedSearch(value) {
        return String(value || "")
            .trim()
            .toLowerCase()
            .normalize("NFD")
            .replace(/[\u0300-\u036f]/g, "")
    }

    function listText(value) {
        if (!value || value.length === undefined) {
            return ""
        }

        const result = []

        for (let i = 0; i < value.length; i++) {
            result.push(value[i])
        }

        return result.join(" ")
    }

    function entryName(entry) {
        const name = String(entry && entry.name ? entry.name : "").trim()

        if (name.length) {
            return name
        }

        return String(entry && entry.id ? entry.id : "Application").trim()
    }

    function entrySubtitle(entry) {
        const genericName = String(entry && entry.genericName ? entry.genericName : "").trim()

        if (genericName.length) {
            return genericName
        }

        const comment = String(entry && entry.comment ? entry.comment : "").trim()

        if (comment.length) {
            return comment
        }

        return String(entry && entry.id ? entry.id : "").trim()
    }

    function entryInitial(entry) {
        return root.entryName(entry).slice(0, 1).toUpperCase() || "?"
    }

    function iconSourceFor(entry) {
        const iconName = String(entry && entry.icon ? entry.icon : "").trim()

        return iconName.length ? DockState.resolveIconSource(iconName) : ""
    }

    function effectiveScreenName(screenName) {
        const requested = String(screenName || "").trim()

        if (requested.length) {
            return requested
        }

        return root.firstScreenName()
    }

    function firstScreenName() {
        const screens = Quickshell.screens || []

        if (screens.length <= 0) {
            return ""
        }

        return root.screenNameFor(screens[0])
    }

    function screenNameFor(screen) {
        return String(screen && screen.name ? screen.name : "").trim()
    }

    function hasScreenName(screenName) {
        const requested = String(screenName || "").trim()
        const screens = Quickshell.screens || []

        if (!requested.length) {
            return false
        }

        for (let i = 0; i < screens.length; i++) {
            if (root.screenNameFor(screens[i]) === requested) {
                return true
            }
        }

        return false
    }

    function shouldShowOnScreen(screen) {
        if (!root.visible) {
            return false
        }

        const requested = String(root.targetScreenName || "").trim()
        const screenName = root.screenNameFor(screen)

        if (requested.length && root.hasScreenName(requested)) {
            return screenName === requested
        }

        return screenName === root.firstScreenName()
    }
}
