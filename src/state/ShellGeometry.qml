pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property int frameInset: 16
    readonly property int frameBorderInset: frameInset + 1
    readonly property int cornerRadius: 48

    readonly property int dockHeight: 88
    readonly property int dockMinWidth: 232
    readonly property int dockSidePadding: 28
    readonly property int dockShapeSidePadding: 72
    readonly property int dockBumpContentPadding: 28
    readonly property int dockShapeExtraWidth: 232
    readonly property int dockBumpHeight: 34
    readonly property int dockRestWidth: 72
    readonly property int dockRestHeight: 24
    readonly property int dockRestFlatWidth: 22
    readonly property int dockRestIconSize: 16
    readonly property int dockItemSize: 48
    readonly property int dockItemGap: 14
    readonly property int dockPadding: 20
    readonly property int dockHoverZoneHeight: 28
    readonly property int dockRevealOffset: 18
    readonly property int dockSeparatorWidth: 1
    readonly property int dockSeparatorHeight: 34

    readonly property int clockNotchWidth: 208
    readonly property int clockNotchDepth: 18
    readonly property int clockNotchRadius: 19
    readonly property int clockNotchHorizontalPadding: 22
    readonly property int clockNotchFontSize: 13
    readonly property int clockNotchTextVerticalOffset: -8

    readonly property real homePanelTopRatio: 0.25
    readonly property int homePanelExpandedWidth: 380
    readonly property int homePanelExpandedHeight: 472
    readonly property int homePanelBumpDepth: 24
    readonly property int homePanelBumpHeight: dockRestWidth
    readonly property int homePanelCompactShapeRadius: 10
    readonly property int homePanelShapeRadius: 28
    readonly property int homePanelHandleWidth: frameInset + homePanelBumpDepth + 12
    readonly property int homePanelHandleHeight: homePanelBumpHeight
    readonly property int homePanelHandleIconSize: dockRestIconSize
    readonly property int homePanelAnimationDuration: 220
    readonly property int homePanelRoomGap: 10

    function homePanelTopFor(screenHeight) {
        const availableHeight = Math.max(0, Number(screenHeight || 0))
        const minTop = frameInset + cornerRadius + 8
        const maxTop = Math.max(
            minTop,
            availableHeight - frameInset - cornerRadius - homePanelExpandedHeight - 8
        )
        const desiredTop = Math.round(availableHeight * homePanelTopRatio)

        return Math.min(maxTop, Math.max(minTop, desiredTop))
    }
}
