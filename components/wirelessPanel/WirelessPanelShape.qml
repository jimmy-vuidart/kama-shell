import QtQuick

Item {
    id: root

    property int bodyTopInset: 0
    property int outerRightRadius: 14
    property int topLinkHeight: 12
    property int topLinkWidth: 28
    property int topLinkRadius: 10
    property int panelBorderWidth: 2
    property color panelColor: "black"
    property color panelBorderColor: "black"
    property color panelInnerStrokeColor: "#3e404a"

    Canvas {
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d")
            const bodyTop = Math.max(root.bodyTopInset, 0)
            const bodyHeight = Math.max(height - bodyTop, 0)
            const radius = Math.min(root.outerRightRadius, bodyHeight / 2)
            const linkHeight = Math.max(root.topLinkHeight, 0)
            const linkWidth = Math.min(Math.max(root.topLinkWidth, 0), width)
            const linkRadius = Math.min(Math.max(root.topLinkRadius, 0), linkHeight, linkWidth)
            const innerInset = root.panelBorderWidth + 1
            const innerRadius = Math.max(radius - innerInset, 0)
            const innerLinkHeight = Math.max(linkHeight - innerInset, 0)
            const innerLinkWidth = Math.max(linkWidth - innerInset, 0)
            const innerLinkRadius = Math.max(Math.min(linkRadius - innerInset, innerLinkHeight, innerLinkWidth), 0)

            ctx.reset()
            ctx.fillStyle = root.panelColor
            ctx.strokeStyle = root.panelBorderColor
            ctx.lineWidth = root.panelBorderWidth

            if (linkHeight > 0 && linkWidth > 0) {
                ctx.beginPath()
                ctx.moveTo(0, bodyTop)
                ctx.lineTo(linkWidth - linkRadius, bodyTop)
                ctx.arcTo(linkWidth, bodyTop, linkWidth, bodyTop - linkRadius, linkRadius)
                ctx.lineTo(linkWidth, bodyTop - linkHeight)
                ctx.lineTo(0, bodyTop - linkHeight)
                ctx.closePath()
                ctx.fill()
                ctx.stroke()
            }

            ctx.beginPath()
            ctx.moveTo(0, bodyTop)
            ctx.lineTo(width - radius, bodyTop)
            ctx.arcTo(width, bodyTop, width, bodyTop + radius, radius)
            ctx.lineTo(width, bodyTop + bodyHeight - radius)
            ctx.arcTo(width, bodyTop + bodyHeight, width - radius, bodyTop + bodyHeight, radius)
            ctx.lineTo(0, bodyTop + bodyHeight)
            ctx.closePath()

            ctx.fill()
            ctx.stroke()

            ctx.beginPath()
            ctx.moveTo(innerInset, bodyTop + innerInset)
            ctx.lineTo(width - innerInset - innerRadius, bodyTop + innerInset)
            ctx.arcTo(width - innerInset, bodyTop + innerInset, width - innerInset, bodyTop + innerInset + innerRadius, innerRadius)
            ctx.lineTo(width - innerInset, bodyTop + bodyHeight - innerInset - innerRadius)
            ctx.arcTo(width - innerInset, bodyTop + bodyHeight - innerInset, width - innerInset - innerRadius, bodyTop + bodyHeight - innerInset, innerRadius)
            ctx.lineTo(innerInset, bodyTop + bodyHeight - innerInset)
            ctx.closePath()

            ctx.strokeStyle = root.panelInnerStrokeColor
            ctx.lineWidth = 1
            ctx.stroke()

            if (innerLinkHeight > 0 && innerLinkWidth > 0) {
                ctx.beginPath()
                ctx.moveTo(innerInset, bodyTop + innerInset)
                ctx.lineTo(innerInset + innerLinkWidth - innerLinkRadius, bodyTop + innerInset)
                ctx.arcTo(innerInset + innerLinkWidth, bodyTop + innerInset, innerInset + innerLinkWidth, bodyTop + innerInset - innerLinkRadius, innerLinkRadius)
                ctx.lineTo(innerInset + innerLinkWidth, bodyTop + innerInset - innerLinkHeight)
                ctx.lineTo(innerInset, bodyTop + innerInset - innerLinkHeight)
                ctx.closePath()
                ctx.stroke()
            }
        }
    }
}
