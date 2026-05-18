pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property var menu: null
    property string screenName: ""
    property rect anchorRect: Qt.rect(0, 0, 0, 0)
    property bool visible: false

    function open(menu, screenName, anchorRect) {
        if (!menu) {
            root.close()
            return
        }

        root.menu = menu
        root.screenName = screenName || ""
        root.anchorRect = anchorRect || Qt.rect(0, 0, 0, 0)
        root.visible = true
    }

    function close() {
        root.visible = false
        root.menu = null
        root.screenName = ""
        root.anchorRect = Qt.rect(0, 0, 0, 0)
    }
}
