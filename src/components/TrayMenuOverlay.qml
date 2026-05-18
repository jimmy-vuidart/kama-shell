import Quickshell
import QtQuick
import Quickshell.Wayland

import "../state"

Variants {
    model: Quickshell.screens
    delegate: Component {
        PanelWindow {
            id: window

            required property var modelData

            readonly property bool menuVisible: TrayMenuState.visible
                && TrayMenuState.screenName === modelData.name
            readonly property bool backgroundBlurEnabled: menuVisible
                && ShellTheme.isLiquidGlass
                && CompositorState.supportsBackgroundEffect

            screen: modelData
            visible: menuVisible
            color: "transparent"
            surfaceFormat.opaque: false
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "kama-shell-tray-menu"
            WlrLayershell.keyboardFocus: menuVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            BackgroundEffect.blurRegion: window.backgroundBlurEnabled ? trayMenuBlurRegion : null

            function refreshTrayMenuBlurRegion() {
                if (window.backgroundBlurEnabled) {
                    trayMenuBlurRegion.changed()
                }
            }

            onBackgroundBlurEnabledChanged: Qt.callLater(refreshTrayMenuBlurRegion)
            onWidthChanged: Qt.callLater(refreshTrayMenuBlurRegion)
            onHeightChanged: Qt.callLater(refreshTrayMenuBlurRegion)

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            Region {
                id: trayMenuBlurRegion

                Region {
                    x: Math.floor(panelLoader.item ? panelLoader.item.x : 0)
                    y: Math.floor(panelLoader.item ? panelLoader.item.y : 0)
                    width: Math.ceil(panelLoader.item ? panelLoader.item.width : 0)
                    height: Math.ceil(panelLoader.item ? panelLoader.item.height : 0)
                    radius: Math.ceil(ShellTheme.isFfxiv ? 8 : 18)
                }
            }

            Item {
                anchors.fill: parent
                focus: window.menuVisible

                Keys.onEscapePressed: TrayMenuState.close()

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onPressed: TrayMenuState.close()
                }

                Loader {
                    id: panelLoader

                    active: window.menuVisible
                    sourceComponent: TrayMenuPanel {
                        id: menuPanel

                        menu: TrayMenuState.menu
                        compositorBlurActive: window.backgroundBlurEnabled
                        x: window.clamp(
                            TrayMenuState.anchorRect.x + TrayMenuState.anchorRect.width - width,
                            8,
                            window.width - width - 8
                        )
                        y: window.menuY(height)
                        onCloseRequested: TrayMenuState.close()
                        onXChanged: Qt.callLater(window.refreshTrayMenuBlurRegion)
                        onYChanged: Qt.callLater(window.refreshTrayMenuBlurRegion)
                        onWidthChanged: Qt.callLater(window.refreshTrayMenuBlurRegion)
                        onHeightChanged: Qt.callLater(window.refreshTrayMenuBlurRegion)
                    }
                }
            }

            function menuY(panelHeight) {
                const below = TrayMenuState.anchorRect.y + TrayMenuState.anchorRect.height + 8
                const above = TrayMenuState.anchorRect.y - panelHeight - 8

                if (below + panelHeight <= window.height - 8) {
                    return below
                }

                return window.clamp(above, 8, window.height - panelHeight - 8)
            }

            function clamp(value, minValue, maxValue) {
                return Math.max(minValue, Math.min(value, Math.max(minValue, maxValue)))
            }
        }
    }
}
