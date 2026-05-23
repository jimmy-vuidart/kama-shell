import Quickshell
import QtQuick
import QtQuick.Window

import "state"

Window {
    id: root
    width: 1
    height: 1
    visible: false

    property var geometry: ({
        frame: { left: 16, top: 16, right: 1904, bottom: 1064, cornerRadius: 48 },
        slots: {
            clock: { left: 856, right: 1064, bottom: 34, radius: 18 },
            status: { left: 1660, right: 1840, bottom: 40, radius: 12 },
            dock: {
                slopeStartLeft: 800,
                slopeStartRight: 1120,
                topFlatLeft: 900,
                topFlatRight: 1020,
                peakY: 1012,
                curveRun: 42,
                radius: 28,
                revealProgress: 1
            },
            home: {
                left: 1660,
                right: 1904,
                top: 260,
                bottom: 700,
                radius: 28,
                curveRun: 32,
                revealProgress: 1
            }
        }
    })

    Component.onCompleted: {
        const segments = RingPath.buildInnerSegments(root.geometry)
        root.assert(segments.length > 0, "segments are produced")
        root.assert(segments[0].kind === "line", "first segment is a line")
        root.assert(segments[segments.length - 1].kind === "arc", "last segment closes with an arc")

        const dock = root.geometry.slots.dock
        root.assert(root.hasLine(segments, dock.slopeStartRight, root.geometry.frame.bottom,
            dock.slopeStartRight, dock.peakY + dock.radius), "dock open right edge is straight")
        root.assert(root.hasLine(segments, dock.slopeStartRight - dock.radius, dock.peakY,
            dock.slopeStartLeft + dock.radius, dock.peakY), "dock open top edge is straight")
        root.assert(root.hasLine(segments, dock.slopeStartLeft, dock.peakY + dock.radius,
            dock.slopeStartLeft, root.geometry.frame.bottom), "dock open left edge is straight")
        const idleDockSegments = RingPath.buildInnerSegments(root.geometryWithDockReveal(0))
        root.assert(!root.hasLine(idleDockSegments, dock.slopeStartRight - dock.radius, dock.peakY,
            dock.slopeStartLeft + dock.radius, dock.peakY), "dock idle keeps the compact bump top")

        const home = root.geometry.slots.home
        const homeRadius = Math.min(home.radius, home.right - home.left, (home.bottom - home.top) / 2)
        root.assert(root.hasLine(segments, home.right, home.top, home.left + homeRadius, home.top),
            "home panel top edge is straight")
        root.assert(root.hasLine(segments, home.left + homeRadius, home.bottom, home.right, home.bottom),
            "home panel bottom edge is straight")
        const idleSegments = RingPath.buildInnerSegments(root.geometryWithHomeReveal(0))
        root.assert(!root.hasLine(idleSegments, home.right, home.top, home.left + homeRadius, home.top),
            "home panel idle keeps the compact bump top")

        const path = RingPath.buildSvgPath(root.geometry, {
            withOuterRectangle: true,
            outerWidth: 1920,
            outerHeight: 1080
        })
        root.assert(path.indexOf("NaN") < 0, "svg path contains no NaN")
        root.assert(path.indexOf("M 0.000 0.000") === 0, "svg path starts with outer rectangle")
        root.assert(path.indexOf(" A ") >= 0, "svg path contains arcs")
        root.assert(path.indexOf(" C ") >= 0, "svg path contains cubics")

        const signature = RingPath.geometrySignature(root.geometry)
        root.assert(signature === RingPath.geometrySignature(root.geometry), "signature is stable")
        console.log("RingPathSelfTest passed")
        root.destroy()
    }

    function assert(condition, message) {
        if (!condition) {
            console.error("RingPathSelfTest failed:", message)
            root.destroy()
            throw new Error(message)
        }
    }

    function hasLine(segments, x1, y1, x2, y2) {
        for (let i = 0; i < segments.length; i++) {
            const segment = segments[i]
            if (segment.kind === "line"
                    && root.near(segment.x1, x1)
                    && root.near(segment.y1, y1)
                    && root.near(segment.x2, x2)
                    && root.near(segment.y2, y2)) {
                return true
            }
        }

        return false
    }

    function near(left, right) {
        return Math.abs(left - right) < 0.001
    }

    function geometryWithHomeReveal(progress) {
        const copy = JSON.parse(JSON.stringify(root.geometry))
        copy.slots.home.revealProgress = progress
        return copy
    }

    function geometryWithDockReveal(progress) {
        const copy = JSON.parse(JSON.stringify(root.geometry))
        copy.slots.dock.revealProgress = progress
        return copy
    }
}
