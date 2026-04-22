import Quickshell
import QtQuick

import "state"

ShellRoot {
    Timer {
        interval: 1500
        running: true
        repeat: false

        onTriggered: {
            for (let i = 0; i < DockState.items.length; i++) {
                const item = DockState.items[i]
                console.log("dock-item", i, item.key || "", item.iconName || "", item.iconSource || "")
            }

            Qt.quit()
        }
    }
}
