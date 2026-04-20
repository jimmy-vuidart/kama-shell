import Gtk from "gi://Gtk?version=4.0"

export function Header() {
  return (
    <box class="header-bar" halign={Gtk.Align.CENTER}>
      <box class="header-bar__title-wrap shell-surface">
        <label class="header-bar__title" label="CONTROL CENTER" />
      </box>
    </box>
  )
}
