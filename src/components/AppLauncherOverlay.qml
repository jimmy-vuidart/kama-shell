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
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "kama-shell-launcher"
                WlrLayershell.keyboardFocus: visible
                    ? WlrKeyboardFocus.Exclusive
                    : WlrKeyboardFocus.None

                readonly property bool backgroundBlurEnabled: visible
                    && ShellTheme.isLiquidGlass
                    && CompositorState.supportsBackgroundEffect

                BackgroundEffect.blurRegion: window.backgroundBlurEnabled ? launcherBlurRegion : null

                function refreshLauncherBlurRegion() {
                    if (window.backgroundBlurEnabled) {
                        launcherBlurRegion.changed()
                    }
                }

                onBackgroundBlurEnabledChanged: Qt.callLater(refreshLauncherBlurRegion)
                onWidthChanged: Qt.callLater(refreshLauncherBlurRegion)
                onHeightChanged: Qt.callLater(refreshLauncherBlurRegion)

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                color: "transparent"
                surfaceFormat.opaque: false

                Region {
                    id: launcherBlurRegion

                    Region {
                        x: Math.floor(launcher.x)
                        y: Math.floor(launcher.y)
                        width: Math.ceil(launcher.width)
                        height: Math.ceil(launcher.height)
                        radius: Math.ceil(ShellTheme.isFfxiv ? 10 : 28)
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, ShellTheme.isFfxiv ? 0.34 : 0.18)
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

                    onXChanged: Qt.callLater(window.refreshLauncherBlurRegion)
                    onYChanged: Qt.callLater(window.refreshLauncherBlurRegion)
                    onWidthChanged: Qt.callLater(window.refreshLauncherBlurRegion)
                    onHeightChanged: Qt.callLater(window.refreshLauncherBlurRegion)
                }
            }
        }
    }
}
