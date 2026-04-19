import QtQuick

Item {
    id: root

    property bool triggerHovered: triggerHover.containsMouse

    width: 40
    height: 148

    Rectangle {
        anchors.fill: parent
        anchors.bottomMargin: 32
        radius: width / 2
        color: Qt.rgba(0.16, 0.16, 0.18, 0.92)
    }

    Item {
        width: 28
        height: 28
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 32

        MouseArea {
            id: triggerHover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        Canvas {
            anchors.fill: parent
            antialiasing: true

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                ctx.strokeStyle = "#f2f3f8"
                ctx.lineCap = "round"
                ctx.lineWidth = 2
                const cx = width / 2
                const cy = height / 2 + 2

                ctx.beginPath()
                ctx.moveTo(cx, cy + 6)
                ctx.lineTo(cx, cy + 6)
                ctx.stroke()

                ctx.beginPath()
                ctx.arc(cx, cy + 1, 4.5, Math.PI * 1.2, Math.PI * 1.8)
                ctx.stroke()

                ctx.beginPath()
                ctx.arc(cx, cy - 1, 8.5, Math.PI * 1.18, Math.PI * 1.82)
                ctx.stroke()
            }
        }
    }
}