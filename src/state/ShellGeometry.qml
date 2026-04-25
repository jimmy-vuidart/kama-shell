pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property int frameInset: 32
    readonly property int frameBorderInset: frameInset + 1
    readonly property int workAreaInset: frameBorderInset
    readonly property int cornerRadius: 48

    readonly property int dockHeight: 88
    readonly property int dockMinWidth: 232
    readonly property int dockSidePadding: 28
    readonly property int dockShapeSidePadding: 72
    readonly property int dockBumpContentPadding: 28
    readonly property int dockShapeExtraWidth: 232
    readonly property int dockBumpHeight: 34
    readonly property int dockItemSize: 48
    readonly property int dockItemGap: 14
    readonly property int dockPadding: 20
    readonly property int dockSeparatorWidth: 1
    readonly property int dockSeparatorHeight: 34
}
