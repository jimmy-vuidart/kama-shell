pragma Singleton

import Quickshell
import QtQuick

// Source de vérité pour la silhouette intérieure du ring.
//
// `RingSilhouettePath.qml` dessine cette même forme côté GPU depuis un path SVG;
// `RingBlurRegion.qml` consomme les segments CPU pour produire son
// `BackgroundEffect.blurRegion`. Toute évolution géométrique du ring se fait
// ici, jamais en recopiant des `PathLine` / `PathCubic` dans plusieurs fichiers.
Singleton {
    id: root

    // Facteur Bézier qui approxime un quart de cercle (≈ (4/3) * tan(π/8)).
    // Utilisé pour les coins concaves de la notch d'horloge.
    readonly property real cubicNotchFactor: 0.55

    // Courbes de bosse côté HomePanel, cohérentes avec le dock.
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

    function arc(cx, cy, radius, side, yMin, yMax, x2, y2) {
        return {
            kind: "arc",
            cx: cx, cy: cy,
            radius: radius, side: side,
            yMin: yMin, yMax: yMax,
            x2: x2, y2: y2
        }
    }

    function normalizeGeometry(sourceGeometry, options) {
        const source = sourceGeometry || {}
        const opts = options || {}

        if (source.frame && source.slots) {
            return root.geometryWithInset(source, opts.inset || 0)
        }

        return root.geometryWithInset({
            frame: {
                left: source.innerLeft || 0,
                top: source.innerTop || 0,
                right: source.innerRight || 0,
                bottom: source.innerBottom || 0,
                cornerRadius: source.cornerRadius || 0
            },
            slots: {
                clock: {
                    left: source.clockNotchLeft || 0,
                    right: source.clockNotchRight || 0,
                    bottom: source.clockNotchBottom || 0,
                    radius: source.clockNotchRadius || 0
                },
                status: {
                    left: source.statusNotchLeft || 0,
                    right: source.statusNotchRight || 0,
                    bottom: source.statusNotchBottom || 0,
                    radius: source.statusNotchRadius || 0
                },
                dock: {
                    slopeStartLeft: source.dockSlopeStartLeft || 0,
                    slopeStartRight: source.dockSlopeStartRight || 0,
                    topFlatLeft: source.dockTopFlatLeft || 0,
                    topFlatRight: source.dockTopFlatRight || 0,
                    peakY: source.dockPeakY || 0,
                    curveRun: source.dockCurveRun || 0
                },
                home: {
                    left: source.homePanelShapeLeft || 0,
                    right: source.homePanelShapeRight || 0,
                    top: source.homePanelShapeTop || 0,
                    bottom: source.homePanelShapeBottom || 0,
                    radius: source.homePanelShapeRadius || 0,
                    curveRun: source.homePanelCurveRun || 0
                }
            }
        }, opts.inset || 0)
    }

    function geometryWithInset(geometry, inset) {
        const g = geometry || {}
        const frame = g.frame || {}
        const slots = g.slots || {}
        const clock = slots.clock || {}
        const status = slots.status || {}
        const dock = slots.dock || {}
        const home = slots.home || {}
        const amount = Number(inset || 0)

        return {
            frame: {
                left: Number(frame.left || 0) + amount,
                top: Number(frame.top || 0) + amount,
                right: Number(frame.right || 0) - amount,
                bottom: Number(frame.bottom || 0) - amount,
                cornerRadius: Number(frame.cornerRadius || 0)
            },
            slots: {
                clock: {
                    left: Number(clock.left || 0) + amount,
                    right: Number(clock.right || 0) - amount,
                    bottom: Number(clock.bottom || 0) - amount,
                    radius: Number(clock.radius || 0)
                },
                status: {
                    left: Number(status.left || 0) + amount,
                    right: Number(status.right || 0) - amount,
                    bottom: Number(status.bottom || 0) - amount,
                    radius: Number(status.radius || 0)
                },
                dock: {
                    slopeStartLeft: Number(dock.slopeStartLeft || 0) + amount,
                    slopeStartRight: Number(dock.slopeStartRight || 0) - amount,
                    topFlatLeft: Number(dock.topFlatLeft || 0) + amount,
                    topFlatRight: Number(dock.topFlatRight || 0) - amount,
                    peakY: Number(dock.peakY || 0) + amount,
                    curveRun: Number(dock.curveRun || 0)
                },
                home: {
                    left: Number(home.left || 0) + amount,
                    right: Number(home.right || 0) - amount,
                    top: Number(home.top || 0) + amount,
                    bottom: Number(home.bottom || 0) - amount,
                    radius: Number(home.radius || 0),
                    curveRun: Math.max(1, Number(home.curveRun || home.radius || 1) - amount)
                }
            }
        }
    }

    function flatGeometry(sourceGeometry, options) {
        const geometry = root.normalizeGeometry(sourceGeometry, options)
        const frame = geometry.frame
        const slots = geometry.slots

        return {
            innerLeft: frame.left,
            innerTop: frame.top,
            innerRight: frame.right,
            innerBottom: frame.bottom,
            cornerRadius: frame.cornerRadius,
            clockNotchLeft: slots.clock.left,
            clockNotchRight: slots.clock.right,
            clockNotchBottom: slots.clock.bottom,
            clockNotchRadius: slots.clock.radius,
            statusNotchLeft: slots.status.left,
            statusNotchRight: slots.status.right,
            statusNotchBottom: slots.status.bottom,
            statusNotchRadius: slots.status.radius,
            dockSlopeStartLeft: slots.dock.slopeStartLeft,
            dockSlopeStartRight: slots.dock.slopeStartRight,
            dockTopFlatLeft: slots.dock.topFlatLeft,
            dockTopFlatRight: slots.dock.topFlatRight,
            dockPeakY: slots.dock.peakY,
            dockCurveRun: slots.dock.curveRun,
            homePanelShapeLeft: slots.home.left,
            homePanelShapeRight: slots.home.right,
            homePanelShapeTop: slots.home.top,
            homePanelShapeBottom: slots.home.bottom,
            homePanelShapeRadius: slots.home.radius,
            homePanelCurveRun: slots.home.curveRun
        }
    }

    function buildInnerSegments(sourceGeometry, options) {
        const g = root.flatGeometry(sourceGeometry, options)
        const left = g.innerLeft
        const top = g.innerTop
        const right = g.innerRight
        const bottom = g.innerBottom
        const r = g.cornerRadius
        const notchK = g.clockNotchRadius * cubicNotchFactor
        const statusK = g.statusNotchRadius * cubicNotchFactor
        const homeRun = Math.max(1, g.homePanelCurveRun || g.homePanelShapeRadius)
        const homeK = homeRun * cubicHomeFactor

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

            // Top edge: clock notch exit → status notch
            line(g.clockNotchRight, top, g.statusNotchLeft, top),

            // Status notch: descend
            cubic(
                g.statusNotchLeft, top,
                g.statusNotchLeft + statusK, top,
                g.statusNotchLeft, g.statusNotchBottom - statusK,
                g.statusNotchLeft + g.statusNotchRadius, g.statusNotchBottom
            ),
            line(
                g.statusNotchLeft + g.statusNotchRadius, g.statusNotchBottom,
                g.statusNotchRight - g.statusNotchRadius, g.statusNotchBottom
            ),
            cubic(
                g.statusNotchRight - g.statusNotchRadius, g.statusNotchBottom,
                g.statusNotchRight, g.statusNotchBottom - statusK,
                g.statusNotchRight - statusK, top,
                g.statusNotchRight, top
            ),

            // Top edge: status notch exit → upper-right arc start
            line(g.statusNotchRight, top, right - r, top),
            arc(right - r, top + r, r, 1, top, top + r, right, top + r),

            // Right edge: down to home panel top
            line(right, top + r, g.homePanelShapeRight, g.homePanelShapeTop),

            // Bosse du panel maison: même famille visuelle que le dock, tournée à droite.
            cubic(
                g.homePanelShapeRight, g.homePanelShapeTop,
                g.homePanelShapeRight, g.homePanelShapeTop + homeK,
                g.homePanelShapeLeft, g.homePanelShapeTop + homeRun - homeK,
                g.homePanelShapeLeft, g.homePanelShapeTop + homeRun
            ),
            line(
                g.homePanelShapeLeft, g.homePanelShapeTop + homeRun,
                g.homePanelShapeLeft, g.homePanelShapeBottom - homeRun
            ),
            cubic(
                g.homePanelShapeLeft, g.homePanelShapeBottom - homeRun,
                g.homePanelShapeLeft, g.homePanelShapeBottom - homeRun + homeK,
                g.homePanelShapeRight, g.homePanelShapeBottom - homeK,
                g.homePanelShapeRight, g.homePanelShapeBottom
            ),

            // Right edge: down from home panel → lower-right arc
            line(g.homePanelShapeRight, g.homePanelShapeBottom, right, bottom - r),
            arc(right - r, bottom - r, r, 1, bottom - r, bottom, right - r, bottom),

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
            arc(left + r, bottom - r, r, -1, bottom - r, bottom, left, bottom - r),

            // Left edge up
            line(left, bottom - r, left, top + r),

            // Upper-left arc (closes the loop)
            arc(left + r, top + r, r, -1, top, top + r, left + r, top)
        ]
    }

    function buildSvgPath(sourceGeometry, options) {
        const opts = options || {}
        const geometry = root.normalizeGeometry(sourceGeometry, { inset: opts.inset || 0 })
        const frame = geometry.frame
        const startX = frame.left + frame.cornerRadius
        const startY = frame.top
        const parts = []

        if (opts.withOuterRectangle) {
            const width = Math.max(0, Number(opts.outerWidth || 0))
            const height = Math.max(0, Number(opts.outerHeight || 0))
            parts.push(
                "M", root.n(0), root.n(0),
                "L", root.n(width), root.n(0),
                "L", root.n(width), root.n(height),
                "L", root.n(0), root.n(height),
                "Z"
            )
        }

        parts.push("M", root.n(startX), root.n(startY))

        const segments = root.buildInnerSegments(geometry)
        for (let i = 0; i < segments.length; i++) {
            const segment = segments[i]

            if (segment.kind === "line") {
                parts.push("L", root.n(segment.x2), root.n(segment.y2))
            } else if (segment.kind === "cubic") {
                parts.push(
                    "C",
                    root.n(segment.x1), root.n(segment.y1),
                    root.n(segment.x2), root.n(segment.y2),
                    root.n(segment.x3), root.n(segment.y3)
                )
            } else if (segment.kind === "arc") {
                parts.push(
                    "A",
                    root.n(segment.radius), root.n(segment.radius),
                    "0", "0", "1",
                    root.n(segment.x2), root.n(segment.y2)
                )
            }
        }

        parts.push("Z")
        return parts.join(" ")
    }

    function geometrySignature(sourceGeometry) {
        const g = root.flatGeometry(sourceGeometry)
        return [
            g.innerLeft, g.innerTop, g.innerRight, g.innerBottom, g.cornerRadius,
            g.clockNotchLeft, g.clockNotchRight, g.clockNotchBottom, g.clockNotchRadius,
            g.statusNotchLeft, g.statusNotchRight, g.statusNotchBottom, g.statusNotchRadius,
            g.dockSlopeStartLeft, g.dockSlopeStartRight, g.dockTopFlatLeft,
            g.dockTopFlatRight, g.dockPeakY, g.dockCurveRun,
            g.homePanelShapeLeft, g.homePanelShapeRight, g.homePanelShapeTop,
            g.homePanelShapeBottom, g.homePanelShapeRadius, g.homePanelCurveRun
        ].map(function(value) {
            return root.n(value)
        }).join("|")
    }

    function n(value) {
        const numberValue = Number(value || 0)
        return isFinite(numberValue) ? numberValue.toFixed(3) : "0.000"
    }
}
