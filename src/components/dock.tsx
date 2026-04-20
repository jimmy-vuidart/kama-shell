import Gtk from "gi://Gtk?version=4.0"

import { clockState } from "../services/system-state"

const dockItems = ["FILES", "WEB", "TERM", "CODE", "CHAT", "GAME", "MUSIC", "OBS"]

export function Dock() {
  return (
    <box class="dock-wrap" halign={Gtk.Align.CENTER}>
      <box class="dock shell-surface" spacing={14}>
        {dockItems.map((item) => (
          <button class="dock__item">
            <label class="dock__label" label={item} />
          </button>
        ))}
        <box
          orientation={Gtk.Orientation.VERTICAL}
          class="dock__status"
          hexpand
          halign={Gtk.Align.END}
        >
          <label class="dock__time" label={clockState((clock) => clock.time)} />
          <label class="dock__date" label={clockState((clock) => clock.date)} />
        </box>
      </box>
    </box>
  )
}
