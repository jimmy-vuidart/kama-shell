import Quickshell
import QtQuick

import "../state"

Item {
    id: root

    required property var trayItem
    required property var screen
    readonly property string iconSource: StatusNotchState.normalizeTrayIconSource(root.trayItem ? root.trayItem.icon : "")

    width: ShellGeometry.statusNotchIconSize
    height: ShellGeometry.statusNotchIconSize

    Image {
        id: iconImage

        anchors.fill: parent
        source: root.iconSource
        sourceSize.width: ShellGeometry.statusNotchIconSize
        sourceSize.height: ShellGeometry.statusNotchIconSize
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
        visible: root.iconSource.length > 0 && status === Image.Ready
    }

    Text {
        anchors.centerIn: parent
        text: root.fallbackLabel()
        color: ShellTheme.textPrimary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 10
        font.weight: Font.Bold
        style: ShellTheme.controlTextStyle
        styleColor: ShellTheme.textShadow
        visible: root.iconSource.length === 0 || iconImage.status !== Image.Ready
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: function(mouse) {
            if (!root.trayItem) return

            if (mouse.button === Qt.RightButton) {
                root.showMenu(mouse.x, mouse.y)
            } else if (mouse.button === Qt.MiddleButton) {
                root.trayItem.secondaryActivate()
            } else if (root.trayItem.onlyMenu) {
                root.showMenu(mouse.x, mouse.y)
            } else {
                root.trayItem.activate()
            }
        }
    }

    function showMenu(relativeX, relativeY) {
        if (!root.trayItem || !root.trayItem.hasMenu) return

        const win = root.QsWindow.window
        if (!win || !win.contentItem) return

        const rect = win.contentItem.mapFromItem(root, 0, root.height, root.width, root.height)
        TrayMenuState.open(root.trayItem.menu, root.screen ? root.screen.name : "", rect)
    }

    function fallbackLabel() {
        const source = root.trayItem
            ? String(root.trayItem.title || root.trayItem.tooltipTitle || root.trayItem.id || "?")
            : "?"
        return source.trim().slice(0, 1).toUpperCase() || "?"
    }
}
