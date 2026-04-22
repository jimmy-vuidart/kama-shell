import Quickshell
import QtQuick
import QtQuick.Shapes
import Quickshell.Wayland

import "../state"

Variants {
    model: Quickshell.screens
    delegate: Component {
        PanelWindow {
            id: window
            required property var modelData
            screen: modelData
            WlrLayershell.layer: WlrLayershell.Overlay
            WlrLayershell.namespace: "kama-shell-ring"

            readonly property real innerLeft: ShellGeometry.frameInset
            readonly property real innerTop: ShellGeometry.frameInset
            readonly property real innerRight: window.width - ShellGeometry.frameInset
            readonly property real innerBottom: window.height - ShellGeometry.frameInset
            readonly property real dockShapeLeft: (window.width - dock.shapeWidth) / 2
            readonly property real dockShapeRight: dockShapeLeft + dock.shapeWidth
            readonly property real dockTop: window.height - ShellGeometry.frameInset - ShellGeometry.dockHeight
            readonly property real dockSlopeStartLeft: dockShapeLeft
            readonly property real dockSlopeStartRight: dockShapeRight
            readonly property real dockPeakY: dockTop + 2
            readonly property real dockFlatHalfWidth: Math.max(52, dock.bumpWidth * 0.32)
            readonly property real dockTopFlatLeft: (window.width / 2) - dockFlatHalfWidth
            readonly property real dockTopFlatRight: (window.width / 2) + dockFlatHalfWidth
            readonly property real dockCurveRun: Math.max(46, (dockSlopeStartRight - dockTopFlatRight) * 0.42)

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
                            x: window.width - ShellGeometry.frameInset
                            y: window.height - ShellGeometry.frameInset - ShellGeometry.cornerRadius
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

            Shape {
                anchors.fill: parent

                ShapePath {
                    fillGradient: LinearGradient {
                        x1: 0; y1: 0
                        x2: window.width; y2: window.height
                        GradientStop { position: 0.0; color: Qt.rgba(0.9, 0.95, 1, 0.005) }
                        GradientStop { position: 0.5; color: Qt.rgba(0.9, 0.95, 1, 0.005) }
                        GradientStop { position: 1.0; color: Qt.rgba(0.9, 0.95, 1, 0.005) }
                    }
                    strokeColor: "transparent"
                    strokeWidth: 0
                    fillRule: ShapePath.OddEvenFill

                    // Outer rectangle
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

                    // Inner cutout with rounded corners
                    // Top-left corner
                    PathMove {
                        x: ShellGeometry.frameInset + ShellGeometry.cornerRadius; y: ShellGeometry.frameInset
                    }
                    // Top-right corner
                    PathLine {
                        x: window.width - ShellGeometry.frameInset - ShellGeometry.cornerRadius; y: ShellGeometry.frameInset
                    }
                    PathArc {
                        x: window.width - ShellGeometry.frameInset; y: ShellGeometry.frameInset + ShellGeometry.cornerRadius
                        radiusX: ShellGeometry.cornerRadius; radiusY: ShellGeometry.cornerRadius
                        useLargeArc: false
                        direction: PathArc.Clockwise
                    }
                    // Bottom-right corner
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
                    // Top-left corner (closing)
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

                // Inner border for glass effect highlights
                ShapePath {
                    strokeColor: Qt.rgba(0.92, 0.96, 1, 0.5)
                    strokeWidth: 1.2
                    fillColor: "transparent"

                    PathMove {
                        x: ShellGeometry.frameBorderInset + ShellGeometry.cornerRadius; y: ShellGeometry.frameBorderInset
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

                // Additional specular highlight for physical edge
                ShapePath {
                    strokeColor: Qt.rgba(1, 1, 1, 0.4)
                    strokeWidth: 0.8
                    fillColor: "transparent"

                    PathMove {
                        x: ShellGeometry.frameInset + 0.5 + ShellGeometry.cornerRadius; y: ShellGeometry.frameInset + 0.5
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

            AppDock {
                id: dock
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: ShellGeometry.frameInset
                }
            }
        }
    }
}
