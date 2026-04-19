import QtQuick

Canvas {
    property int frameMargin: 48
    property int innerRadius: 24
    property color frameColor: "black"

    antialiasing: true

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()

        ctx.fillStyle = frameColor
        ctx.fillRect(0, 0, width, height)

        const margin = frameMargin
        const radius = innerRadius
        const x = margin
        const y = margin
        const w = width - (margin * 2)
        const h = height - (margin * 2)

        ctx.globalCompositeOperation = "destination-out"
        ctx.beginPath()
        ctx.moveTo(x + radius, y)
        ctx.lineTo(x + w - radius, y)
        ctx.arcTo(x + w, y, x + w, y + radius, radius)
        ctx.lineTo(x + w, y + h - radius)
        ctx.arcTo(x + w, y + h, x + w - radius, y + h, radius)
        ctx.lineTo(x + radius, y + h)
        ctx.arcTo(x, y + h, x, y + h - radius, radius)
        ctx.lineTo(x, y + radius)
        ctx.arcTo(x, y, x + radius, y, radius)
        ctx.closePath()
        ctx.fill()
    }
}