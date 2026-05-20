import Quickshell.Io
import QtQuick

import "../state"

IpcHandler {
    target: "kama-shell"

    function toggleLauncher(): void {
        LauncherState.toggle("")
    }

    function showLauncher(): void {
        LauncherState.show("")
    }

    function hideLauncher(): void {
        LauncherState.hide()
    }

    function brightnessUp(): void {
        OsdState.brightnessUp()
    }

    function brightnessDown(): void {
        OsdState.brightnessDown()
    }

    function toggleSettings(): void {
        SettingsState.toggle("")
    }

    function showSettings(): void {
        SettingsState.show("")
    }

    function hideSettings(): void {
        SettingsState.hide()
    }
}
