import Quickshell
import Quickshell.Wayland
import QtQuick

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
                visible: LauncherState.shouldShowOnScreen(root.modelData)
                focusable: visible
                WlrLayershell.layer: WlrLayershell.Overlay
                WlrLayershell.namespace: "kama-shell-launcher"
                WlrLayershell.keyboardFocus: visible
                    ? WlrKeyboardFocus.Exclusive
                    : WlrKeyboardFocus.None

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                color: "transparent"
                surfaceFormat.opaque: false

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, ShellTheme.isFfxiv ? 0.42 : 0.24)
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: LauncherState.hide()
                }

                AppLauncher {
                    id: launcher

                    anchors.centerIn: parent
                    width: Math.min(760, Math.max(320, window.width - 72))
                    height: Math.min(640, Math.max(360, window.height - 128))
                    active: window.visible
                }
            }
        }
    }
}
