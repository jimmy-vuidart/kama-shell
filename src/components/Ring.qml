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

            WorkAreaReserve {
                targetScreen: root.modelData
                windowNamespace: "kama-shell-workarea-top"
                reserveSize: ShellGeometry.workAreaInset
                anchorTop: true
                anchorLeft: true
                anchorRight: true
            }

            WorkAreaReserve {
                targetScreen: root.modelData
                windowNamespace: "kama-shell-workarea-left"
                reserveSize: ShellGeometry.workAreaInset
                anchorTop: true
                anchorLeft: true
                anchorBottom: true
            }

            WorkAreaReserve {
                targetScreen: root.modelData
                windowNamespace: "kama-shell-workarea-right"
                reserveSize: ShellGeometry.workAreaInset
                anchorTop: true
                anchorRight: true
                anchorBottom: true
            }

            WorkAreaReserve {
                targetScreen: root.modelData
                windowNamespace: "kama-shell-workarea-bottom"
                reserveSize: ShellGeometry.workAreaInset
                anchorLeft: true
                anchorRight: true
                anchorBottom: true
            }

            PanelWindow {
                id: window
                screen: root.modelData
                WlrLayershell.layer: WlrLayershell.Overlay
                WlrLayershell.namespace: "kama-shell-ring"

                readonly property real innerLeft: ShellGeometry.frameInset
                readonly property real innerTop: ShellGeometry.frameInset
                readonly property real innerRight: window.width - ShellGeometry.frameInset
                readonly property real innerBottom: window.height - ShellGeometry.frameInset
                property bool dockShouldShow: dockHoverArea.containsMouse || dock.hovered || dock.contextMenuVisible
                property real dockReveal: dockShouldShow ? 1 : 0
                readonly property real dockRestCenter: window.width / 2
                readonly property real dockCurrentShapeWidth: ShellGeometry.dockRestWidth + ((dock.shapeWidth - ShellGeometry.dockRestWidth) * dockReveal)
                readonly property real dockCurrentHeight: ShellGeometry.dockRestHeight + ((ShellGeometry.dockHeight - ShellGeometry.dockRestHeight) * dockReveal)
                readonly property real dockShapeLeft: dockRestCenter - (dockCurrentShapeWidth / 2)
                readonly property real dockShapeRight: dockRestCenter + (dockCurrentShapeWidth / 2)
                readonly property real dockTop: window.height - ShellGeometry.frameInset - dockCurrentHeight
                readonly property real dockSlopeStartLeft: dockShapeLeft
                readonly property real dockSlopeStartRight: dockShapeRight
                readonly property real dockPeakY: dockTop + 2
                readonly property real dockFlatHalfWidth: (ShellGeometry.dockRestFlatWidth / 2) + ((Math.max(52, dock.bumpWidth * 0.32) - (ShellGeometry.dockRestFlatWidth / 2)) * dockReveal)
                readonly property real dockTopFlatLeft: (window.width / 2) - dockFlatHalfWidth
                readonly property real dockTopFlatRight: (window.width / 2) + dockFlatHalfWidth
                readonly property real dockCurveRun: Math.max(10, (dockSlopeStartRight - dockTopFlatRight) * 0.42)

                Behavior on dockReveal {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.InOutCubic
                    }
                }

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

                    Region {
                        item: dockContainer
                    }

                    Region {
                        item: dockHoverZone
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
                            x2: 0; y2: window.height
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, ShellGeometry.glassTopHighlightAlpha) }
                            GradientStop { position: 0.18; color: Qt.rgba(0.92, 0.98, 1, ShellGeometry.glassTintAlpha) }
                            GradientStop { position: 0.62; color: Qt.rgba(0.78, 0.86, 0.94, 0.13) }
                            GradientStop { position: 1.0; color: Qt.rgba(0.16, 0.19, 0.24, ShellGeometry.glassBottomShadeAlpha) }
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
                            x: window.width - ShellGeometry.frameInset - ShellGeometry.cornerRadius; y: ShellGeometry.frameInset
                        }
                        PathArc {
                            x: window.width - ShellGeometry.frameInset; y: ShellGeometry.frameInset + ShellGeometry.cornerRadius
                            radiusX: ShellGeometry.cornerRadius; radiusY: ShellGeometry.cornerRadius
                            useLargeArc: false
                            direction: PathArc.Clockwise
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

                    ShapePath {
                        strokeColor: Qt.rgba(0.92, 0.97, 1, ShellGeometry.glassBorderAlpha)
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

                    ShapePath {
                        strokeColor: Qt.rgba(1, 1, 1, ShellGeometry.glassInnerHighlightAlpha)
                        strokeWidth: 1
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

                    ShapePath {
                        strokeColor: Qt.rgba(0.05, 0.08, 0.12, 0.2)
                        strokeWidth: 1
                        fillColor: "transparent"

                        PathMove {
                            x: ShellGeometry.frameInset + ShellGeometry.cornerRadius; y: window.innerBottom - 0.5
                        }
                        PathLine {
                            x: window.dockSlopeStartLeft; y: window.innerBottom - 0.5
                        }
                        PathCubic {
                            x: window.dockTopFlatLeft; y: window.dockPeakY + 0.5
                            control1X: window.dockSlopeStartLeft + window.dockCurveRun; control1Y: window.innerBottom - 0.5
                            control2X: window.dockTopFlatLeft - (window.dockCurveRun * 0.55); control2Y: window.dockPeakY + 0.5
                        }
                        PathLine {
                            x: window.dockTopFlatRight; y: window.dockPeakY + 0.5
                        }
                        PathCubic {
                            x: window.dockSlopeStartRight; y: window.innerBottom - 0.5
                            control1X: window.dockTopFlatRight + (window.dockCurveRun * 0.55); control1Y: window.dockPeakY + 0.5
                            control2X: window.dockSlopeStartRight - window.dockCurveRun; control2Y: window.innerBottom - 0.5
                        }
                        PathLine {
                            x: window.innerRight - ShellGeometry.cornerRadius; y: window.innerBottom - 0.5
                        }
                    }
                }

                Item {
                    id: dockContainer
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: ShellGeometry.frameInset
                    }
                    width: dock.implicitWidth
                    height: dock.implicitHeight * window.dockReveal
                    clip: true

                    AppDock {
                        id: dock
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            bottom: parent.bottom
                        }
                        revealProgress: window.dockReveal
                    }
                }

                Item {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: ShellGeometry.frameInset + 3
                    }
                    width: ShellGeometry.dockRestWidth - 18
                    height: ShellGeometry.dockRestHeight - 6
                    opacity: 1 - window.dockReveal
                    visible: opacity > 0

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
                                color: Qt.rgba(0.95, 0.98, 1, 0.88)
                            }
                        }
                    }
                }

                Item {
                    id: dockHoverZone

                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: 0
                    }
                    width: Math.max(dock.shapeWidth, ShellGeometry.dockMinWidth + 72)
                    height: ShellGeometry.frameInset + ShellGeometry.dockHoverZoneHeight

                    MouseArea {
                        id: dockHoverArea
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: true
                    }
                }
            }
        }
    }
}
