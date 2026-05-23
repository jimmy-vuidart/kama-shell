//@ pragma IconTheme hicolor

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
    TrayMenuOverlay {}
    SessionActionsOverlay {}
    AppLauncherOverlay {}
    SettingsOverlay {}
    OsdOverlay {}
    KamaShellIpc {}
}
