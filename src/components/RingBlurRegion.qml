import Quickshell
import QtQuick

import "../state"

Region {
    id: root

    property bool active: false
    property int surfaceWidth: 0
    property int surfaceHeight: 0

    property real innerLeft: 0
    property real innerTop: 0
    property real innerRight: 0
    property real innerBottom: 0
    property real cornerRadius: 0

    property real clockNotchLeft: 0
    property real clockNotchRight: 0
    property real clockNotchBottom: 0
    property real clockNotchRadius: 0

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

    readonly property var geometryValues: [
        active,
        surfaceWidth,
        surfaceHeight,
        innerLeft,
        innerTop,
        innerRight,
        innerBottom,
        cornerRadius,
        clockNotchLeft,
        clockNotchRight,
        clockNotchBottom,
        clockNotchRadius,
        dockSlopeStartLeft,
        dockSlopeStartRight,
        dockTopFlatLeft,
        dockTopFlatRight,
        dockPeakY,
        dockCurveRun,
        homePanelShapeLeft,
        homePanelShapeRight,
        homePanelShapeTop,
        homePanelShapeBottom,
        homePanelShapeRadius
    ]

    property var spanPool: []
    property bool rebuildQueued: false

    // Cette Region sert uniquement de conteneur pour les spans enfants.
    // Lui donner la taille de la surface ajouterait un rectangle plein à
    // BackgroundEffect.blurRegion et flouterait tout le PanelWindow.
    width: 0
    height: 0

    Component.onCompleted: scheduleRebuild()
    onGeometryValuesChanged: scheduleRebuild()

    function scheduleRebuild() {
        if (root.rebuildQueued) {
            return
        }

        root.rebuildQueued = true
        Qt.callLater(root.rebuild)
    }

    function rebuild() {
        root.rebuildQueued = false

        const spans = root.active ? root.buildCompressedSpans() : []
        root.ensureSpanPool(spans.length)

        for (let i = 0; i < root.spanPool.length; i++) {
            const region = root.spanPool[i]
            const span = i < spans.length ? spans[i] : null

            region.x = span ? span.x : 0
            region.y = span ? span.y : 0
            region.width = span ? span.width : 0
            region.height = span ? span.height : 0
        }

        root.changed()
    }

    function ensureSpanPool(count) {
        while (root.spanPool.length < count) {
            const region = Qt.createQmlObject(
                "import Quickshell\nRegion { x: 0; y: 0; width: 0; height: 0 }",
                root,
                "ring-blur-span"
            )

            root.regions.push(region)
            root.spanPool.push(region)
        }
    }

    function buildCompressedSpans() {
        const result = []
        const activeBySlot = []
        const height = Math.max(0, Math.ceil(root.surfaceHeight))

        for (let y = 0; y < height; y++) {
            const row = root.pixelSpansForY(y)
            const slots = Math.max(row.length, activeBySlot.length)

            for (let slot = 0; slot < slots; slot++) {
                const next = slot < row.length ? row[slot] : null
                const current = activeBySlot[slot] || null

                if (current && next && current.x === next.x && current.width === next.width) {
                    current.height += 1
                    continue
                }

                if (current) {
                    result.push(current)
                    activeBySlot[slot] = null
                }

                if (next) {
                    activeBySlot[slot] = {
                        x: next.x,
                        y: y,
                        width: next.width,
                        height: 1
                    }
                }
            }
        }

        for (let i = 0; i < activeBySlot.length; i++) {
            if (activeBySlot[i]) {
                result.push(activeBySlot[i])
            }
        }

        return result
    }

    function pixelSpansForY(rowY) {
        const width = Math.max(0, Math.ceil(root.surfaceWidth))
        const scanY = rowY + 0.5
        const intersections = root.innerCutoutIntersections(scanY)

        if (intersections.length < 2) {
            return width > 0 ? [{ x: 0, width: width }] : []
        }

        const spans = []
        let cursor = 0

        for (let i = 0; i + 1 < intersections.length; i += 2) {
            root.appendPixelSpan(spans, cursor, intersections[i], width)
            cursor = intersections[i + 1]
        }

        root.appendPixelSpan(spans, cursor, width, width)
        return spans
    }

    function appendPixelSpan(spans, left, right, maxWidth) {
        const start = Math.max(0, Math.min(maxWidth, Math.ceil(left - 0.5)))
        const end = Math.max(0, Math.min(maxWidth, Math.ceil(right - 0.5)))

        if (end > start) {
            spans.push({
                x: start,
                width: end - start
            })
        }
    }

    function innerCutoutIntersections(scanY) {
        const xs = []
        const segments = root.innerCutoutSegments()

        for (let i = 0; i < segments.length; i++) {
            const segment = segments[i]

            if (segment.kind === "line") {
                root.addLineIntersection(xs, segment, scanY)
            } else if (segment.kind === "cubic") {
                root.addCubicIntersection(xs, segment, scanY)
            } else if (segment.kind === "arc") {
                root.addArcIntersection(xs, segment, scanY)
            }
        }

        xs.sort(function(left, right) {
            return left - right
        })

        const unique = []

        for (let i = 0; i < xs.length; i++) {
            if (unique.length === 0 || Math.abs(xs[i] - unique[unique.length - 1]) > 0.001) {
                unique.push(Math.max(0, Math.min(root.surfaceWidth, xs[i])))
            }
        }

        return unique
    }

    // Délègue la production des segments à `RingPath` (singleton). Toute
    // évolution géométrique du ring se fait dans RingPath et le composant
    // QML jumeau `RingSilhouettePath`, jamais en dupliquant ici.
    function innerCutoutSegments() {
        return RingPath.buildInnerSegments({
            innerLeft: root.innerLeft,
            innerTop: root.innerTop,
            innerRight: root.innerRight,
            innerBottom: root.innerBottom,
            cornerRadius: root.cornerRadius,
            clockNotchLeft: root.clockNotchLeft,
            clockNotchRight: root.clockNotchRight,
            clockNotchBottom: root.clockNotchBottom,
            clockNotchRadius: root.clockNotchRadius,
            dockSlopeStartLeft: root.dockSlopeStartLeft,
            dockSlopeStartRight: root.dockSlopeStartRight,
            dockTopFlatLeft: root.dockTopFlatLeft,
            dockTopFlatRight: root.dockTopFlatRight,
            dockPeakY: root.dockPeakY,
            dockCurveRun: root.dockCurveRun,
            homePanelShapeLeft: root.homePanelShapeLeft,
            homePanelShapeRight: root.homePanelShapeRight,
            homePanelShapeTop: root.homePanelShapeTop,
            homePanelShapeBottom: root.homePanelShapeBottom,
            homePanelShapeRadius: root.homePanelShapeRadius
        })
    }

    function addLineIntersection(xs, segment, scanY) {
        if (Math.abs(segment.y1 - segment.y2) < 0.001) {
            return
        }

        const minY = Math.min(segment.y1, segment.y2)
        const maxY = Math.max(segment.y1, segment.y2)

        if (scanY < minY || scanY >= maxY) {
            return
        }

        const t = (scanY - segment.y1) / (segment.y2 - segment.y1)
        xs.push(segment.x1 + ((segment.x2 - segment.x1) * t))
    }

    function addCubicIntersection(xs, segment, scanY) {
        const minY = Math.min(segment.y0, segment.y1, segment.y2, segment.y3)
        const maxY = Math.max(segment.y0, segment.y1, segment.y2, segment.y3)

        if (scanY < minY || scanY >= maxY || Math.abs(segment.y3 - segment.y0) < 0.001) {
            return
        }

        const increasing = segment.y3 > segment.y0
        let low = 0
        let high = 1

        for (let i = 0; i < 18; i++) {
            const mid = (low + high) / 2
            const y = root.cubicValue(segment.y0, segment.y1, segment.y2, segment.y3, mid)

            if ((y < scanY) === increasing) {
                low = mid
            } else {
                high = mid
            }
        }

        const t = (low + high) / 2
        xs.push(root.cubicValue(segment.x0, segment.x1, segment.x2, segment.x3, t))
    }

    function cubicValue(a, b, c, d, t) {
        const mt = 1 - t

        return (mt * mt * mt * a)
            + (3 * mt * mt * t * b)
            + (3 * mt * t * t * c)
            + (t * t * t * d)
    }

    function addArcIntersection(xs, segment, scanY) {
        if (scanY < segment.yMin || scanY >= segment.yMax || segment.radius <= 0) {
            return
        }

        const dy = scanY - segment.cy
        const distance = (segment.radius * segment.radius) - (dy * dy)

        if (distance < 0) {
            return
        }

        xs.push(segment.cx + (segment.side * Math.sqrt(distance)))
    }
}
