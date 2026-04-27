import Quickshell.Io
import QtQuick

import "../state"

IpcHandler {
    target: "kama-shell"

    function toggleLauncher(screenName: string): void {
        LauncherState.toggle(screenName)
    }

    function showLauncher(screenName: string): void {
        LauncherState.show(screenName)
    }

    function hideLauncher(): void {
        LauncherState.hide()
    }
}
