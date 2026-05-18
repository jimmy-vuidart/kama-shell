pragma Singleton

import Quickshell
import QtQuick

// Source de vérité pour la silhouette intérieure du ring.
//
// `RingSilhouettePath.qml` (composant ShapePath réutilisable) dessine cette
// même forme côté GPU; `RingBlurRegion.qml` la consomme côté CPU pour
// produire son `BackgroundEffect.blurRegion`. Toute évolution géométrique
// du ring (notch supplémentaire, panneau additionnel) se fait ici et dans
// `RingSilhouettePath.qml` — plus jamais dans 6 endroits différents.
Singleton {
    id: root

    // Facteur Bézier qui approxime un quart de cercle (≈ (4/3) * tan(π/8)).
    // Utilisé pour les coins concaves de la notch d'horloge.
    readonly property real cubicNotchFactor: 0.55

    // Variante plus serrée pour les coins du HomePanel.
    readonly property real cubicHomeFactor: 0.45

    function line(x1, y1, x2, y2) {
        return { kind: "line", x1: x1, y1: y1, x2: x2, y2: y2 }
    }

    function cubic(x0, y0, x1, y1, x2, y2, x3, y3) {
        return {
            kind: "cubic",
            x0: x0, y0: y0,
            x1: x1, y1: y1,
            x2: x2, y2: y2,
            x3: x3, y3: y3
        }
    }

    function arc(cx, cy, radius, side, yMin, yMax) {
        return {
            kind: "arc",
            cx: cx, cy: cy,
            radius: radius, side: side,
            yMin: yMin, yMax: yMax
        }
    }

    // Construit la liste ordonnée de segments fermant la silhouette intérieure
    // du ring. `g` doit contenir les champs scalaires suivants:
    //   innerLeft, innerTop, innerRight, innerBottom, cornerRadius
    //   clockNotchLeft, clockNotchRight, clockNotchBottom, clockNotchRadius
    //   dockSlopeStartLeft, dockSlopeStartRight,
    //   dockTopFlatLeft, dockTopFlatRight, dockPeakY, dockCurveRun
    //   homePanelShapeLeft, homePanelShapeRight,
    //   homePanelShapeTop, homePanelShapeBottom, homePanelShapeRadius
    //
    // Le tracé démarre au coin supérieur gauche (juste après l'arc) et se
    // referme à ce même point après avoir parcouru: top edge, clock notch,
    // upper-right arc, right edge, home panel évidement, lower-right arc,
    // bottom edge avec dock, lower-left arc, left edge, upper-left arc.
    function buildInnerSegments(g) {
        const left = g.innerLeft
        const top = g.innerTop
        const right = g.innerRight
        const bottom = g.innerBottom
        const r = g.cornerRadius
        const notchK = g.clockNotchRadius * cubicNotchFactor
        const homeK = g.homePanelShapeRadius * cubicHomeFactor

        return [
            // Top edge: upper-left arc end → clock notch entry
            line(left + r, top, g.clockNotchLeft, top),

            // Clock notch: descend
            cubic(
                g.clockNotchLeft, top,
                g.clockNotchLeft + notchK, top,
                g.clockNotchLeft, g.clockNotchBottom - notchK,
                g.clockNotchLeft + g.clockNotchRadius, g.clockNotchBottom
            ),
            line(
                g.clockNotchLeft + g.clockNotchRadius, g.clockNotchBottom,
                g.clockNotchRight - g.clockNotchRadius, g.clockNotchBottom
            ),
            cubic(
                g.clockNotchRight - g.clockNotchRadius, g.clockNotchBottom,
                g.clockNotchRight, g.clockNotchBottom - notchK,
                g.clockNotchRight - notchK, top,
                g.clockNotchRight, top
            ),

            // Top edge: clock notch exit → upper-right arc start
            line(g.clockNotchRight, top, right - r, top),
            arc(right - r, top + r, r, 1, top, top + r),

            // Right edge: down to home panel top
            line(right, top + r, g.homePanelShapeRight, g.homePanelShapeTop),

            // Home panel évidement (rectangle arrondi creusé depuis la droite)
            line(
                g.homePanelShapeRight, g.homePanelShapeTop,
                g.homePanelShapeLeft + g.homePanelShapeRadius, g.homePanelShapeTop
            ),
            cubic(
                g.homePanelShapeLeft + g.homePanelShapeRadius, g.homePanelShapeTop,
                g.homePanelShapeLeft + homeK, g.homePanelShapeTop,
                g.homePanelShapeLeft, g.homePanelShapeTop + homeK,
                g.homePanelShapeLeft, g.homePanelShapeTop + g.homePanelShapeRadius
            ),
            line(
                g.homePanelShapeLeft, g.homePanelShapeTop + g.homePanelShapeRadius,
                g.homePanelShapeLeft, g.homePanelShapeBottom - g.homePanelShapeRadius
            ),
            cubic(
                g.homePanelShapeLeft, g.homePanelShapeBottom - g.homePanelShapeRadius,
                g.homePanelShapeLeft, g.homePanelShapeBottom - homeK,
                g.homePanelShapeLeft + homeK, g.homePanelShapeBottom,
                g.homePanelShapeLeft + g.homePanelShapeRadius, g.homePanelShapeBottom
            ),
            line(
                g.homePanelShapeLeft + g.homePanelShapeRadius, g.homePanelShapeBottom,
                g.homePanelShapeRight, g.homePanelShapeBottom
            ),

            // Right edge: down from home panel → lower-right arc
            line(g.homePanelShapeRight, g.homePanelShapeBottom, right, bottom - r),
            arc(right - r, bottom - r, r, 1, bottom - r, bottom),

            // Bottom edge: lower-right arc end → dock right slope
            line(right - r, bottom, g.dockSlopeStartRight, bottom),

            // Dock bump (right slope, top flat, left slope)
            cubic(
                g.dockSlopeStartRight, bottom,
                g.dockSlopeStartRight - g.dockCurveRun, bottom,
                g.dockTopFlatRight + (g.dockCurveRun * cubicNotchFactor), g.dockPeakY,
                g.dockTopFlatRight, g.dockPeakY
            ),
            line(g.dockTopFlatRight, g.dockPeakY, g.dockTopFlatLeft, g.dockPeakY),
            cubic(
                g.dockTopFlatLeft, g.dockPeakY,
                g.dockTopFlatLeft - (g.dockCurveRun * cubicNotchFactor), g.dockPeakY,
                g.dockSlopeStartLeft + g.dockCurveRun, bottom,
                g.dockSlopeStartLeft, bottom
            ),

            // Bottom edge: dock left slope → lower-left arc
            line(g.dockSlopeStartLeft, bottom, left + r, bottom),
            arc(left + r, bottom - r, r, -1, bottom - r, bottom),

            // Left edge up
            line(left, bottom - r, left, top + r),

            // Upper-left arc (closes the loop)
            arc(left + r, top + r, r, -1, top, top + r)
        ]
    }
}
