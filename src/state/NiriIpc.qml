pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Helper d'IPC vers niri. Phase initiale: chaque appel lance `niri msg --json`,
// parse le JSON, ignore les champs inconnus. Une evolution future devra se
// brancher directement sur `$NIRI_SOCKET` avec un event stream long-running
// pour eviter le polling.
Singleton {
    id: root

    readonly property bool available: CompositorState.hasNiriIpc

    signal queryFailed(var args, string reason)

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
}
