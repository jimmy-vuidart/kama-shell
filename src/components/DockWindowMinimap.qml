import Quickshell
import QtQuick

import "../state"

Item {
    id: root

    required property var screen

    readonly property string screenName: screen ? String(screen.name || "") : ""

    readonly property var activeWorkspaceId: {
        var _ = NiriWorkspaceState.workspaces
        return NiriWorkspaceState.activeWorkspaceIdForOutput(root.screenName)
    }

    readonly property var workspaceWindows: {
        var _ = NiriWindowBackend.windows
        var wsId = root.activeWorkspaceId
        if (wsId === null || wsId === undefined)
            return []
        return NiriWindowBackend.windows.filter(function(w) {
            return w && !w.isFloating && String(w.workspaceId) === String(wsId)
        })
    }

    readonly property bool hasWindows: workspaceWindows.length > 0

    readonly property var columns: {
        var wins = root.workspaceWindows
        var groups = {}
        var fallback = []

        for (var i = 0; i < wins.length; i++) {
            var w = wins[i]
            var ci = (w.layout && w.layout.columnIndex >= 0) ? w.layout.columnIndex : -1

            if (ci < 0) {
                fallback.push(w)
            } else {
                if (!groups[ci])
                    groups[ci] = []
                groups[ci].push(w)
            }
        }

        var colKeys = Object.keys(groups).map(Number).sort(function(a, b) {
            return a - b
        })
        var result = []

        for (var k = 0; k < colKeys.length; k++) {
            var tiles = groups[colKeys[k]].slice()
            tiles.sort(function(a, b) {
                var ai = (a.layout && a.layout.tileIndex >= 0) ? a.layout.tileIndex : 0
                var bi = (b.layout && b.layout.tileIndex >= 0) ? b.layout.tileIndex : 0
                return ai - bi
            })
            result.push(tiles)
        }

        if (fallback.length > 0)
            result.push(fallback)

        return result
    }

    readonly property int columnCount: columns.length

    readonly property var columnTileWidths: {
        var cols = root.columns
        var widths = []
        for (var i = 0; i < cols.length; i++) {
            var tiles = cols[i]
            var tw = (tiles && tiles.length > 0 && tiles[0].layout && tiles[0].layout.tileWidth > 0)
                ? tiles[0].layout.tileWidth
                : 1
            widths.push(tw)
        }
        return widths
    }

    readonly property int totalWidth: {
        if (columnCount === 0)
            return ShellGeometry.minimapMinWidth
        var inner = columnCount * ShellGeometry.minimapColumnTargetWidth + Math.max(0, columnCount - 1) * ShellGeometry.minimapColumnGap
        return Math.max(ShellGeometry.minimapMinWidth, Math.min(ShellGeometry.minimapMaxWidth, inner + 2 * ShellGeometry.minimapPadding))
    }

    readonly property int innerWidth: totalWidth - 2 * ShellGeometry.minimapPadding - Math.max(0, columnCount - 1) * ShellGeometry.minimapColumnGap

    readonly property var columnVisualWidths: {
        var ctw = root.columnTileWidths
        var n = ctw.length
        if (n === 0)
            return []
        var totalTW = 0
        for (var i = 0; i < n; i++)
            totalTW += ctw[i]
        var available = root.innerWidth
        var widths = []
        var distributed = 0
        for (var j = 0; j < n - 1; j++) {
            var w = Math.max(4, Math.round(available * ctw[j] / totalTW))
            widths.push(w)
            distributed += w
        }
        widths.push(Math.max(4, available - distributed))
        return widths
    }

    // Geometric approximation: which columns fit in screenWidth centered on focused column
    readonly property int screenWidth: {
        var _ = NiriWorkspaceState.outputs
        var output = NiriWorkspaceState.outputForName(root.screenName)
        return output && output.logicalWidth > 0 ? output.logicalWidth : 1920
    }

    readonly property int focusedColumnArrayIdx: {
        var cols = root.columns
        for (var i = 0; i < cols.length; i++) {
            var tiles = cols[i]
            for (var j = 0; j < tiles.length; j++) {
                if (tiles[j] && tiles[j].activated)
                    return i
            }
        }
        return -1
    }

    readonly property var columnsInView: {
        var n = root.columnCount
        if (n === 0)
            return []
        var focusIdx = root.focusedColumnArrayIdx
        var result = []
        for (var i = 0; i < n; i++)
            result.push(false)
        if (focusIdx < 0)
            return result
        var colW = root.columnTileWidths
        result[focusIdx] = true
        var leftBudget = Math.max(0, root.screenWidth - colW[focusIdx]) / 2
        var rightBudget = leftBudget
        for (var l = focusIdx - 1; l >= 0; l--) {
            if (leftBudget > 0) {
                result[l] = true
                leftBudget -= colW[l]
            } else {
                break
            }
        }
        for (var r = focusIdx + 1; r < n; r++) {
            if (rightBudget > 0) {
                result[r] = true
                rightBudget -= colW[r]
            } else {
                break
            }
        }
        return result
    }

    width: totalWidth
    height: ShellGeometry.dockItemSize

    function tileHeightsForColumn(tiles, availableHeight) {
        if (!tiles || tiles.length === 0)
            return []
        var n = tiles.length
        var totalGaps = Math.max(0, n - 1) * ShellGeometry.minimapTileGap
        var available = Math.max(0, availableHeight - totalGaps)
        var totalTileH = 0

        for (var i = 0; i < n; i++) {
            totalTileH += (tiles[i].layout && tiles[i].layout.tileHeight > 0) ? tiles[i].layout.tileHeight : 1
        }

        var heights = []
        var distributed = 0

        for (var j = 0; j < n - 1; j++) {
            var h = (tiles[j].layout && tiles[j].layout.tileHeight > 0) ? tiles[j].layout.tileHeight : 1
            var tileH = Math.max(ShellGeometry.minimapTileMinHeight, Math.round(available * h / totalTileH))
            heights.push(tileH)
            distributed += tileH
        }

        heights.push(Math.max(ShellGeometry.minimapTileMinHeight, available - distributed))
        return heights
    }

    Item {
        anchors {
            fill: parent
            leftMargin: ShellGeometry.minimapPadding
            rightMargin: ShellGeometry.minimapPadding
            topMargin: ShellGeometry.minimapPadding
            bottomMargin: ShellGeometry.minimapPadding
        }
        clip: true

        Row {
            anchors.centerIn: parent
            spacing: ShellGeometry.minimapColumnGap

            Repeater {
                model: root.columns.length

                delegate: Item {
                    id: columnDelegate

                    required property int index

                    readonly property int columnIdx: index
                    readonly property var columnTiles: root.columns[columnIdx]
                    readonly property int visualWidth: root.columnVisualWidths[columnIdx] || ShellGeometry.minimapColumnTargetWidth
                    readonly property int innerHeight: ShellGeometry.dockItemSize - 2 * ShellGeometry.minimapPadding
                    readonly property var tileHeights: root.tileHeightsForColumn(columnTiles, innerHeight)
                    readonly property bool colInView: root.columnsInView[columnIdx] || false

                    width: visualWidth
                    height: innerHeight

                    Column {
                        anchors.fill: parent
                        spacing: ShellGeometry.minimapTileGap

                        Repeater {
                            model: columnDelegate.columnTiles ? columnDelegate.columnTiles.length : 0

                            delegate: Rectangle {
                                required property int index

                                readonly property var tileWindow: columnDelegate.columnTiles[index]
                                readonly property bool isActive: tileWindow ? tileWindow.activated : false

                                width: columnDelegate.visualWidth
                                height: columnDelegate.tileHeights[index] || ShellGeometry.minimapTileMinHeight
                                radius: 2
                                color: isActive ? ShellTheme.runningIndicatorActive : ShellTheme.runningIndicator
                                opacity: isActive || columnDelegate.colInView ? 1.0 : 0.3

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        if (tileWindow && tileWindow.niriWindowId !== undefined) {
                                            NiriWindowBackend.focusWindowById(tileWindow.niriWindowId)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
