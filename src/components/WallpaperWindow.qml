import Quickshell
import QtQuick
import Quickshell.Wayland

import "../state"

Variants {
    model: Quickshell.screens
    delegate: Component {
        Item {
            id: root
            required property var modelData

            PanelWindow {
                id: window
                screen: root.modelData
                WlrLayershell.layer: WlrLayershell.Background
                WlrLayershell.namespace: "kama-shell-wallpaper"
                color: "transparent"
                focusable: false

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                Rectangle {
                    anchors.fill: parent
                    color: WallpaperState.fallbackColor
                    visible: !WallpaperState.hasWallpaper
                }

                Image {
                    id: wallpaperImage
                    anchors.fill: parent
                    source: WallpaperState.source
                    visible: WallpaperState.hasWallpaper
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(window.width, window.height)
                    cache: true
                    asynchronous: true
                    smooth: true
                    mipmap: true
                }
            }
        }
    }
}
