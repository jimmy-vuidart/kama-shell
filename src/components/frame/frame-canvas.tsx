import {
  buildShellFramePolygon,
  buildShellInnerPolygon,
  traceRoundedPolygon,
  type Point,
} from "./frame-path"
import { shellFrameLayout } from "./frame-layout"
import { initInner, innerPolygon, setFrameSize } from "./frame-debug"

type DrawContext = {
  save: () => void
  restore: () => void
  setSourceRGBA: (r: number, g: number, b: number, a: number) => void
  setLineWidth: (width: number) => void
  fillPreserve: () => void
  strokePreserve: () => void
  stroke: () => void
  moveTo: (x: number, y: number) => void
  lineTo: (x: number, y: number) => void
  curveTo: (
    x1: number,
    y1: number,
    x2: number,
    y2: number,
    x3: number,
    y3: number,
  ) => void
  closePath: () => void
  setFillRule?: (rule: number) => void
}

function drawShellFrame(cr: DrawContext, outer: Point[], inner: Point[]) {
  cr.save()
  traceRoundedPolygon(cr, outer, shellFrameLayout.frameRadius)
  traceRoundedPolygon(cr, inner, 28)
  cr.setFillRule?.(1)
  cr.setSourceRGBA(0.15, 0.24, 0.68, 0.18)
  cr.fillPreserve()
  cr.setSourceRGBA(0.56, 0.78, 1, 0.02)
  cr.setLineWidth(10)
  cr.stroke()
  cr.restore()

  cr.save()
  traceRoundedPolygon(cr, inner, 28)
  cr.setSourceRGBA(0.72, 0.87, 1, 0.26)
  cr.setLineWidth(1.4)
  cr.stroke()
  cr.restore()
}

export function FrameCanvas() {
  let lastWidth = 0
  let lastHeight = 0

  return (
    <drawingarea
      hexpand
      vexpand
      class="shell-frame-canvas"
      $={(self) => {
        self.set_draw_func((_area, cr, width, height) => {
          if (width !== lastWidth || height !== lastHeight) {
            lastWidth = width
            lastHeight = height
            setFrameSize({ width, height })
          }
          initInner(buildShellInnerPolygon(width, height))
          const outer = buildShellFramePolygon(width, height)
          const inner = innerPolygon.peek().points
          drawShellFrame(cr as unknown as DrawContext, outer, inner)
        })

        innerPolygon.subscribe(() => self.queue_draw())
      }}
    />
  )
}
