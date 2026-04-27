//@ pragma IconTheme Yaru-red-dark

import Quickshell
import QtQuick
import QtQuick.Shapes
import Quickshell.Wayland

import "components"
import "ipc"
import "state"

ShellRoot {
    WallpaperWindow {}
    Ring {}
    AppLauncherOverlay {}
    KamaShellIpc {}
}

