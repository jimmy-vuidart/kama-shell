import Quickshell
import Quickshell.Io
import QtQuick

import "state"

ShellRoot {
    Process {
        command: ["/usr/bin/python3", "-c", "print('process-probe')"]
        running: true
        onStarted: console.log("process-probe-started", processId)
        onExited: function(exitCode, exitStatus) {
            console.log("process-probe-exited", exitCode, exitStatus)
        }

        stdout: StdioCollector {
            onStreamFinished: console.log("process-probe-stdout", text)
        }
    }

    Component {
        id: dynamicProbeComponent

        Process {
            onStarted: console.log("dynamic-probe-started", processId)
            onExited: function(exitCode, exitStatus) {
                console.log("dynamic-probe-exited", exitCode, exitStatus)
                destroy()
            }

            stdout: StdioCollector {
                onStreamFinished: console.log("dynamic-probe-stdout", text)
            }
        }
    }

    Timer {
        interval: 100
        running: true
        repeat: false

        onTriggered: {
            const probe = dynamicProbeComponent.createObject(this)
            console.log("dynamic-probe-create", probe)
            probe.exec(["/usr/bin/python3", "-c", "print('dynamic-probe')"])
        }
    }

    Timer {
        interval: 12000
        running: true
        repeat: false

        onTriggered: {
            console.log("dock-shell-dir", Quickshell.shellDir)
            console.log("dock-pinned-count", DockState.pinnedApps.length)
            console.log("dock-toplevel-count", DockState.currentToplevels().length)
            console.log("dock-item-count", DockState.items.length)

            for (let i = 0; i < DockState.items.length; i++) {
                const item = DockState.items[i]
                console.log("dock-item", i, item.key || "", item.iconName || "", item.iconSource || "")
            }

            Qt.quit()
        }
    }
}
