import Quickshell
import QtQuick
import QtQuick.Effects
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
                WlrLayershell.layer: WlrLayershell.Overlay
                WlrLayershell.namespace: "kama-shell-ring"

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
                    ShellGeometry.homePanelCompactShapeRadius
                        + ((ShellGeometry.homePanelShapeRadius - ShellGeometry.homePanelCompactShapeRadius) * homePanel.revealProgress),
                    homePanelShapeDepth,
                    homePanel.currentHeight / 2
                )
                readonly property real homePanelFlatHalfHeight: (ShellGeometry.dockRestFlatWidth / 2)
                    + ((Math.max(0, (homePanel.currentHeight / 2) - window.homePanelShapeRadius) - (ShellGeometry.dockRestFlatWidth / 2)) * homePanel.revealProgress)
                readonly property real homePanelShoulderInset: Math.max(
                    0,
                    (homePanel.currentHeight / 2) - homePanelFlatHalfHeight
                )

                component InnerCutout: Item {
                    Shape {
                        anchors.fill: parent

                        ShapePath {
                            strokeWidth: 0
                            strokeColor: "transparent"
                            fillColor: "white"

                            startX: ShellGeometry.frameInset + ShellGeometry.cornerRadius
                            startY: ShellGeometry.frameInset

                            PathLine {
                                x: window.clockNotchLeft
                                y: ShellGeometry.frameInset
                            }
                            PathCubic {
                                x: window.clockNotchLeft + window.clockNotchRadius
                                y: window.clockNotchBottom
                                control1X: window.clockNotchLeft + (window.clockNotchRadius * 0.55)
                                control1Y: ShellGeometry.frameInset
                                control2X: window.clockNotchLeft
                                control2Y: window.clockNotchBottom - (window.clockNotchRadius * 0.55)
                            }
                            PathLine {
                                x: window.clockNotchRight - window.clockNotchRadius
                                y: window.clockNotchBottom
                            }
                            PathCubic {
                                x: window.clockNotchRight
                                y: ShellGeometry.frameInset
                                control1X: window.clockNotchRight
                                control1Y: window.clockNotchBottom - (window.clockNotchRadius * 0.55)
                                control2X: window.clockNotchRight - (window.clockNotchRadius * 0.55)
                                control2Y: ShellGeometry.frameInset
                            }
                            PathLine {
                                x: window.width - ShellGeometry.frameInset - ShellGeometry.cornerRadius
                                y: ShellGeometry.frameInset
                            }
                            PathArc {
                                x: window.width - ShellGeometry.frameInset
                                y: ShellGeometry.frameInset + ShellGeometry.cornerRadius
                                radiusX: ShellGeometry.cornerRadius
                                radiusY: ShellGeometry.cornerRadius
                                useLargeArc: false
                                direction: PathArc.Clockwise
                            }
                            PathLine {
                                x: window.homePanelShapeRight
                                y: window.homePanelShapeTop
                            }
                            PathCubic {
                                x: window.homePanelShapeLeft
                                y: window.homePanelShapeTop + window.homePanelShoulderInset
                                control1X: window.homePanelShapeRight
                                control1Y: window.homePanelShapeTop + (window.homePanelShoulderInset * 0.45)
                                control2X: window.homePanelShapeLeft
                                control2Y: window.homePanelShapeTop + (window.homePanelShoulderInset * 0.55)
                            }
                            PathLine {
                                x: window.homePanelShapeLeft
                                y: window.homePanelShapeBottom - window.homePanelShoulderInset
                            }
                            PathCubic {
                                x: window.homePanelShapeRight
                                y: window.homePanelShapeBottom
                                control1X: window.homePanelShapeLeft
                                control1Y: window.homePanelShapeBottom - (window.homePanelShoulderInset * 0.55)
                                control2X: window.homePanelShapeRight
                                control2Y: window.homePanelShapeBottom - (window.homePanelShoulderInset * 0.45)
                            }
                            PathLine {
                                x: window.innerRight
                                y: window.innerBottom - ShellGeometry.cornerRadius
                            }
                            PathArc {
                                x: window.innerRight - ShellGeometry.cornerRadius
                                y: window.innerBottom
                                radiusX: ShellGeometry.cornerRadius
                                radiusY: ShellGeometry.cornerRadius
                                useLargeArc: false
                                direction: PathArc.Clockwise
                            }
                            PathLine {
                                x: window.dockSlopeStartRight
                                y: window.innerBottom
                            }
                            PathCubic {
                                x: window.dockTopFlatRight
                                y: window.dockPeakY
                                control1X: window.dockSlopeStartRight - window.dockCurveRun
                                control1Y: window.innerBottom
                                control2X: window.dockTopFlatRight + (window.dockCurveRun * 0.55)
                                control2Y: window.dockPeakY
                            }
                            PathLine {
                                x: window.dockTopFlatLeft
                                y: window.dockPeakY
                            }
                            PathCubic {
                                x: window.dockSlopeStartLeft
                                y: window.innerBottom
                                control1X: window.dockTopFlatLeft - (window.dockCurveRun * 0.55)
                                control1Y: window.dockPeakY
                                control2X: window.dockSlopeStartLeft + window.dockCurveRun
                                control2Y: window.innerBottom
                            }
                            PathLine {
                                x: window.innerLeft + ShellGeometry.cornerRadius
                                y: window.innerBottom
                            }
                            PathArc {
                                x: ShellGeometry.frameInset
                                y: window.height - ShellGeometry.frameInset - ShellGeometry.cornerRadius
                                radiusX: ShellGeometry.cornerRadius
                                radiusY: ShellGeometry.cornerRadius
                                useLargeArc: false
                                direction: PathArc.Clockwise
                            }
                            PathLine {
                                x: ShellGeometry.frameInset
                                y: ShellGeometry.frameInset + ShellGeometry.cornerRadius
                            }
                            PathArc {
                                x: ShellGeometry.frameInset + ShellGeometry.cornerRadius
                                y: ShellGeometry.frameInset
                                radiusX: ShellGeometry.cornerRadius
                                radiusY: ShellGeometry.cornerRadius
                                useLargeArc: false
                                direction: PathArc.Clockwise
                            }
                        }
                    }
                }

                component RingOutlinePath: ShapePath {
                    property color outlineColor: "transparent"
                    property real outlineWidth: 1

                    strokeColor: outlineColor
                    strokeWidth: outlineWidth
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin

                    PathMove {
                        x: ShellGeometry.frameBorderInset + ShellGeometry.cornerRadius; y: ShellGeometry.frameBorderInset
                    }
                    PathLine {
                        x: window.clockNotchLeft + 1; y: ShellGeometry.frameBorderInset
                    }
                    PathCubic {
                        x: window.clockNotchLeft + window.clockNotchRadius; y: window.clockNotchBottom - 1
                        control1X: window.clockNotchLeft + 1 + (window.clockNotchRadius * 0.55); control1Y: ShellGeometry.frameBorderInset
                        control2X: window.clockNotchLeft + 1; control2Y: window.clockNotchBottom - 1 - (window.clockNotchRadius * 0.55)
                    }
                    PathLine {
                        x: window.clockNotchRight - window.clockNotchRadius; y: window.clockNotchBottom - 1
                    }
                    PathCubic {
                        x: window.clockNotchRight - 1; y: ShellGeometry.frameBorderInset
                        control1X: window.clockNotchRight - 1; control1Y: window.clockNotchBottom - 1 - (window.clockNotchRadius * 0.55)
                        control2X: window.clockNotchRight - 1 - (window.clockNotchRadius * 0.55); control2Y: ShellGeometry.frameBorderInset
                    }
                    PathLine {
                        x: window.width - ShellGeometry.frameBorderInset - ShellGeometry.cornerRadius; y: ShellGeometry.frameBorderInset
                    }
                    PathArc {
                        x: window.width - ShellGeometry.frameBorderInset; y: ShellGeometry.frameBorderInset + ShellGeometry.cornerRadius
                        radiusX: ShellGeometry.cornerRadius; radiusY: ShellGeometry.cornerRadius
                        useLargeArc: false
                        direction: PathArc.Clockwise
                    }
                    PathLine {
                        x: window.homePanelShapeRight - 1; y: window.homePanelShapeTop + 1
                    }
                    PathCubic {
                        x: window.homePanelShapeLeft + 1; y: window.homePanelShapeTop + window.homePanelShoulderInset
                        control1X: window.homePanelShapeRight - 1; control1Y: window.homePanelShapeTop + (window.homePanelShoulderInset * 0.45)
                        control2X: window.homePanelShapeLeft + 1; control2Y: window.homePanelShapeTop + (window.homePanelShoulderInset * 0.55)
                    }
                    PathLine {
                        x: window.homePanelShapeLeft + 1; y: window.homePanelShapeBottom - window.homePanelShoulderInset
                    }
                    PathCubic {
                        x: window.homePanelShapeRight - 1; y: window.homePanelShapeBottom - 1
                        control1X: window.homePanelShapeLeft + 1; control1Y: window.homePanelShapeBottom - (window.homePanelShoulderInset * 0.55)
                        control2X: window.homePanelShapeRight - 1; control2Y: window.homePanelShapeBottom - (window.homePanelShoulderInset * 0.45)
                    }
                    PathLine {
                        x: window.innerRight - 1; y: window.innerBottom - 1 - ShellGeometry.cornerRadius
                    }
                    PathArc {
                        x: window.innerRight - 1 - ShellGeometry.cornerRadius; y: window.innerBottom - 1
                        radiusX: ShellGeometry.cornerRadius; radiusY: ShellGeometry.cornerRadius
                        useLargeArc: false
                        direction: PathArc.Clockwise
                    }
                    PathLine {
                        x: window.dockSlopeStartRight - 1; y: window.innerBottom - 1
                    }
                    PathCubic {
                        x: window.dockTopFlatRight - 1; y: window.dockPeakY + 1
                        control1X: window.dockSlopeStartRight - 1 - window.dockCurveRun; control1Y: window.innerBottom - 1
                        control2X: window.dockTopFlatRight - 1 + (window.dockCurveRun * 0.55); control2Y: window.dockPeakY + 1
                    }
                    PathLine {
                        x: window.dockTopFlatLeft + 1; y: window.dockPeakY + 1
                    }
                    PathCubic {
                        x: window.dockSlopeStartLeft + 1; y: window.innerBottom - 1
                        control1X: window.dockTopFlatLeft + 1 - (window.dockCurveRun * 0.55); control1Y: window.dockPeakY + 1
                        control2X: window.dockSlopeStartLeft + 1 + window.dockCurveRun; control2Y: window.innerBottom - 1
                    }
                    PathLine {
                        x: window.innerLeft + ShellGeometry.cornerRadius + 1; y: window.innerBottom - 1
                    }
                    PathArc {
                        x: window.innerLeft + 1; y: window.innerBottom - 1 - ShellGeometry.cornerRadius
                        radiusX: ShellGeometry.cornerRadius; radiusY: ShellGeometry.cornerRadius
                        useLargeArc: false
                        direction: PathArc.Clockwise
                    }
                    PathLine {
                        x: ShellGeometry.frameBorderInset; y: ShellGeometry.frameBorderInset + ShellGeometry.cornerRadius
                    }
                    PathArc {
                        x: ShellGeometry.frameBorderInset + ShellGeometry.cornerRadius; y: ShellGeometry.frameBorderInset
                        radiusX: ShellGeometry.cornerRadius; radiusY: ShellGeometry.cornerRadius
                        useLargeArc: false
                        direction: PathArc.Clockwise
                    }
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

                BackgroundEffect.blurRegion: Region {
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
                }
                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                color: "transparent"
                surfaceFormat.opaque: false

                // Liquid glass backdrop for the ring frame.
                // Same architecture as LiquidGlassSurface: wallpaper rendered internally,
                // blurred via MultiEffect, then ring_glass.frag clips to the ring frame
                // shape via an inner-boundary SDF and applies lensing at the inner edge.
                Item {
                    anchors.fill: parent
                    visible: ShellTheme.isLiquidGlass

                    // Source wallpaper scene: NOT marked visible:false so Qt renders it
                    // into the ShaderEffectSource texture. hideSource:true on the
                    // ShaderEffectSource prevents it from appearing directly in the scene.
                    Item {
                        id: ringWallpaperScene
                        width: window.width
                        height: window.height

                        Rectangle {
                            anchors.fill: parent
                            color: WallpaperState.fallbackColor
                        }
                        Image {
                            anchors.fill: parent
                            source: WallpaperState.source
                            visible: WallpaperState.hasWallpaper
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(ringWallpaperScene.width, ringWallpaperScene.height)
                            smooth: true
                            mipmap: true
                            asynchronous: true
                            cache: true
                        }
                    }

                    ShaderEffectSource {
                        id: ringWallpaperSource
                        width: window.width
                        height: window.height
                        sourceItem: ringWallpaperScene
                        hideSource: true
                        live: true
                        recursive: false
                        mipmap: true
                        visible: false
                    }

                    Item {
                        id: ringBlurredHolder
                        anchors.fill: parent
                        layer.enabled: true
                        layer.smooth: true
                        layer.effect: ShaderEffect {
                            property real surfaceWidth: ringBlurredHolder.width
                            property real surfaceHeight: ringBlurredHolder.height
                            property real frameInset: ShellGeometry.frameInset
                            property real cornerRadius: ShellGeometry.cornerRadius
                            property real edgeWidth: ShellTheme.liquidEdgeWidth
                            property real lensingStrength: ShellTheme.liquidLensingStrength
                            property real aberrationStrength: ShellTheme.liquidAberrationStrength
                            property real clockLeft: window.clockNotchLeft
                            property real clockRight: window.clockNotchRight
                            property real clockBottom: window.clockNotchBottom
                            property real clockRadius: window.clockNotchRadius
                            property real dockLeft: window.dockSlopeStartLeft
                            property real dockRight: window.dockSlopeStartRight
                            property real dockTopY: window.dockPeakY
                            property real dockTopFlatLeft: window.dockTopFlatLeft
                            property real dockTopFlatRight: window.dockTopFlatRight
                            property real dockCurveRun: window.dockCurveRun
                            property real homeLeft: window.homePanelShapeLeft
                            property real homeRight: window.homePanelShapeRight
                            property real homeTop: window.homePanelShapeTop
                            property real homeBottom: window.homePanelShapeBottom
                            property real homeShoulderInset: window.homePanelShoulderInset

                            fragmentShader: Qt.resolvedUrl("../shaders/ring_glass.frag.qsb")
                        }

                        MultiEffect {
                            anchors.fill: parent
                            source: ringWallpaperSource
                            autoPaddingEnabled: false
                            blurEnabled: true
                            blurMax: ShellTheme.liquidBlurMax
                            blur: ShellTheme.liquidBlurAmount
                            saturation: ShellTheme.liquidSaturation
                            brightness: ShellTheme.liquidBrightness
                        }
                    }
                }

                Shape {
                    anchors.fill: parent

                    ShapePath {
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

                        startX: 0; startY: 0
                        PathLine {
                            x: window.width; y: 0
                        }
                        PathLine {
                            x: window.width; y: window.height
                        }
                        PathLine {
                            x: 0; y: window.height
                        }
                        PathLine {
                            x: 0; y: 0
                        }

                        PathMove {
                            x: ShellGeometry.frameInset + ShellGeometry.cornerRadius; y: ShellGeometry.frameInset
                        }
                        PathLine {
                            x: window.clockNotchLeft; y: ShellGeometry.frameInset
                        }
                        PathCubic {
                            x: window.clockNotchLeft + window.clockNotchRadius; y: window.clockNotchBottom
                            control1X: window.clockNotchLeft + (window.clockNotchRadius * 0.55); control1Y: ShellGeometry.frameInset
                            control2X: window.clockNotchLeft; control2Y: window.clockNotchBottom - (window.clockNotchRadius * 0.55)
                        }
                        PathLine {
                            x: window.clockNotchRight - window.clockNotchRadius; y: window.clockNotchBottom
                        }
                        PathCubic {
                            x: window.clockNotchRight; y: ShellGeometry.frameInset
                            control1X: window.clockNotchRight; control1Y: window.clockNotchBottom - (window.clockNotchRadius * 0.55)
                            control2X: window.clockNotchRight - (window.clockNotchRadius * 0.55); control2Y: ShellGeometry.frameInset
                        }
                        PathLine {
                            x: window.width - ShellGeometry.frameInset - ShellGeometry.cornerRadius; y: ShellGeometry.frameInset
                        }
                        PathArc {
                            x: window.width - ShellGeometry.frameInset; y: ShellGeometry.frameInset + ShellGeometry.cornerRadius
                            radiusX: ShellGeometry.cornerRadius; radiusY: ShellGeometry.cornerRadius
                            useLargeArc: false
                            direction: PathArc.Clockwise
                        }
                        PathLine {
                            x: window.homePanelShapeRight; y: window.homePanelShapeTop
                        }
                        PathCubic {
                            x: window.homePanelShapeLeft; y: window.homePanelShapeTop + window.homePanelShoulderInset
                            control1X: window.homePanelShapeRight; control1Y: window.homePanelShapeTop + (window.homePanelShoulderInset * 0.45)
                            control2X: window.homePanelShapeLeft; control2Y: window.homePanelShapeTop + (window.homePanelShoulderInset * 0.55)
                        }
                        PathLine {
                            x: window.homePanelShapeLeft; y: window.homePanelShapeBottom - window.homePanelShoulderInset
                        }
                        PathCubic {
                            x: window.homePanelShapeRight; y: window.homePanelShapeBottom
                            control1X: window.homePanelShapeLeft; control1Y: window.homePanelShapeBottom - (window.homePanelShoulderInset * 0.55)
                            control2X: window.homePanelShapeRight; control2Y: window.homePanelShapeBottom - (window.homePanelShoulderInset * 0.45)
                        }
                        PathLine {
                            x: window.innerRight; y: window.innerBottom - ShellGeometry.cornerRadius
                        }
                        PathArc {
                            x: window.innerRight - ShellGeometry.cornerRadius; y: window.innerBottom
                            radiusX: ShellGeometry.cornerRadius; radiusY: ShellGeometry.cornerRadius
                            useLargeArc: false
                            direction: PathArc.Clockwise
                        }
                        PathLine {
                            x: window.dockSlopeStartRight; y: window.innerBottom
                        }
                        PathCubic {
                            x: window.dockTopFlatRight; y: window.dockPeakY
                            control1X: window.dockSlopeStartRight - window.dockCurveRun; control1Y: window.innerBottom
                            control2X: window.dockTopFlatRight + (window.dockCurveRun * 0.55); control2Y: window.dockPeakY
                        }
                        PathLine {
                            x: window.dockTopFlatLeft; y: window.dockPeakY
                        }
                        PathCubic {
                            x: window.dockSlopeStartLeft; y: window.innerBottom
                            control1X: window.dockTopFlatLeft - (window.dockCurveRun * 0.55); control1Y: window.dockPeakY
                            control2X: window.dockSlopeStartLeft + window.dockCurveRun; control2Y: window.innerBottom
                        }
                        PathLine {
                            x: window.innerLeft + ShellGeometry.cornerRadius; y: window.innerBottom
                        }
                        PathArc {
                            x: window.innerLeft; y: window.innerBottom - ShellGeometry.cornerRadius
                            radiusX: ShellGeometry.cornerRadius; radiusY: ShellGeometry.cornerRadius
                            useLargeArc: false
                            direction: PathArc.Clockwise
                        }
                        PathLine {
                            x: ShellGeometry.frameInset; y: ShellGeometry.frameInset + ShellGeometry.cornerRadius
                        }
                        PathArc {
                            x: ShellGeometry.frameInset + ShellGeometry.cornerRadius; y: ShellGeometry.frameInset
                            radiusX: ShellGeometry.cornerRadius; radiusY: ShellGeometry.cornerRadius
                            useLargeArc: false
                            direction: PathArc.Clockwise
                        }
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
                    opacity: 1 - Math.min(1, homePanel.revealProgress * 2.2)
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
