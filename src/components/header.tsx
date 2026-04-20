import Gtk from "gi://Gtk?version=4.0"

import { StatusChip } from "./primitives/status-chip"

export function Header() {
  return (
    <box class="header-bar">
      <box hexpand />
      <box class="header-bar__title-wrap">
        <label class="header-bar__title" label="CONTROL CENTER" />
      </box>
      <box hexpand halign={Gtk.Align.END}>
        <box class="header-bar__signals" spacing={10}>
          <StatusChip label="LIVE METRICS" tone="blue" />
          <StatusChip label="MVP UI" tone="pink" />
        </box>
      </box>
    </box>
  )
}
