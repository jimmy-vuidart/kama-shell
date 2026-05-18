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
        anchor.item: root
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Right
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: function(mouse) {
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
        if (root.trayItem && root.trayItem.hasMenu) {
            console.log(
                "status-notch tray menu open",
                "id=" + String(root.trayItem.id),
                "relativeX=" + Math.round(relativeX),
                "relativeY=" + Math.round(relativeY),
                "hasMenu=" + String(root.trayItem.hasMenu)
            )
            trayMenu.anchor.updateAnchor()
            trayMenu.open()
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
