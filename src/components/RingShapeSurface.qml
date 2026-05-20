import QtQuick
import QtQuick.Shapes

import "../state"

Shape {
    id: root

    required property Item panels

    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    asynchronous: true

    component RingOutlinePath: RingSilhouettePath {
        required property Item panels
        property color outlineColor: "transparent"
        property real outlineWidth: 1
        property real outlineInset: 1

        geometry: panels.ringGeometry
        inset: outlineInset
        strokeColor: outlineColor
        strokeWidth: outlineWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
    }

    RingSilhouettePath {
        geometry: root.panels.ringGeometry
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
        outlineInset: 1.2
        outlineColor: ShellTheme.ringInnerNeonGlowOuter
        outlineWidth: ShellTheme.ringInnerNeonOuterWidth + (root.panels.morphingIntensity * 1.8)
    }

    RingOutlinePath {
        panels: root.panels
        outlineInset: 1
        outlineColor: ShellTheme.ringInnerNeonGlowMiddle
        outlineWidth: ShellTheme.ringInnerNeonMiddleWidth + (root.panels.morphingIntensity * 1.2)
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

    RingSilhouettePath {
        geometry: root.panels.ringGeometry
        inset: 0.5
        strokeColor: ShellTheme.panelBorderHighlight
        strokeWidth: ShellTheme.panelHighlightWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
    }

    RingOutlinePath {
        panels: root.panels
        outlineInset: 0.35
        outlineColor: ShellTheme.ringInnerNeonCore
        outlineWidth: ShellTheme.ringInnerNeonCoreWidth + (root.panels.morphingIntensity * 0.55)
    }

    RingOutlinePath {
        panels: root.panels
        outlineInset: -0.15
        outlineColor: ShellTheme.ringInnerNeonShine
        outlineWidth: ShellTheme.ringInnerNeonShineWidth
    }
}
