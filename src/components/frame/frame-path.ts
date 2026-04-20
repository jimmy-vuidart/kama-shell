import { shellFrameLayout } from "./frame-layout"

type Point = {
  x: number
  y: number
}

type DrawContext = {
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
}

function direction(from: Point, to: Point) {
  const dx = to.x - from.x
  const dy = to.y - from.y
  const length = Math.max(1, Math.hypot(dx, dy))

  return {
    x: dx / length,
    y: dy / length,
    length,
  }
}

function offsetPoint(point: Point, dir: { x: number; y: number }, distance: number): Point {
  return {
    x: point.x + dir.x * distance,
    y: point.y + dir.y * distance,
  }
}

export function buildShellFramePolygon(width: number, height: number): Point[] {
  const left = shellFrameLayout.outerMargin + shellFrameLayout.frameLeft
  const top = shellFrameLayout.outerMargin + shellFrameLayout.frameTop
  const right = width - shellFrameLayout.outerMargin - shellFrameLayout.frameRight
  const bottom = height - shellFrameLayout.outerMargin - shellFrameLayout.frameBottom

  return [
    { x: left, y: top },
    { x: right, y: top },
    { x: right, y: bottom },
    { x: left, y: bottom },
  ]
}

export function buildShellInnerRect(width: number, height: number) {
  const left =
    shellFrameLayout.outerMargin +
    shellFrameLayout.frameLeft +
    shellFrameLayout.contentInsetLeft -
    24
  const top =
    shellFrameLayout.outerMargin +
    shellFrameLayout.frameTop +
    shellFrameLayout.contentInsetTop -
    10
  const right =
    width -
    shellFrameLayout.outerMargin -
    shellFrameLayout.frameRight -
    shellFrameLayout.contentInsetRight +
    10
  const bottom =
    height -
    shellFrameLayout.outerMargin -
    shellFrameLayout.frameBottom -
    shellFrameLayout.contentInsetBottom +
    36

  return {
    x: left,
    y: top,
    width: Math.max(0, right - left),
    height: Math.max(0, bottom - top),
    radius: 28,
  }
}

export function buildShellInnerPolygon(width: number, height: number): Point[] {
  const rect = buildShellInnerRect(width, height)

  return [
    { x: rect.x, y: rect.y },
    { x: rect.x + rect.width, y: rect.y },
    { x: rect.x + rect.width, y: rect.y + rect.height },
    { x: rect.x, y: rect.y + rect.height },
  ]
}

export function traceRoundedPolygon(
  cr: DrawContext,
  polygon: Point[],
  defaultRadius: number,
) {
  if (polygon.length < 3) {
    return
  }

  const count = polygon.length
  const first = polygon[0]
  const prevOfFirst = polygon[count - 1]
  const nextOfFirst = polygon[1]
  const firstIncoming = direction(prevOfFirst, first)
  const firstOutgoing = direction(first, nextOfFirst)
  const firstRadius = Math.min(defaultRadius, firstIncoming.length / 2, firstOutgoing.length / 2)
  const start = offsetPoint(first, firstOutgoing, firstRadius)

  cr.moveTo(start.x, start.y)

  for (let index = 1; index <= count; index += 1) {
    const prev = polygon[(index - 1 + count) % count]
    const current = polygon[index % count]
    const next = polygon[(index + 1) % count]
    const incoming = direction(prev, current)
    const outgoing = direction(current, next)
    const radius = Math.min(defaultRadius, incoming.length / 2, outgoing.length / 2)

    const lineEnd = offsetPoint(current, { x: -incoming.x, y: -incoming.y }, radius)
    const curveEnd = offsetPoint(current, outgoing, radius)
    const handle = radius * 0.55
    const control1 = offsetPoint(lineEnd, incoming, handle)
    const control2 = offsetPoint(curveEnd, { x: -outgoing.x, y: -outgoing.y }, handle)

    cr.lineTo(lineEnd.x, lineEnd.y)
    cr.curveTo(
      control1.x,
      control1.y,
      control2.x,
      control2.y,
      curveEnd.x,
      curveEnd.y,
    )
  }

  cr.closePath()
}
