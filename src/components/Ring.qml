import Quickshell
import QtQuick
import QtQuick.Shapes
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
                readonly property real innerLeft: ShellGeometry.frameInset
                readonly property real innerTop: ShellGeometry.frameInset
                readonly property real innerRight: window.width - ShellGeometry.frameInset
                readonly property real innerBottom: window.height - ShellGeometry.frameInset
                readonly property real clockNotchWidth: Math.min(
                    ShellGeometry.clockNotchWidth,
                    Math.max(0, window.width - ((ShellGeometry.frameInset + ShellGeometry.cornerRadius + 16) * 2))
                )
                readonly property real clockNotchLeft: (window.width - clockNotchWidth) / 2
                readonly property real clockNotchRight: clockNotchLeft + clockNotchWidth
                readonly property real clockNotchBottom: ShellGeometry.frameInset + ShellGeometry.clockNotchDepth
                readonly property real clockNotchRadius: Math.min(
                    ShellGeometry.clockNotchRadius,
                    clockNotchWidth / 2,
                    ShellGeometry.clockNotchDepth
                )
                readonly property real dockRestCenter: window.width / 2
                readonly property real dockCurrentShapeWidth: dockWidget.currentWidth
                readonly property real dockCurrentHeight: dockWidget.currentHeight
                readonly property real dockShapeLeft: dockRestCenter - (dockCurrentShapeWidth / 2)
                readonly property real dockShapeRight: dockRestCenter + (dockCurrentShapeWidth / 2)
                readonly property real dockTop: window.height - ShellGeometry.frameInset - dockCurrentHeight
                readonly property real dockSlopeStartLeft: dockShapeLeft
                readonly property real dockSlopeStartRight: dockShapeRight
                readonly property real dockPeakY: dockTop + 2
                readonly property real dockFlatHalfWidth: (ShellGeometry.dockRestFlatWidth / 2) + ((Math.max(52, dock.bumpWidth * 0.32) - (ShellGeometry.dockRestFlatWidth / 2)) * dockWidget.revealProgress)
                readonly property real dockTopFlatLeft: (window.width / 2) - dockFlatHalfWidth
                readonly property real dockTopFlatRight: (window.width / 2) + dockFlatHalfWidth
                readonly property real dockCurveRun: Math.max(10, (dockSlopeStartRight - dockTopFlatRight) * 0.42)
                readonly property real homePanelTop: ShellGeometry.homePanelTopFor(window.height)
                readonly property real homePanelShapeDepth: ShellGeometry.homePanelBumpDepth
                    + ((ShellGeometry.homePanelExpandedWidth - ShellGeometry.frameInset - ShellGeometry.homePanelBumpDepth) * homePanel.revealProgress)
                readonly property real homePanelShapeLeft: window.innerRight - homePanelShapeDepth
                readonly property real homePanelShapeRight: window.innerRight
                readonly property real homePanelShapeTop: homePanelTop
                readonly property real homePanelShapeBottom: homePanelShapeTop + homePanel.currentHeight
                readonly property real homePanelShapeRadius: Math.min(
                    ShellGeometry.homePanelShapeRadius,
                    homePanelShapeDepth,
                    homePanel.currentHeight / 2
                )

                BackgroundEffect.blurRegion: window.backgroundBlurEnabled ? shellBlurRegion : null

                // Item utilisé par `mask: Region` pour soustraire la silhouette
                // intérieure du décor (zone non-cliquable au centre du ring).
                component InnerCutout: Item {
                    Shape {
                        anchors.fill: parent

                        RingSilhouettePath {
                            innerLeft: window.innerLeft
                            innerTop: window.innerTop
                            innerRight: window.innerRight
                            innerBottom: window.innerBottom
                            cornerRadius: ShellGeometry.cornerRadius
                            clockNotchLeft: window.clockNotchLeft
                            clockNotchRight: window.clockNotchRight
                            clockNotchBottom: window.clockNotchBottom
                            clockNotchRadius: window.clockNotchRadius
                            dockSlopeStartLeft: window.dockSlopeStartLeft
                            dockSlopeStartRight: window.dockSlopeStartRight
                            dockTopFlatLeft: window.dockTopFlatLeft
                            dockTopFlatRight: window.dockTopFlatRight
                            dockPeakY: window.dockPeakY
                            dockCurveRun: window.dockCurveRun
                            homePanelShapeLeft: window.homePanelShapeLeft
                            homePanelShapeRight: window.homePanelShapeRight
                            homePanelShapeTop: window.homePanelShapeTop
                            homePanelShapeBottom: window.homePanelShapeBottom
                            homePanelShapeRadius: window.homePanelShapeRadius

                            fillColor: "white"
                            strokeColor: "transparent"
                            strokeWidth: 0
                        }
                    }
                }

                RingBlurRegion {
                    id: shellBlurRegion

                    active: window.backgroundBlurEnabled
                    surfaceWidth: Math.ceil(window.width)
                    surfaceHeight: Math.ceil(window.height)
                    innerLeft: window.innerLeft
                    innerTop: window.innerTop
                    innerRight: window.innerRight
                    innerBottom: window.innerBottom
                    cornerRadius: ShellGeometry.cornerRadius
                    clockNotchLeft: window.clockNotchLeft
                    clockNotchRight: window.clockNotchRight
                    clockNotchBottom: window.clockNotchBottom
                    clockNotchRadius: window.clockNotchRadius
                    dockSlopeStartLeft: window.dockSlopeStartLeft
                    dockSlopeStartRight: window.dockSlopeStartRight
                    dockTopFlatLeft: window.dockTopFlatLeft
                    dockTopFlatRight: window.dockTopFlatRight
                    dockPeakY: window.dockPeakY
                    dockCurveRun: window.dockCurveRun
                    homePanelShapeLeft: window.homePanelShapeLeft
                    homePanelShapeRight: window.homePanelShapeRight
                    homePanelShapeTop: window.homePanelShapeTop
                    homePanelShapeBottom: window.homePanelShapeBottom
                    homePanelShapeRadius: window.homePanelShapeRadius
                }

                // Composant local: une instance de `RingSilhouettePath` configurée
                // comme outline (pas de fill, stroke 1px à l'intérieur du contour
                // de fill via `inset: 1`). Couleur et largeur paramétrables.
                component RingOutlinePath: RingSilhouettePath {
                    property color outlineColor: "transparent"
                    property real outlineWidth: 1

                    innerLeft: window.innerLeft
                    innerTop: window.innerTop
                    innerRight: window.innerRight
                    innerBottom: window.innerBottom
                    cornerRadius: ShellGeometry.cornerRadius
                    clockNotchLeft: window.clockNotchLeft
                    clockNotchRight: window.clockNotchRight
                    clockNotchBottom: window.clockNotchBottom
                    clockNotchRadius: window.clockNotchRadius
                    dockSlopeStartLeft: window.dockSlopeStartLeft
                    dockSlopeStartRight: window.dockSlopeStartRight
                    dockTopFlatLeft: window.dockTopFlatLeft
                    dockTopFlatRight: window.dockTopFlatRight
                    dockPeakY: window.dockPeakY
                    dockCurveRun: window.dockCurveRun
                    homePanelShapeLeft: window.homePanelShapeLeft
                    homePanelShapeRight: window.homePanelShapeRight
                    homePanelShapeTop: window.homePanelShapeTop
                    homePanelShapeBottom: window.homePanelShapeBottom
                    homePanelShapeRadius: window.homePanelShapeRadius
                    inset: 1

                    strokeColor: outlineColor
                    strokeWidth: outlineWidth
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                }

                mask: Region {
                    width: window.width
                    height: window.height

                    Region {
                        width: window.width
                        height: window.height
                    }

                    Region {
                        item: InnerCutout {
                            width: window.width
                            height: window.height
                        }
                        intersection: Intersection.Subtract
                    }

                    Region {
                        item: dockWidget.contentItem
                    }

                    Region {
                        item: dockWidget.hoverItem
                    }

                    Region {
                        item: homePanel
                    }
                }

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                color: "transparent"
                surfaceFormat.opaque: false

                Shape {
                    anchors.fill: parent

                    // Fill du décor: rectangle plein extérieur + silhouette
                    // intérieure carved out via OddEvenFill, dégradé vertical.
                    RingSilhouettePath {
                        innerLeft: window.innerLeft
                        innerTop: window.innerTop
                        innerRight: window.innerRight
                        innerBottom: window.innerBottom
                        cornerRadius: ShellGeometry.cornerRadius
                        clockNotchLeft: window.clockNotchLeft
                        clockNotchRight: window.clockNotchRight
                        clockNotchBottom: window.clockNotchBottom
                        clockNotchRadius: window.clockNotchRadius
                        dockSlopeStartLeft: window.dockSlopeStartLeft
                        dockSlopeStartRight: window.dockSlopeStartRight
                        dockTopFlatLeft: window.dockTopFlatLeft
                        dockTopFlatRight: window.dockTopFlatRight
                        dockPeakY: window.dockPeakY
                        dockCurveRun: window.dockCurveRun
                        homePanelShapeLeft: window.homePanelShapeLeft
                        homePanelShapeRight: window.homePanelShapeRight
                        homePanelShapeTop: window.homePanelShapeTop
                        homePanelShapeBottom: window.homePanelShapeBottom
                        homePanelShapeRadius: window.homePanelShapeRadius

                        withOuterRectangle: true
                        outerWidth: window.width
                        outerHeight: window.height

                        fillGradient: LinearGradient {
                            x1: 0; y1: 0
                            x2: 0; y2: window.height
                            GradientStop { position: 0.0; color: ShellTheme.panelFillTop }
                            GradientStop { position: 0.16; color: ShellTheme.panelFillUpper }
                            GradientStop { position: 0.62; color: ShellTheme.panelFillMiddle }
                            GradientStop { position: 1.0; color: ShellTheme.panelFillBottom }
                        }
                        strokeColor: "transparent"
                        strokeWidth: 0
                        fillRule: ShapePath.OddEvenFill
                    }

                    RingOutlinePath {
                        outlineColor: ShellTheme.panelBorderSupport
                        outlineWidth: ShellTheme.panelBorderSupportWidth
                    }

                    RingOutlinePath {
                        outlineColor: ShellTheme.panelBorder
                        outlineWidth: ShellTheme.panelBorderWidth
                    }

                    ShapePath {
                        strokeColor: ShellTheme.panelBorderHighlight
                        strokeWidth: ShellTheme.panelHighlightWidth
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin

                        PathMove {
                            x: ShellGeometry.frameInset + 0.5 + ShellGeometry.cornerRadius; y: ShellGeometry.frameInset + 0.5
                        }
                        PathLine {
                            x: window.clockNotchLeft + 0.5; y: ShellGeometry.frameInset + 0.5
                        }
                        PathCubic {
                            x: window.clockNotchLeft + window.clockNotchRadius; y: window.clockNotchBottom - 0.5
                            control1X: window.clockNotchLeft + 0.5 + (window.clockNotchRadius * 0.55); control1Y: ShellGeometry.frameInset + 0.5
                            control2X: window.clockNotchLeft + 0.5; control2Y: window.clockNotchBottom - 0.5 - (window.clockNotchRadius * 0.55)
                        }
                        PathLine {
                            x: window.clockNotchRight - window.clockNotchRadius; y: window.clockNotchBottom - 0.5
                        }
                        PathCubic {
                            x: window.clockNotchRight - 0.5; y: ShellGeometry.frameInset + 0.5
                            control1X: window.clockNotchRight - 0.5; control1Y: window.clockNotchBottom - 0.5 - (window.clockNotchRadius * 0.55)
                            control2X: window.clockNotchRight - 0.5 - (window.clockNotchRadius * 0.55); control2Y: ShellGeometry.frameInset + 0.5
                        }
                        PathLine {
                            x: window.width - ShellGeometry.frameInset - 0.5 - ShellGeometry.cornerRadius; y: ShellGeometry.frameInset + 0.5
                        }
                        PathArc {
                            x: window.width - ShellGeometry.frameInset - 0.5; y: ShellGeometry.frameInset + 0.5 + ShellGeometry.cornerRadius
                            radiusX: ShellGeometry.cornerRadius; radiusY: ShellGeometry.cornerRadius
                            useLargeArc: false
                            direction: PathArc.Clockwise
                        }
                    }

                }

                DateTimeNotch {
                    x: window.clockNotchLeft
                    y: ShellGeometry.frameInset
                    width: window.clockNotchWidth
                    height: ShellGeometry.clockNotchDepth
                    visible: window.clockNotchWidth > 0
                }

                HomePanel {
                    id: homePanel

                    x: window.width - currentWidth
                    y: window.homePanelTop
                }

                HouseIcon {
                    id: homeCompactIcon

                    x: window.innerRight - (ShellGeometry.homePanelBumpDepth / 2) - (width / 2)
                    y: window.homePanelTop + (ShellGeometry.homePanelBumpHeight / 2) - (height / 2)
                    width: ShellGeometry.homePanelHandleIconSize
                    height: ShellGeometry.homePanelHandleIconSize
                    opacity: 1 - Math.min(1, homePanel.revealProgress * 1.35)
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                ExpandableEdgeWidget {
                    id: dockWidget
                    anchors.fill: parent
                    compactWidth: ShellGeometry.dockRestWidth
                    compactHeight: ShellGeometry.dockRestHeight
                    expandedWidth: dock.shapeWidth
                    expandedHeight: dock.implicitHeight
                    compactVisualWidth: ShellGeometry.dockRestWidth - 18
                    compactVisualHeight: ShellGeometry.dockRestHeight - 6
                    contentBottomMargin: ShellGeometry.frameInset
                    compactBottomMargin: ShellGeometry.frameInset + 3
                    hoverBottomMargin: 0
                    hoverWidth: Math.max(dock.shapeWidth, ShellGeometry.dockMinWidth + 72)
                    hoverHeight: ShellGeometry.frameInset + ShellGeometry.dockHoverZoneHeight
                    keepExpanded: dock.hovered || dock.contextMenuVisible
                    compactContent: Component {
                        Item {
                            Item {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: 3
                                width: ShellGeometry.dockRestIconSize
                                height: ShellGeometry.dockRestIconSize

                                Repeater {
                                    model: 4

                                    delegate: Rectangle {
                                        required property int index

                                        readonly property real cellSize: 5
                                        readonly property real cellGap: 2

                                        width: cellSize
                                        height: cellSize
                                        radius: 1.5
                                        x: (index % 2) * (cellSize + cellGap)
                                        y: Math.floor(index / 2) * (cellSize + cellGap)
                                        color: ShellTheme.glyphColor
                                    }
                                }
                            }
                        }
                    }

                    AppDock {
                        id: dock
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            bottom: parent.bottom
                        }
                        revealProgress: dockWidget.revealProgress
                        screen: root.modelData
                    }
                }
            }
        }
    }
}
