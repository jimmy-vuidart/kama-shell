import Gtk from "gi://Gtk?version=4.0"

const dockItems = ["FILES", "WEB", "TERM", "CODE", "CHAT", "GAME", "MUSIC", "OBS"]

export function Dock() {
  return (
    <box class="dock-wrap">
      <box class="dock" spacing={14}>
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
          <label class="dock__time" label="10:42 AM" />
          <label class="dock__date" label="APR 20 2026" />
        </box>
      </box>
    </box>
  )
}
