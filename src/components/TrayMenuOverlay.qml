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

            screen: modelData
            visible: menuVisible
            color: "transparent"
            surfaceFormat.opaque: false
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "kama-shell-tray-menu"
            WlrLayershell.keyboardFocus: menuVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            anchors {
                top: true
                left: true
                right: true
                bottom: true
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
                        x: window.clamp(
                            TrayMenuState.anchorRect.x + TrayMenuState.anchorRect.width - width,
                            8,
                            window.width - width - 8
                        )
                        y: window.menuY(height)
                        onCloseRequested: TrayMenuState.close()
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
