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
                curveRun: 42
            },
            home: {
                left: 1660,
                right: 1904,
                top: 260,
                bottom: 700,
                radius: 28,
                curveRun: 32
            }
        }
    })

    Component.onCompleted: {
        const segments = RingPath.buildInnerSegments(root.geometry)
        root.assert(segments.length > 0, "segments are produced")
        root.assert(segments[0].kind === "line", "first segment is a line")
        root.assert(segments[segments.length - 1].kind === "arc", "last segment closes with an arc")

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
}
