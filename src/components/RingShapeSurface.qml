import QtQuick
import QtQuick.Shapes

import "../state"

Shape {
    id: root

    required property Item panels

    anchors.fill: parent

    component RingOutlinePath: RingSilhouettePath {
        required property Item panels
        property color outlineColor: "transparent"
        property real outlineWidth: 1

        innerLeft: panels.innerLeft
        innerTop: panels.innerTop
        innerRight: panels.innerRight
        innerBottom: panels.innerBottom
        cornerRadius: ShellGeometry.cornerRadius
        clockNotchLeft: panels.clockNotchLeft
        clockNotchRight: panels.clockNotchRight
        clockNotchBottom: panels.clockNotchBottom
        clockNotchRadius: panels.clockNotchRadius
        statusNotchLeft: panels.statusNotchLeft
        statusNotchRight: panels.statusNotchRight
        statusNotchBottom: panels.statusNotchBottom
        statusNotchRadius: panels.statusNotchRadius
        dockSlopeStartLeft: panels.dockSlopeStartLeft
        dockSlopeStartRight: panels.dockSlopeStartRight
        dockTopFlatLeft: panels.dockTopFlatLeft
        dockTopFlatRight: panels.dockTopFlatRight
        dockPeakY: panels.dockPeakY
        dockCurveRun: panels.dockCurveRun
        homePanelShapeLeft: panels.homePanelShapeLeft
        homePanelShapeRight: panels.homePanelShapeRight
        homePanelShapeTop: panels.homePanelShapeTop
        homePanelShapeBottom: panels.homePanelShapeBottom
        homePanelShapeRadius: panels.homePanelShapeRadius
        homePanelCurveRun: panels.homePanelCurveRun
        inset: 1
        strokeColor: outlineColor
        strokeWidth: outlineWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
    }

    RingSilhouettePath {
        innerLeft: root.panels.innerLeft
        innerTop: root.panels.innerTop
        innerRight: root.panels.innerRight
        innerBottom: root.panels.innerBottom
        cornerRadius: ShellGeometry.cornerRadius
        clockNotchLeft: root.panels.clockNotchLeft
        clockNotchRight: root.panels.clockNotchRight
        clockNotchBottom: root.panels.clockNotchBottom
        clockNotchRadius: root.panels.clockNotchRadius
        statusNotchLeft: root.panels.statusNotchLeft
        statusNotchRight: root.panels.statusNotchRight
        statusNotchBottom: root.panels.statusNotchBottom
        statusNotchRadius: root.panels.statusNotchRadius
        dockSlopeStartLeft: root.panels.dockSlopeStartLeft
        dockSlopeStartRight: root.panels.dockSlopeStartRight
        dockTopFlatLeft: root.panels.dockTopFlatLeft
        dockTopFlatRight: root.panels.dockTopFlatRight
        dockPeakY: root.panels.dockPeakY
        dockCurveRun: root.panels.dockCurveRun
        homePanelShapeLeft: root.panels.homePanelShapeLeft
        homePanelShapeRight: root.panels.homePanelShapeRight
        homePanelShapeTop: root.panels.homePanelShapeTop
        homePanelShapeBottom: root.panels.homePanelShapeBottom
        homePanelShapeRadius: root.panels.homePanelShapeRadius
        homePanelCurveRun: root.panels.homePanelCurveRun
        withOuterRectangle: true
        outerWidth: root.width
        outerHeight: root.height
        fillGradient: LinearGradient {
            x1: 0; y1: 0
            x2: 0; y2: root.height
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
        panels: root.panels
        outlineColor: ShellTheme.panelBorderSupport
        outlineWidth: ShellTheme.panelBorderSupportWidth + (root.panels.morphingIntensity * 0.8)
    }

    RingOutlinePath {
        panels: root.panels
        outlineColor: ShellTheme.panelBorder
        outlineWidth: ShellTheme.panelBorderWidth + (root.panels.morphingIntensity * 1.4)
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
            x: root.panels.clockNotchLeft + 0.5; y: ShellGeometry.frameInset + 0.5
        }
        PathCubic {
            x: root.panels.clockNotchLeft + root.panels.clockNotchRadius; y: root.panels.clockNotchBottom - 0.5
            control1X: root.panels.clockNotchLeft + 0.5 + (root.panels.clockNotchRadius * 0.55); control1Y: ShellGeometry.frameInset + 0.5
            control2X: root.panels.clockNotchLeft + 0.5; control2Y: root.panels.clockNotchBottom - 0.5 - (root.panels.clockNotchRadius * 0.55)
        }
        PathLine {
            x: root.panels.clockNotchRight - root.panels.clockNotchRadius; y: root.panels.clockNotchBottom - 0.5
        }
        PathCubic {
            x: root.panels.clockNotchRight - 0.5; y: ShellGeometry.frameInset + 0.5
            control1X: root.panels.clockNotchRight - 0.5; control1Y: root.panels.clockNotchBottom - 0.5 - (root.panels.clockNotchRadius * 0.55)
            control2X: root.panels.clockNotchRight - 0.5 - (root.panels.clockNotchRadius * 0.55); control2Y: ShellGeometry.frameInset + 0.5
        }
        PathLine {
            x: root.panels.statusNotchLeft + 0.5; y: ShellGeometry.frameInset + 0.5
        }
        PathCubic {
            x: root.panels.statusNotchLeft + root.panels.statusNotchRadius; y: root.panels.statusNotchBottom - 0.5
            control1X: root.panels.statusNotchLeft + 0.5 + (root.panels.statusNotchRadius * 0.55); control1Y: ShellGeometry.frameInset + 0.5
            control2X: root.panels.statusNotchLeft + 0.5; control2Y: root.panels.statusNotchBottom - 0.5 - (root.panels.statusNotchRadius * 0.55)
        }
        PathLine {
            x: root.panels.statusNotchRight - root.panels.statusNotchRadius; y: root.panels.statusNotchBottom - 0.5
        }
        PathCubic {
            x: root.panels.statusNotchRight - 0.5; y: ShellGeometry.frameInset + 0.5
            control1X: root.panels.statusNotchRight - 0.5; control1Y: root.panels.statusNotchBottom - 0.5 - (root.panels.statusNotchRadius * 0.55)
            control2X: root.panels.statusNotchRight - 0.5 - (root.panels.statusNotchRadius * 0.55); control2Y: ShellGeometry.frameInset + 0.5
        }
        PathLine {
            x: root.width - ShellGeometry.frameInset - 0.5 - ShellGeometry.cornerRadius; y: ShellGeometry.frameInset + 0.5
        }
        PathArc {
            x: root.width - ShellGeometry.frameInset - 0.5; y: ShellGeometry.frameInset + 0.5 + ShellGeometry.cornerRadius
            radiusX: ShellGeometry.cornerRadius; radiusY: ShellGeometry.cornerRadius
            useLargeArc: false
            direction: PathArc.Clockwise
        }
    }
}
