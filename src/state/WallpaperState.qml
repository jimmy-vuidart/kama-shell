pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property string path: ShellConfig.wallpaperPath
    readonly property bool hasWallpaper: path.length > 0
    readonly property url source: hasWallpaper ? "file://" + path : ""
    readonly property color fallbackColor: Qt.rgba(0.04, 0.05, 0.07, 1)
}
