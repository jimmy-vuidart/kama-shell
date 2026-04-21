import Quickshell
import QtQuick
import QtQuick.Shapes
import Quickshell.Wayland

Variants {
    model: Quickshell.screens
    delegate: Component {
        PanelWindow {
            id: window
            screen: modelData
            WlrLayershell.layer: WlrLayershell.Overlay
            WlrLayershell.namespace: "kama-shell-ring"

            mask: Region {
                width: window.width
                height: window.height

                Region {
                    width: window.width
                    height: window.height
                }

                Region {
                    item: Rectangle {
                        x: 32
                        y: 32
                        width: window.width - 64
                        height: window.height - 64
                        radius: window.cornerRadius
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
                    item: Rectangle {
                        x: 32
                        y: 32
                        width: window.width - 64
                        height: window.height - 64
                        radius: window.cornerRadius
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

            readonly property int cornerRadius: 48

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
                        x: 32 + window.cornerRadius; y: 32
                    }
                    // Top-right corner
                    PathLine {
                        x: window.width - 32 - window.cornerRadius; y: 32
                    }
                    PathArc {
                        x: window.width - 32; y: 32 + window.cornerRadius
                        radiusX: window.cornerRadius; radiusY: window.cornerRadius
                        useLargeArc: false
                        direction: PathArc.Clockwise
                    }
                    // Bottom-right corner
                    PathLine {
                        x: window.width - 32; y: window.height - 32 - window.cornerRadius
                    }
                    PathArc {
                        x: window.width - 32 - window.cornerRadius; y: window.height - 32
                        radiusX: window.cornerRadius; radiusY: window.cornerRadius
                        useLargeArc: false
                        direction: PathArc.Clockwise
                    }
                    // Bottom-left corner
                    PathLine {
                        x: 32 + window.cornerRadius; y: window.height - 32
                    }
                    PathArc {
                        x: 32; y: window.height - 32 - window.cornerRadius
                        radiusX: window.cornerRadius; radiusY: window.cornerRadius
                        useLargeArc: false
                        direction: PathArc.Clockwise
                    }
                    // Top-left corner (closing)
                    PathLine {
                        x: 32; y: 32 + window.cornerRadius
                    }
                    PathArc {
                        x: 32 + window.cornerRadius; y: 32
                        radiusX: window.cornerRadius; radiusY: window.cornerRadius
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
                        x: 33 + window.cornerRadius; y: 33
                    }
                    PathLine {
                        x: window.width - 33 - window.cornerRadius; y: 33
                    }
                    PathArc {
                        x: window.width - 33; y: 33 + window.cornerRadius
                        radiusX: window.cornerRadius; radiusY: window.cornerRadius
                        useLargeArc: false
                        direction: PathArc.Clockwise
                    }
                    PathLine {
                        x: window.width - 33; y: window.height - 33 - window.cornerRadius
                    }
                    PathArc {
                        x: window.width - 33 - window.cornerRadius; y: window.height - 33
                        radiusX: window.cornerRadius; radiusY: window.cornerRadius
                        useLargeArc: false
                        direction: PathArc.Clockwise
                    }
                    PathLine {
                        x: 33 + window.cornerRadius; y: window.height - 33
                    }
                    PathArc {
                        x: 33; y: window.height - 33 - window.cornerRadius
                        radiusX: window.cornerRadius; radiusY: window.cornerRadius
                        useLargeArc: false
                        direction: PathArc.Clockwise
                    }
                    PathLine {
                        x: 33; y: 33 + window.cornerRadius
                    }
                    PathArc {
                        x: 33 + window.cornerRadius; y: 33
                        radiusX: window.cornerRadius; radiusY: window.cornerRadius
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
                        x: 32.5 + window.cornerRadius; y: 32.5
                    }
                    PathLine {
                        x: window.width - 32.5 - window.cornerRadius; y: 32.5
                    }
                    PathArc {
                        x: window.width - 32.5; y: 32.5 + window.cornerRadius
                        radiusX: window.cornerRadius; radiusY: window.cornerRadius
                        useLargeArc: false
                        direction: PathArc.Clockwise
                    }
                }
            }
        }
    }
}