import QtQuick
import QtQuick.Shapes

import "../state"

Item {
    id: root

    property color iconColor: ShellTheme.glyphColor

    Shape {
        anchors.fill: parent

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: root.iconColor

            startX: root.width * 0.50
            startY: root.height * 0.10

            PathLine { x: root.width * 0.88; y: root.height * 0.42 }
            PathLine { x: root.width * 0.78; y: root.height * 0.42 }
            PathLine { x: root.width * 0.78; y: root.height * 0.88 }
            PathLine { x: root.width * 0.58; y: root.height * 0.88 }
            PathLine { x: root.width * 0.58; y: root.height * 0.62 }
            PathLine { x: root.width * 0.42; y: root.height * 0.62 }
            PathLine { x: root.width * 0.42; y: root.height * 0.88 }
            PathLine { x: root.width * 0.22; y: root.height * 0.88 }
            PathLine { x: root.width * 0.22; y: root.height * 0.42 }
            PathLine { x: root.width * 0.12; y: root.height * 0.42 }
            PathLine { x: root.width * 0.50; y: root.height * 0.10 }
        }
    }
}
