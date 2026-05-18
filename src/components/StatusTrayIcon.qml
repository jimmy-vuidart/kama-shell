import Quickshell
import QtQuick
import QtQuick.Window

import "../state"

Item {
    id: root

    required property var trayItem
    readonly property string iconSource: root.trayItem ? String(root.trayItem.icon || "").trim() : ""

    width: ShellGeometry.statusNotchIconSize
    height: ShellGeometry.statusNotchIconSize

    Component.onCompleted: root.logTrayIcon("completed")
    onTrayItemChanged: root.logTrayIcon("tray-item-changed")
    onIconSourceChanged: root.logTrayIcon("icon-source-changed")

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

        onStatusChanged: {
            root.logTrayIcon("image-status-changed status=" + root.imageStatusName(status))
        }
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

    QsMenuAnchor {
        id: trayMenu

        menu: root.trayItem ? root.trayItem.menu : null
        anchor.window: root.QsWindow.window
        anchor.adjustment: PopupAdjustment.Flip

        anchor.onAnchoring: {
            const win = root.QsWindow.window
            if (!win) return
            const rect = win.contentItem.mapFromItem(
                root, 0, root.height, root.width, root.height
            )
            trayMenu.anchor.rect = rect
            console.log(
                "status-notch tray anchoring",
                "id=" + String(root.trayItem ? root.trayItem.id : "<null>"),
                "rect=(" + Math.round(rect.x) + "," + Math.round(rect.y) + "," + Math.round(rect.width) + "," + Math.round(rect.height) + ")",
                "window=" + String(win)
            )
        }

        onMenuChanged: console.log(
            "status-notch tray menu-ref changed",
            "id=" + String(root.trayItem ? root.trayItem.id : "<null>"),
            "menu=" + String(menu),
            "menu-is-null=" + String(menu === null)
        )
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onPressed: function(mouse) {
            console.log(
                "status-notch tray mouse-pressed",
                "id=" + String(root.trayItem ? root.trayItem.id : "<null>"),
                "button=" + root.buttonName(mouse.button),
                "x=" + Math.round(mouse.x),
                "y=" + Math.round(mouse.y)
            )
        }

        onClicked: function(mouse) {
            console.log(
                "status-notch tray mouse-clicked",
                "id=" + String(root.trayItem ? root.trayItem.id : "<null>"),
                "button=" + root.buttonName(mouse.button),
                "hasItem=" + String(!!root.trayItem),
                "hasMenu=" + String(root.trayItem ? root.trayItem.hasMenu : "<null>"),
                "onlyMenu=" + String(root.trayItem ? root.trayItem.onlyMenu : "<null>"),
                "menu=" + String(root.trayItem ? root.trayItem.menu : "<null>"),
                "trayMenu.menu=" + String(trayMenu.menu)
            )

            if (!root.trayItem) {
                return
            }

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
        const hasItem = !!root.trayItem
        const hasMenu = hasItem && root.trayItem.hasMenu
        const menuObj = hasItem ? root.trayItem.menu : null

        console.log(
            "status-notch tray show-menu called",
            "id=" + String(hasItem ? root.trayItem.id : "<null>"),
            "relativeX=" + Math.round(relativeX),
            "relativeY=" + Math.round(relativeY),
            "hasItem=" + hasItem,
            "hasMenu=" + hasMenu,
            "menu=" + String(menuObj),
            "trayMenu.menu=" + String(trayMenu.menu),
            "anchor.item=" + String(trayMenu.anchor.item)
        )

        if (hasItem && hasMenu) {
            console.log(
                "status-notch tray open-menu",
                "id=" + String(root.trayItem.id),
                "calling trayMenu.open()"
            )
            trayMenu.open()
            console.log(
                "status-notch tray open-menu done",
                "id=" + String(root.trayItem.id)
            )
        }
    }

    function fallbackLabel() {
        const source = root.trayItem
            ? String(root.trayItem.title || root.trayItem.tooltipTitle || root.trayItem.id || "?")
            : "?"

        return source.trim().slice(0, 1).toUpperCase() || "?"
    }

    function logTrayIcon(reason) {
        console.log(
            "status-notch tray icon",
            reason,
            "id=" + String(root.trayItem ? root.trayItem.id : "<null>"),
            "title=" + String(root.trayItem ? root.trayItem.title : "<null>"),
            "tooltipTitle=" + String(root.trayItem ? root.trayItem.tooltipTitle : "<null>"),
            "iconSource=" + root.iconSource,
            "imageSource=" + String(iconImage.source),
            "imageStatus=" + root.imageStatusName(iconImage.status),
            "imageVisible=" + iconImage.visible,
            "fallbackLabel=" + root.fallbackLabel()
        )
    }

    function buttonName(button) {
        if (button === Qt.LeftButton) return "Left"
        if (button === Qt.RightButton) return "Right"
        if (button === Qt.MiddleButton) return "Middle"
        return "Unknown(" + button + ")"
    }

    function imageStatusName(status) {
        if (status === Image.Null) {
            return "Null"
        }

        if (status === Image.Ready) {
            return "Ready"
        }

        if (status === Image.Loading) {
            return "Loading"
        }

        if (status === Image.Error) {
            return "Error"
        }

        return String(status)
    }
}
