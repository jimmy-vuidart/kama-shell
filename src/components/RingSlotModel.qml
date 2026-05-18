import QtQuick

import "../state"

QtObject {
    id: root

    required property real surfaceWidth
    required property real surfaceHeight

    property real dockRevealProgress: 0
    property real dockRevealVelocity: 0
    property real dockBumpWidth: ShellGeometry.dockMinWidth
    property real dockCurrentWidth: ShellGeometry.dockRestWidth
    property real dockCurrentHeight: ShellGeometry.dockRestHeight

    property real homeRevealProgress: 0
    property real homeRevealVelocity: 0
    property real homeCurrentHeight: ShellGeometry.homePanelHandleHeight

    readonly property real innerLeft: ShellGeometry.frameInset
    readonly property real innerTop: ShellGeometry.frameInset
    readonly property real innerRight: surfaceWidth - ShellGeometry.frameInset
    readonly property real innerBottom: surfaceHeight - ShellGeometry.frameInset

    readonly property real clockNotchWidth: Math.min(
        ShellGeometry.clockNotchWidth,
        Math.max(0, surfaceWidth - ((ShellGeometry.frameInset + ShellGeometry.cornerRadius + 16) * 2))
    )
    readonly property real clockNotchLeft: (surfaceWidth - clockNotchWidth) / 2
    readonly property real clockNotchRight: clockNotchLeft + clockNotchWidth
    readonly property real clockNotchBottom: ShellGeometry.frameInset + ShellGeometry.clockNotchDepth
    readonly property real clockNotchRadius: Math.min(
        ShellGeometry.clockNotchRadius,
        clockNotchWidth / 2,
        ShellGeometry.clockNotchDepth
    )

    readonly property real dockRestCenter: surfaceWidth / 2
    readonly property real dockShapeLeft: dockRestCenter - (dockCurrentWidth / 2)
    readonly property real dockShapeRight: dockRestCenter + (dockCurrentWidth / 2)
    readonly property real dockTop: surfaceHeight - ShellGeometry.frameInset - dockCurrentHeight
    readonly property real dockSlopeStartLeft: dockShapeLeft
    readonly property real dockSlopeStartRight: dockShapeRight
    readonly property real dockPeakY: dockTop + 2
    readonly property real dockSquashBoost: dockRevealVelocity * 14
    readonly property real dockFlatHalfWidth: (ShellGeometry.dockRestFlatWidth / 2)
        + ((Math.max(52, dockBumpWidth * 0.32) - (ShellGeometry.dockRestFlatWidth / 2)) * dockRevealProgress)
        + dockSquashBoost
    readonly property real dockTopFlatLeft: (surfaceWidth / 2) - dockFlatHalfWidth
    readonly property real dockTopFlatRight: (surfaceWidth / 2) + dockFlatHalfWidth
    readonly property real dockCurveRun: Math.max(10, (dockSlopeStartRight - dockTopFlatRight) * 0.42)

    readonly property real homePanelTop: ShellGeometry.homePanelTopFor(surfaceHeight)
    readonly property real homePanelSquashBoost: homeRevealVelocity * 18
    readonly property real homePanelShapeDepth: ShellGeometry.homePanelBumpDepth
        + ((ShellGeometry.homePanelExpandedWidth - ShellGeometry.frameInset - ShellGeometry.homePanelBumpDepth) * homeRevealProgress)
        + homePanelSquashBoost
    readonly property real homePanelShapeLeft: innerRight - homePanelShapeDepth
    readonly property real homePanelShapeRight: innerRight
    readonly property real homePanelShapeTop: homePanelTop
    readonly property real homePanelShapeBottom: homePanelShapeTop + homeCurrentHeight
    readonly property real homePanelShapeRadius: Math.min(
        ShellGeometry.homePanelShapeRadius,
        homePanelShapeDepth,
        homeCurrentHeight / 2
    )

    readonly property real morphingIntensity: Math.min(1, Math.max(
        Math.abs(dockRevealVelocity),
        Math.abs(homeRevealVelocity)
    ))
}
