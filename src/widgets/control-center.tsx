import Gtk from "gi://Gtk?version=4.0"

import { Card } from "../components/primitives/card"
import { SectionTitle } from "../components/primitives/section-title"

const toggles = [
  ["Wi-Fi", "Home_Network"],
  ["Bluetooth", "On"],
  ["Do Not Disturb", "Off"],
  ["Network", "12.4 MB/s up"],
]

const sliders = [
  ["Volume", 68],
  ["Brightness", 82],
]

export function ControlCenterWidget() {
  return (
    <Card className="control-card">
      <SectionTitle title="Control Center" subtitle="Raccourcis système et actions rapides." />
      <box orientation={Gtk.Orientation.VERTICAL} class="toggle-list" spacing={12}>
        {toggles.map(([label, value]) => (
          <box class="toggle-row">
            <label class="toggle-row__label" label={label} xalign={0} hexpand />
            <label class="toggle-row__value" label={value} />
          </box>
        ))}
      </box>
      <box orientation={Gtk.Orientation.VERTICAL} class="slider-list" spacing={12}>
        {sliders.map(([label, value]) => (
          <box orientation={Gtk.Orientation.VERTICAL} class="slider-row" spacing={8}>
            <box class="slider-row__header">
              <label label={label} xalign={0} hexpand />
              <label label={`${value}%`} />
            </box>
            <levelbar class="slider-row__bar" value={value} maxValue={100} />
          </box>
        ))}
      </box>
      <box class="action-grid" spacing={12}>
        <button class="action-grid__item"><label label="SETTINGS" /></button>
        <button class="action-grid__item"><label label="LOCK" /></button>
        <button class="action-grid__item"><label label="POWER" /></button>
      </box>
    </Card>
  )
}
