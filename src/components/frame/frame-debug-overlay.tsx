import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"

import { buildShellFramePolygon, type Point } from "./frame-path"
import {
  findInsertionIndex,
  findNearestPoint,
  innerPolygon,
  insertPoint,
  movePoint,
} from "./frame-debug"

type CairoCtx = {
  save: () => void
  restore: () => void
  setSourceRGBA: (r: number, g: number, b: number, a: number) => void
  setLineWidth: (w: number) => void
  fillPreserve: () => void
  stroke: () => void
  arc: (xc: number, yc: number, radius: number, a1: number, a2: number) => void
}

function drawDot(cr: CairoCtx, p: Point, fillR: number, fillG: number, fillB: number) {
  cr.save()
  cr.arc(p.x, p.y, 7, 0, Math.PI * 2)
  cr.setSourceRGBA(fillR, fillG, fillB, 0.95)
  cr.fillPreserve()
  cr.setSourceRGBA(1, 1, 1, 0.95)
  cr.setLineWidth(1.6)
  cr.stroke()
  cr.restore()
}

export function FrameDebugOverlay() {
  let dragging: { index: number; origX: number; origY: number } | null = null

  return (
    <drawingarea
      hexpand
      vexpand
      class="shell-frame-debug"
      $={(self) => {
        self.set_draw_func((_area, cr, width, height) => {
          const ctx = cr as unknown as CairoCtx
          const outer = buildShellFramePolygon(width, height)
          const inner = innerPolygon.peek().points
          for (const p of outer) drawDot(ctx, p, 0.4, 0.4, 0.4)
          for (const p of inner) drawDot(ctx, p, 1, 0.15, 0.2)
        })

        innerPolygon.subscribe(() => self.queue_draw())

        const drag = new Gtk.GestureDrag()
        drag.set_button(Gdk.BUTTON_PRIMARY)
        drag.connect("drag-begin", (_g: unknown, x: number, y: number) => {
          const inner = innerPolygon.peek().points
          const hit = findNearestPoint(x, y, inner)
          dragging = hit
            ? { index: hit.index, origX: hit.point.x, origY: hit.point.y }
            : null
        })
        drag.connect("drag-update", (_g: unknown, dx: number, dy: number) => {
          if (!dragging) return
          movePoint(dragging.index, {
            x: dragging.origX + dx,
            y: dragging.origY + dy,
          })
        })
        drag.connect("drag-end", () => {
          dragging = null
        })
        self.add_controller(drag)

        const rightClick = new Gtk.GestureClick()
        rightClick.set_button(Gdk.BUTTON_SECONDARY)
        rightClick.connect(
          "pressed",
          (_g: unknown, _n: number, x: number, y: number) => {
            const inner = innerPolygon.peek().points
            const insertAt = findInsertionIndex(x, y, inner)
            insertPoint(insertAt, { x, y })
          },
        )
        self.add_controller(rightClick)
      }}
    />
  )
}
