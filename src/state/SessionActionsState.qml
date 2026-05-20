pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string logoutAction: "logout"
    readonly property string rebootAction: "reboot"
    readonly property string poweroffAction: "poweroff"
    readonly property string sessionId: Quickshell.env("XDG_SESSION_ID") || ""
    readonly property bool canLogout: sessionId.length > 0
    readonly property bool busy: currentAction.length > 0
    property bool visible: false
    property string targetScreenName: ""
    property rect anchorRect: Qt.rect(0, 0, 0, 0)
    property string currentAction: ""

    function show(screenName, anchorRect) {
        root.targetScreenName = root.effectiveScreenName(screenName)
        root.anchorRect = anchorRect || Qt.rect(0, 0, 0, 0)
        root.visible = true
    }

    function hide() {
        if (root.busy) {
            return
        }

        root.visible = false
        root.targetScreenName = ""
        root.anchorRect = Qt.rect(0, 0, 0, 0)
    }

    function toggle(screenName, anchorRect) {
        const nextScreenName = root.effectiveScreenName(screenName)

        if (root.visible && root.targetScreenName === nextScreenName) {
            root.hide()
            return
        }

        root.show(nextScreenName, anchorRect)
    }

    function trigger(action) {
        if (root.busy) {
            return
        }

        if (action === root.logoutAction) {
            if (!root.canLogout) {
                return
            }

            root.currentAction = action
            logoutProcess.running = true
            return
        }

        if (action === root.rebootAction) {
            root.currentAction = action
            rebootProcess.running = true
            return
        }

        if (action === root.poweroffAction) {
            root.currentAction = action
            poweroffProcess.running = true
        }
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

    function handleProcessFinished(action) {
        if (root.currentAction === action) {
            root.currentAction = ""
        }
    }

    Process {
        id: logoutProcess

        command: ["loginctl", "terminate-session", root.sessionId]
        running: false
        onRunningChanged: if (!running) root.handleProcessFinished(root.logoutAction)
    }

    Process {
        id: rebootProcess

        command: ["systemctl", "--no-ask-password", "reboot"]
        running: false
        onRunningChanged: if (!running) root.handleProcessFinished(root.rebootAction)
    }

    Process {
        id: poweroffProcess

        command: ["systemctl", "--no-ask-password", "poweroff"]
        running: false
        onRunningChanged: if (!running) root.handleProcessFinished(root.poweroffAction)
    }
}
