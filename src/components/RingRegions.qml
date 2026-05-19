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

    Region {
        item: root.panels.statusNotchItem
    }

    component InnerCutout: Item {
        required property Item panels

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            asynchronous: true

            RingSilhouettePath {
                geometry: panels.ringGeometry
                fillColor: "white"
                strokeColor: "transparent"
                strokeWidth: 0
            }
        }
    }
}
