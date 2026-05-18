import QtQuick
import QtQuick.Shapes

// ShapePath réutilisable qui dessine la silhouette intérieure du ring
// (top edge, clock notch, status notch, upper-right arc, right edge, home panel,
// lower-right arc, dock bump, lower-left arc, left edge, upper-left arc).
//
// La même silhouette est définie en JavaScript par `RingPath` (singleton),
// que `RingBlurRegion` consomme. Toute évolution géométrique (notch
// supplémentaire, panneau additionnel) doit modifier les deux endroits
// pour rester cohérente.
//
// Modes:
//  - `withOuterRectangle: false` (défaut) — dessine uniquement le contour
//    intérieur. Adapté aux strokes (outlines) et au mask (fillColor opaque).
//  - `withOuterRectangle: true` — précède le contour intérieur d'un rectangle
//    plein de taille (outerWidth × outerHeight). Combiné à
//    `fillRule: ShapePath.OddEvenFill`, le contour intérieur est carved out
//    du rectangle, ce qui produit le fill du décor du ring.
//
// `inset: real` décale uniformément la silhouette vers l'extérieur du décor
// (= rétrécit le trou intérieur de `inset` pixels). Utilisé pour positionner
// les outlines à 1 px ou 0.5 px à l'intérieur du contour de fill.
ShapePath {
    id: root

    property real innerLeft: 0
    property real innerTop: 0
    property real innerRight: 0
    property real innerBottom: 0
    property real cornerRadius: 0

    property real clockNotchLeft: 0
    property real clockNotchRight: 0
    property real clockNotchBottom: 0
    property real clockNotchRadius: 0

    property real statusNotchLeft: 0
    property real statusNotchRight: 0
    property real statusNotchBottom: 0
    property real statusNotchRadius: 0

    property real dockSlopeStartLeft: 0
    property real dockSlopeStartRight: 0
    property real dockTopFlatLeft: 0
    property real dockTopFlatRight: 0
    property real dockPeakY: 0
    property real dockCurveRun: 0

    property real homePanelShapeLeft: 0
    property real homePanelShapeRight: 0
    property real homePanelShapeTop: 0
    property real homePanelShapeBottom: 0
    property real homePanelShapeRadius: 0

    property real inset: 0

    property bool withOuterRectangle: false
    property real outerWidth: 0
    property real outerHeight: 0

    // Coordonnées effectives, inset appliqué de manière cohérente vers
    // l'intérieur du décor (= vers l'extérieur du trou).
    readonly property real effLeft: innerLeft + inset
    readonly property real effTop: innerTop + inset
    readonly property real effRight: innerRight - inset
    readonly property real effBottom: innerBottom - inset
    readonly property real effClockLeft: clockNotchLeft + inset
    readonly property real effClockRight: clockNotchRight - inset
    readonly property real effClockBottom: clockNotchBottom - inset
    readonly property real effStatusLeft: statusNotchLeft + inset
    readonly property real effStatusRight: statusNotchRight - inset
    readonly property real effStatusBottom: statusNotchBottom - inset
    readonly property real effDockSlopeLeft: dockSlopeStartLeft + inset
    readonly property real effDockSlopeRight: dockSlopeStartRight - inset
    readonly property real effDockTopFlatLeft: dockTopFlatLeft + inset
    readonly property real effDockTopFlatRight: dockTopFlatRight - inset
    readonly property real effDockPeakY: dockPeakY + inset
    readonly property real effHomeLeft: homePanelShapeLeft + inset
    readonly property real effHomeRight: homePanelShapeRight - inset
    readonly property real effHomeTop: homePanelShapeTop + inset
    readonly property real effHomeBottom: homePanelShapeBottom - inset

    // Bézier control offsets (≈ quart de cercle)
    readonly property real notchControlOffset: clockNotchRadius * 0.55
    readonly property real statusControlOffset: statusNotchRadius * 0.55
    readonly property real homeControlOffset: homePanelShapeRadius * 0.45

    // Point de départ du contour intérieur (juste après l'arc supérieur gauche).
    readonly property real silStartX: effLeft + cornerRadius
    readonly property real silStartY: effTop

    // Coordonnées du rectangle extérieur. En mode non-rect, on dégénère sur
    // (silStartX, silStartY) pour produire 4 PathLine de longueur nulle qui
    // n'introduisent ni stroke ni fill parasite.
    readonly property real outerXMax: withOuterRectangle ? outerWidth : silStartX
    readonly property real outerXMin: withOuterRectangle ? 0 : silStartX
    readonly property real outerYMax: withOuterRectangle ? outerHeight : silStartY
    readonly property real outerYMin: withOuterRectangle ? 0 : silStartY

    startX: outerXMin
    startY: outerYMin

    // --- Sub-path 1: rectangle extérieur (ou dégénéré en mode contour seul) ---
    PathLine { x: root.outerXMax; y: root.outerYMin }
    PathLine { x: root.outerXMax; y: root.outerYMax }
    PathLine { x: root.outerXMin; y: root.outerYMax }
    PathLine { x: root.outerXMin; y: root.outerYMin }

    // --- Sub-path 2: contour intérieur (silhouette du ring) ---
    PathMove { x: root.silStartX; y: root.silStartY }

    // Top edge → clock notch
    PathLine { x: root.effClockLeft; y: root.effTop }
    PathCubic {
        x: root.effClockLeft + root.clockNotchRadius; y: root.effClockBottom
        control1X: root.effClockLeft + root.notchControlOffset; control1Y: root.effTop
        control2X: root.effClockLeft; control2Y: root.effClockBottom - root.notchControlOffset
    }
    PathLine { x: root.effClockRight - root.clockNotchRadius; y: root.effClockBottom }
    PathCubic {
        x: root.effClockRight; y: root.effTop
        control1X: root.effClockRight; control1Y: root.effClockBottom - root.notchControlOffset
        control2X: root.effClockRight - root.notchControlOffset; control2Y: root.effTop
    }
    PathLine { x: root.effStatusLeft; y: root.effTop }
    PathCubic {
        x: root.effStatusLeft + root.statusNotchRadius; y: root.effStatusBottom
        control1X: root.effStatusLeft + root.statusControlOffset; control1Y: root.effTop
        control2X: root.effStatusLeft; control2Y: root.effStatusBottom - root.statusControlOffset
    }
    PathLine { x: root.effStatusRight - root.statusNotchRadius; y: root.effStatusBottom }
    PathCubic {
        x: root.effStatusRight; y: root.effTop
        control1X: root.effStatusRight; control1Y: root.effStatusBottom - root.statusControlOffset
        control2X: root.effStatusRight - root.statusControlOffset; control2Y: root.effTop
    }
    PathLine { x: root.effRight - root.cornerRadius; y: root.effTop }

    // Upper-right arc
    PathArc {
        x: root.effRight; y: root.effTop + root.cornerRadius
        radiusX: root.cornerRadius; radiusY: root.cornerRadius
        useLargeArc: false
        direction: PathArc.Clockwise
    }

    // Right edge → home panel évidement
    PathLine { x: root.effHomeRight; y: root.effHomeTop }
    PathLine { x: root.effHomeLeft + root.homePanelShapeRadius; y: root.effHomeTop }
    PathCubic {
        x: root.effHomeLeft; y: root.effHomeTop + root.homePanelShapeRadius
        control1X: root.effHomeLeft + root.homeControlOffset; control1Y: root.effHomeTop
        control2X: root.effHomeLeft; control2Y: root.effHomeTop + root.homeControlOffset
    }
    PathLine { x: root.effHomeLeft; y: root.effHomeBottom - root.homePanelShapeRadius }
    PathCubic {
        x: root.effHomeLeft + root.homePanelShapeRadius; y: root.effHomeBottom
        control1X: root.effHomeLeft; control1Y: root.effHomeBottom - root.homeControlOffset
        control2X: root.effHomeLeft + root.homeControlOffset; control2Y: root.effHomeBottom
    }
    PathLine { x: root.effHomeRight; y: root.effHomeBottom }

    // Right edge → lower-right arc
    PathLine { x: root.effRight; y: root.effBottom - root.cornerRadius }
    PathArc {
        x: root.effRight - root.cornerRadius; y: root.effBottom
        radiusX: root.cornerRadius; radiusY: root.cornerRadius
        useLargeArc: false
        direction: PathArc.Clockwise
    }

    // Bottom edge with dock bump
    PathLine { x: root.effDockSlopeRight; y: root.effBottom }
    PathCubic {
        x: root.effDockTopFlatRight; y: root.effDockPeakY
        control1X: root.effDockSlopeRight - root.dockCurveRun; control1Y: root.effBottom
        control2X: root.effDockTopFlatRight + (root.dockCurveRun * 0.55); control2Y: root.effDockPeakY
    }
    PathLine { x: root.effDockTopFlatLeft; y: root.effDockPeakY }
    PathCubic {
        x: root.effDockSlopeLeft; y: root.effBottom
        control1X: root.effDockTopFlatLeft - (root.dockCurveRun * 0.55); control1Y: root.effDockPeakY
        control2X: root.effDockSlopeLeft + root.dockCurveRun; control2Y: root.effBottom
    }
    PathLine { x: root.effLeft + root.cornerRadius; y: root.effBottom }

    // Lower-left arc
    PathArc {
        x: root.effLeft; y: root.effBottom - root.cornerRadius
        radiusX: root.cornerRadius; radiusY: root.cornerRadius
        useLargeArc: false
        direction: PathArc.Clockwise
    }

    // Left edge up
    PathLine { x: root.effLeft; y: root.effTop + root.cornerRadius }

    // Upper-left arc (closes back to silStart)
    PathArc {
        x: root.effLeft + root.cornerRadius; y: root.effTop
        radiusX: root.cornerRadius; radiusY: root.cornerRadius
        useLargeArc: false
        direction: PathArc.Clockwise
    }
}
