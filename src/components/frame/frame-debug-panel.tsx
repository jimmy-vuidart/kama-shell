import Gtk from "gi://Gtk?version=4.0"
import { createComputed } from "ags"

import { buildShellFramePolygon, type Point } from "./frame-path"
import { frameSize, innerPolygon } from "./frame-debug"

function formatSection(title: string, points: Point[]) {
  const header = title.toUpperCase()
  const lines = points.map(
    (p, i) => `  ${String(i).padStart(2, " ")}: (${Math.round(p.x)}, ${Math.round(p.y)})`,
  )
  return [header, ...lines].join("\n")
}

export function FrameDebugPanel() {
  const text = createComputed(() => {
    const { width, height } = frameSize()
    const inner = innerPolygon().points
    if (!width || !height) return "(waiting for frame size…)"
    const outer = buildShellFramePolygon(width, height)
    return [
      `size: ${width} × ${height}`,
      "",
      formatSection("outer", outer),
      "",
      formatSection("inner", inner),
      "",
      "left-drag: move | right-click: add point",
    ].join("\n")
  })

  return (
    <box
      class="frame-debug-panel"
      halign={Gtk.Align.CENTER}
      valign={Gtk.Align.CENTER}
    >
      <label
        class="frame-debug-panel__text"
        label={text}
        xalign={0}
        yalign={0}
      />
    </box>
  )
}
