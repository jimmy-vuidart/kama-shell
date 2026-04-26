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
}
