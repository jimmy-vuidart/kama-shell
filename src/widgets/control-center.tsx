import Gtk from "gi://Gtk?version=4.0"

import { Card } from "../components/primitives/card"
import { SectionTitle } from "../components/primitives/section-title"
import {
  audioSlider,
  bluetoothToggle,
  brightnessSlider,
  focusToggle,
  networkToggle,
  wifiToggle,
} from "../services/system-state"

function ToggleRow(props: {
  label: string
  value: string | ReturnType<typeof wifiToggle>
}) {
  return (
    <box class="toggle-row">
      <label class="toggle-row__label" label={props.label} xalign={0} hexpand />
      <label class="toggle-row__value" label={props.value} />
    </box>
  )
}

function SliderRow(props: {
  label: string
  value: number | ReturnType<typeof audioSlider>
  display: string | ReturnType<typeof audioSlider>
}) {
  return (
    <box orientation={Gtk.Orientation.VERTICAL} class="slider-row" spacing={8}>
      <box class="slider-row__header">
        <label label={props.label} xalign={0} hexpand />
        <label label={props.display} />
      </box>
      <levelbar class="slider-row__bar" value={props.value} maxValue={100} />
    </box>
  )
}

type ControlCenterWidgetProps = {
  attached?: boolean
}

export function ControlCenterWidget(props: ControlCenterWidgetProps) {
  const className = props.attached ? "control-card control-card--attached" : "control-card"

  return (
    <Card className={className}>
      <SectionTitle title="Control Center" subtitle="Etat réel du poste avec fallbacks non bloquants." />
      <box orientation={Gtk.Orientation.VERTICAL} class="toggle-list" spacing={12}>
        <ToggleRow label="Wi-Fi" value={wifiToggle((item) => item.value)} />
        <ToggleRow label="Bluetooth" value={bluetoothToggle((item) => item.value)} />
        <ToggleRow label="Do Not Disturb" value={focusToggle((item) => item.value)} />
        <ToggleRow label="Network" value={networkToggle((item) => item.value)} />
      </box>
      <box orientation={Gtk.Orientation.VERTICAL} class="slider-list" spacing={12}>
        <SliderRow
          label="Volume"
          value={audioSlider((item) => item.percent)}
          display={audioSlider((item) => item.display)}
        />
        <SliderRow
          label="Brightness"
          value={brightnessSlider((item) => item.percent)}
          display={brightnessSlider((item) => item.display)}
        />
      </box>
      <box class="action-grid" spacing={12}>
        <button class="action-grid__item"><label label="SETTINGS" /></button>
        <button class="action-grid__item"><label label="LOCK" /></button>
        <button class="action-grid__item"><label label="POWER" /></button>
      </box>
    </Card>
  )
}
