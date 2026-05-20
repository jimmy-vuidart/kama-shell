pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property bool visible: false
    property string selectedSection: "appearance"
    property string targetScreenName: ""

    function show(screenName) {
        root.targetScreenName = root.effectiveScreenName(screenName)
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

    function effectiveScreenName(screenName) {
        const requested = String(screenName || "").trim()

        if (requested.length) {
            return requested
        }

        return root.firstScreenName()
    }

    function firstScreenName() {
        const screens = root.screenValues()

        if (screens.length <= 0) {
            return ""
        }

        return root.screenNameFor(screens[0])
    }

    function screenValues() {
        const screens = Quickshell.screens

        if (!screens) {
            return []
        }

        if (screens.values && screens.values.length !== undefined) {
            return root.listValues(screens.values)
        }

        if (screens.length !== undefined) {
            return root.listValues(screens)
        }

        if (screens.count !== undefined && screens.get) {
            const result = []

            for (let i = 0; i < screens.count; i++) {
                result.push(screens.get(i))
            }

            return result
        }

        return []
    }

    function listValues(value) {
        if (!value || value.length === undefined) {
            return []
        }

        const result = []

        for (let i = 0; i < value.length; i++) {
            result.push(value[i])
        }

        return result
    }

    function screenNameFor(screen) {
        return String(screen && screen.name ? screen.name : "").trim()
    }

    function hasScreenName(screenName) {
        const requested = String(screenName || "").trim()
        const screens = root.screenValues()

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

        if (requested.length) {
            return screenName === requested
        }

        const firstScreenName = root.firstScreenName()

        return firstScreenName.length ? screenName === firstScreenName : true
    }
}
