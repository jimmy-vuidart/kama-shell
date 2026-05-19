import QtQuick
import QtQuick.Shapes

import "../state"

// ShapePath réutilisable qui dessine la silhouette intérieure du ring depuis la
// source de vérité `RingPath`. Le chemin visible et la region de blur passent
// donc par la même description géométrique.
ShapePath {
    id: root

    property var geometry: ({})
    property real inset: 0
    property bool withOuterRectangle: false
    property real outerWidth: 0
    property real outerHeight: 0

    startX: 0
    startY: 0

    PathSvg {
        path: RingPath.buildSvgPath(root.geometry, {
            inset: root.inset,
            withOuterRectangle: root.withOuterRectangle,
            outerWidth: root.outerWidth,
            outerHeight: root.outerHeight
        })
    }
}
