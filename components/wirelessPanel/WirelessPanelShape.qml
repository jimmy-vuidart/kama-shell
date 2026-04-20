import QtQuick

Item {
    id: root

    property int bodyTopInset: 0
    property int outerRightRadius: 14
    property int topLinkHeight: 12
    property int topLinkWidth: 28
    property int topLinkRadius: 10
    property int panelBorderWidth: 2
    property int concaveRadius: 8
    property color panelColor: "black"
    property color panelBorderColor: "black"
    property color panelInnerStrokeColor: "#3e404a"

    Canvas {
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d")

            const bodyTop    = Math.max(root.bodyTopInset, 0)
            const bodyHeight = Math.max(height - bodyTop, 0)
            const radius     = Math.min(root.outerRightRadius, bodyHeight / 2, width / 2)
            const linkH      = Math.max(root.topLinkHeight, 0)
            const linkW      = Math.min(Math.max(root.topLinkWidth, 0), width)
            const linkR      = Math.min(root.topLinkRadius, linkH / 2, linkW / 2)
            const hasLink    = linkH > 0 && linkW > 0
            // Rayon du coin concave, clampé pour rester dans les limites
            const cr         = hasLink ? Math.min(root.concaveRadius, linkH, width - linkW) : 0

            const bw  = root.panelBorderWidth
            const ii  = bw + 1   // inset du trait intérieur

            // Valeurs insettées pour le trait intérieur
            const iRadius  = Math.max(radius  - ii, 0)
            const iLinkR   = Math.max(linkR   - ii, 0)
            const iCr      = Math.max(cr      - ii, 0)
            const iLinkW   = Math.max(linkW   - ii, 0)
            const iLinkH   = Math.max(linkH   - ii, 0)

            ctx.reset()

            // ── Forme principale (fill + bordure extérieure) ─────────────────
            ctx.fillStyle   = root.panelColor
            ctx.strokeStyle = root.panelBorderColor
            ctx.lineWidth   = bw

            ctx.beginPath()
            if (hasLink && cr > 0) {
                // Toplink + corps réunis avec coin concave à la jonction
                ctx.moveTo(0, bodyTop - linkH)
                ctx.lineTo(linkW - linkR, bodyTop - linkH)
                // Coin haut-droit du topLink (convexe)
                ctx.arcTo(linkW, bodyTop - linkH, linkW, bodyTop - linkH + linkR, linkR)
                // Bord droit du topLink jusqu'au départ du coin concave
                ctx.lineTo(linkW, bodyTop - cr)
                // Coin concave : le point de contrôle positionné dans le creux
                // attire la courbe vers l'intérieur → effet concave
                ctx.quadraticCurveTo(linkW, bodyTop, linkW + cr, bodyTop)
                // Bord supérieur du corps (partie droite du topLink)
                ctx.lineTo(width - radius, bodyTop)
            } else if (hasLink) {
                // Fallback sans coin concave
                ctx.moveTo(0, bodyTop - linkH)
                ctx.lineTo(linkW - linkR, bodyTop - linkH)
                ctx.arcTo(linkW, bodyTop - linkH, linkW, bodyTop, linkR)
                ctx.lineTo(linkW, bodyTop)
                ctx.lineTo(width - radius, bodyTop)
            } else {
                ctx.moveTo(0, bodyTop)
                ctx.lineTo(width - radius, bodyTop)
            }
            // Coin haut-droit du corps (convexe)
            ctx.arcTo(width, bodyTop, width, bodyTop + radius, radius)
            // Bord droit du corps
            ctx.lineTo(width, bodyTop + bodyHeight - radius)
            // Coin bas-droit du corps (convexe)
            ctx.arcTo(width, bodyTop + bodyHeight, width - radius, bodyTop + bodyHeight, radius)
            // Bord inférieur + fermeture (gauche)
            ctx.lineTo(0, bodyTop + bodyHeight)
            ctx.closePath()
            ctx.fill()
            ctx.stroke()

            // ── Trait intérieur décoratif ────────────────────────────────────
            ctx.strokeStyle = root.panelInnerStrokeColor
            ctx.lineWidth   = 1

            ctx.beginPath()
            if (hasLink && iCr > 0) {
                ctx.moveTo(ii, bodyTop - linkH + ii)
                ctx.lineTo(ii + iLinkW - iLinkR, bodyTop - linkH + ii)
                ctx.arcTo(ii + iLinkW, bodyTop - linkH + ii,
                          ii + iLinkW, bodyTop - linkH + ii + iLinkR, iLinkR)
                ctx.lineTo(ii + iLinkW, bodyTop - iCr)
                ctx.quadraticCurveTo(ii + iLinkW, bodyTop, ii + iLinkW + iCr, bodyTop + ii)
                ctx.lineTo(width - ii - iRadius, bodyTop + ii)
            } else if (hasLink) {
                ctx.moveTo(ii, bodyTop - linkH + ii)
                ctx.lineTo(ii + iLinkW - iLinkR, bodyTop - linkH + ii)
                ctx.arcTo(ii + iLinkW, bodyTop - linkH + ii,
                          ii + iLinkW, bodyTop + ii, iLinkR)
                ctx.lineTo(ii + iLinkW, bodyTop + ii)
                ctx.lineTo(width - ii - iRadius, bodyTop + ii)
            } else {
                ctx.moveTo(ii, bodyTop + ii)
                ctx.lineTo(width - ii - iRadius, bodyTop + ii)
            }
            // Coin haut-droit intérieur
            ctx.arcTo(width - ii, bodyTop + ii, width - ii, bodyTop + ii + iRadius, iRadius)
            // Bord droit intérieur
            ctx.lineTo(width - ii, bodyTop + bodyHeight - ii - iRadius)
            // Coin bas-droit intérieur
            ctx.arcTo(width - ii, bodyTop + bodyHeight - ii,
                      width - ii - iRadius, bodyTop + bodyHeight - ii, iRadius)
            // Bord inférieur intérieur + fermeture
            ctx.lineTo(ii, bodyTop + bodyHeight - ii)
            ctx.closePath()
            ctx.stroke()
        }
    }
}
