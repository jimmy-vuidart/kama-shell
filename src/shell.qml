//@ pragma IconTheme Yaru-red-dark

import Quickshell
import QtQuick
import QtQuick.Shapes
import Quickshell.Wayland

import "components"
import "ipc"
import "state"

ShellRoot {
    Ring {}
    AppLauncherOverlay {}
    KamaShellIpc {}
}
