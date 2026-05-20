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
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "kama-shell-ring"

                readonly property bool backgroundBlurEnabled: ShellTheme.isLiquidGlass
                    && CompositorState.supportsBackgroundEffect
                readonly property bool fullscreenActive: NiriWorkspaceState.hasFullscreenOnScreen(root.modelData)

                BackgroundEffect.blurRegion: window.backgroundBlurEnabled && !window.fullscreenActive ? shellBlurRegion : null
                mask: window.fullscreenActive ? emptyInputRegion : activeInputRegion

                Region {
                    id: emptyInputRegion
                }

                RingRegions {
                    id: activeInputRegion

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

                Item {
                    anchors.fill: parent
                    opacity: window.fullscreenActive ? 0 : 1

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutCubic
                        }
                    }

                    RingPanels {
                        id: ringPanels

                        anchors.fill: parent
                        screen: root.modelData
                        z: 1
                    }

                    RingSurfaceRenderer {
                        anchors.fill: parent
                        panels: ringPanels
                        z: 0
                    }
                }

                RingBlurRegion {
                    id: shellBlurRegion

                    active: window.backgroundBlurEnabled && !window.fullscreenActive
                    surfaceWidth: Math.ceil(window.width)
                    surfaceHeight: Math.ceil(window.height)
                    geometry: ringPanels.ringGeometry
                }
            }
        }
    }
}
