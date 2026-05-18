import Quickshell
import QtQuick
import QtQuick.Shapes

import "../state"

Region {
    id: root

    required property Item panels

    width: panels.width
    height: panels.height

    Region {
        width: root.width
        height: root.height
    }

    Region {
        item: InnerCutout {
            panels: root.panels
            width: root.width
            height: root.height
        }
        intersection: Intersection.Subtract
    }

    Region {
        item: root.panels.dockContentItem
    }

    Region {
        item: root.panels.dockHoverItem
    }

    Region {
        item: root.panels.homePanelItem
    }

    component InnerCutout: Item {
        required property Item panels

        Shape {
            anchors.fill: parent

            RingSilhouettePath {
                innerLeft: panels.innerLeft
                innerTop: panels.innerTop
                innerRight: panels.innerRight
                innerBottom: panels.innerBottom
                cornerRadius: ShellGeometry.cornerRadius
                clockNotchLeft: panels.clockNotchLeft
                clockNotchRight: panels.clockNotchRight
                clockNotchBottom: panels.clockNotchBottom
                clockNotchRadius: panels.clockNotchRadius
                dockSlopeStartLeft: panels.dockSlopeStartLeft
                dockSlopeStartRight: panels.dockSlopeStartRight
                dockTopFlatLeft: panels.dockTopFlatLeft
                dockTopFlatRight: panels.dockTopFlatRight
                dockPeakY: panels.dockPeakY
                dockCurveRun: panels.dockCurveRun
                homePanelShapeLeft: panels.homePanelShapeLeft
                homePanelShapeRight: panels.homePanelShapeRight
                homePanelShapeTop: panels.homePanelShapeTop
                homePanelShapeBottom: panels.homePanelShapeBottom
                homePanelShapeRadius: panels.homePanelShapeRadius
                fillColor: "white"
                strokeColor: "transparent"
                strokeWidth: 0
            }
        }
    }
}
