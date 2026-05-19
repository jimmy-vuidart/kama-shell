import Quickshell
import QtQuick
import Quickshell.Wayland

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
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "kama-shell-ring"

                readonly property bool backgroundBlurEnabled: ShellTheme.isLiquidGlass
                    && CompositorState.supportsBackgroundEffect

                BackgroundEffect.blurRegion: window.backgroundBlurEnabled ? shellBlurRegion : null
                mask: RingRegions {
                    panels: ringPanels
                }

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                color: "transparent"
                surfaceFormat.opaque: false

                RingPanels {
                    id: ringPanels

                    anchors.fill: parent
                    screen: root.modelData
                    z: 1
                }

                RingBlurRegion {
                    id: shellBlurRegion

                    active: window.backgroundBlurEnabled
                    surfaceWidth: Math.ceil(window.width)
                    surfaceHeight: Math.ceil(window.height)
                    geometry: ringPanels.ringGeometry
                }

                RingSurfaceRenderer {
                    anchors.fill: parent
                    panels: ringPanels
                    z: 0
                }
            }
        }
    }
}
