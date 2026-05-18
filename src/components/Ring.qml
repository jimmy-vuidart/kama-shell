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
                    innerLeft: ringPanels.innerLeft
                    innerTop: ringPanels.innerTop
                    innerRight: ringPanels.innerRight
                    innerBottom: ringPanels.innerBottom
                    cornerRadius: ShellGeometry.cornerRadius
                    clockNotchLeft: ringPanels.clockNotchLeft
                    clockNotchRight: ringPanels.clockNotchRight
                    clockNotchBottom: ringPanels.clockNotchBottom
                    clockNotchRadius: ringPanels.clockNotchRadius
                    dockSlopeStartLeft: ringPanels.dockSlopeStartLeft
                    dockSlopeStartRight: ringPanels.dockSlopeStartRight
                    dockTopFlatLeft: ringPanels.dockTopFlatLeft
                    dockTopFlatRight: ringPanels.dockTopFlatRight
                    dockPeakY: ringPanels.dockPeakY
                    dockCurveRun: ringPanels.dockCurveRun
                    homePanelShapeLeft: ringPanels.homePanelShapeLeft
                    homePanelShapeRight: ringPanels.homePanelShapeRight
                    homePanelShapeTop: ringPanels.homePanelShapeTop
                    homePanelShapeBottom: ringPanels.homePanelShapeBottom
                    homePanelShapeRadius: ringPanels.homePanelShapeRadius
                }

                RingSurfaceRenderer {
                    anchors.fill: parent
                    panels: ringPanels
                    backend: "sdf"
                    z: 0
                }
            }
        }
    }
}
