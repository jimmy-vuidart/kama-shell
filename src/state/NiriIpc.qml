pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Helper d'IPC vers niri. Les requetes ponctuelles passent par
// `niri msg --json`; l'etat fenetres consomme un event stream long-running
// pour eviter le polling.
Singleton {
    id: root

    readonly property bool available: CompositorState.hasNiriIpc
    property bool eventStreamWanted: false
    property int eventStreamRestartDelay: 1000

    signal queryFailed(var args, string reason)
    signal eventReceived(var event)
    signal eventStreamFailed(string reason)

    function query(args, callback) {
        const normalizedArgs = root.normalizeArgs(args)

        if (!root.available) {
            if (typeof callback === "function") {
                callback(null)
            }
            return null
        }

        const proc = queryComponent.createObject(root, {
            queryArgs: normalizedArgs,
            done: typeof callback === "function" ? callback : function() {}
        })

        if (proc) {
            proc.running = true
        }

        return proc
    }

    function normalizeArgs(args) {
        if (Array.isArray(args)) {
            return args.map(function(value) { return String(value) })
        }

        if (args === undefined || args === null) {
            return []
        }

        return [String(args)]
    }

    function parseJson(text, args) {
        const raw = String(text || "").trim()

        if (!raw.length) {
            return null
        }

        try {
            return JSON.parse(raw)
        } catch (error) {
            root.queryFailed(args, String(error))
            return null
        }
    }

    function startEventStream() {
        root.eventStreamWanted = true

        if (!root.available || eventStreamProcess.running) {
            return
        }

        eventStreamRestartTimer.stop()
        eventStreamProcess.running = true
    }

    function stopEventStream() {
        root.eventStreamWanted = false
        eventStreamRestartTimer.stop()

        if (eventStreamProcess.running) {
            eventStreamProcess.running = false
        }
    }

    function restartEventStream() {
        root.stopEventStream()
        Qt.callLater(root.startEventStream)
    }

    function handleEventLine(data) {
        const raw = String(data || "").trim()

        if (!raw.length) {
            return
        }

        try {
            root.eventReceived(JSON.parse(raw))
        } catch (error) {
            root.eventStreamFailed("parse " + String(error))
        }
    }

    function scheduleEventStreamRestart(reason) {
        if (!root.eventStreamWanted || !root.available) {
            return
        }

        root.eventStreamFailed(reason)
        eventStreamRestartTimer.interval = root.eventStreamRestartDelay
        root.eventStreamRestartDelay = Math.min(5000, root.eventStreamRestartDelay * 2)
        eventStreamRestartTimer.restart()
    }

    component QueryProcess: Process {
        id: process

        required property var queryArgs
        required property var done

        command: ["niri", "msg", "--json"].concat(process.queryArgs)

        stdout: StdioCollector {
            onStreamFinished: {
                const parsed = root.parseJson(text, process.queryArgs)

                process.done(parsed)
                process.destroy()
            }
        }

        onExited: function(exitCode, _exitStatus) {
            if (exitCode !== 0) {
                root.queryFailed(process.queryArgs, "exit " + exitCode)
            }
        }
    }

    Component {
        id: queryComponent
        QueryProcess {}
    }

    Process {
        id: eventStreamProcess

        command: ["niri", "msg", "--json", "event-stream"]
        running: false

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: function(data) {
                root.handleEventLine(data)
            }
        }

        stderr: StdioCollector {}

        onStarted: {
            root.eventStreamRestartDelay = 1000
        }

        onExited: function(exitCode, _exitStatus) {
            root.scheduleEventStreamRestart("exit " + exitCode)
        }
    }

    Timer {
        id: eventStreamRestartTimer

        repeat: false

        onTriggered: {
            if (root.eventStreamWanted && root.available && !eventStreamProcess.running) {
                eventStreamProcess.running = true
            }
        }
    }
}
