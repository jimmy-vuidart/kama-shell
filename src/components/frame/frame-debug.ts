import { createState } from "ags"
import type { Point } from "./frame-path"

type InnerState = {
  points: Point[]
  initialized: boolean
}

export const [innerPolygon, setInnerPolygon] = createState<InnerState>({
  points: [],
  initialized: false,
})

export const [frameSize, setFrameSize] = createState<{ width: number; height: number }>({
  width: 0,
  height: 0,
})

export function initInner(points: Point[]) {
  if (innerPolygon.peek().initialized) return
  setInnerPolygon({ points: [...points], initialized: true })
}

export function movePoint(index: number, point: Point) {
  setInnerPolygon((s) => {
    if (index < 0 || index >= s.points.length) return s
    const next = s.points.slice()
    next[index] = point
    return { ...s, points: next }
  })
}

export function insertPoint(insertAt: number, point: Point) {
  setInnerPolygon((s) => {
    const next = s.points.slice()
    next.splice(insertAt, 0, point)
    return { ...s, points: next }
  })
}

export function removePoint(index: number) {
  setInnerPolygon((s) => {
    if (s.points.length <= 3) return s
    const next = s.points.slice()
    next.splice(index, 1)
    return { ...s, points: next }
  })
}

export function findNearestPoint(x: number, y: number, points: Point[], maxDistance = 22) {
  let best: { index: number; point: Point; dist: number } | null = null
  points.forEach((p, i) => {
    const dist = Math.hypot(p.x - x, p.y - y)
    if (dist < maxDistance && (!best || dist < best.dist)) {
      best = { index: i, point: p, dist }
    }
  })
  return best
}

export function findInsertionIndex(x: number, y: number, points: Point[]): number {
  const n = points.length
  if (n < 2) return n
  let bestI = 0
  let bestDist = Infinity
  for (let i = 0; i < n; i += 1) {
    const a = points[i]
    const b = points[(i + 1) % n]
    const dx = b.x - a.x
    const dy = b.y - a.y
    const len2 = dx * dx + dy * dy
    let t = len2 > 0 ? ((x - a.x) * dx + (y - a.y) * dy) / len2 : 0
    t = Math.max(0, Math.min(1, t))
    const px = a.x + t * dx
    const py = a.y + t * dy
    const dist = Math.hypot(x - px, y - py)
    if (dist < bestDist) {
      bestDist = dist
      bestI = i
    }
  }
  return bestI + 1
}
