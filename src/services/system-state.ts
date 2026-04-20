import { createPoll } from "ags/time"

import {
  createCpuMetric,
  createLoadingMetric,
  createNetworkMetric,
  readAudioSlider,
  readBatteryMetric,
  readBluetoothToggle,
  readBrightnessSlider,
  readFocusToggle,
  readMemoryMetric,
  readNetworkToggle,
  readWifiToggle,
} from "../integrations/system"
import { formatClockParts } from "../utils/format"

export const cpuMetric = createPoll(
  {
    ...createLoadingMetric("CPU", "Sampling usage"),
    sample: null,
  },
  2000,
  (prev) => createCpuMetric(prev),
)

export const memoryMetric = createPoll(
  createLoadingMetric("RAM", "Reading memory"),
  5000,
  () => readMemoryMetric(),
)

export const batteryMetric = createPoll(
  createLoadingMetric("Battery", "Looking for device"),
  15000,
  () => readBatteryMetric(),
)

export const networkMetric = createPoll(
  {
    ...createLoadingMetric("Network", "Sampling throughput"),
    counters: null,
  },
  2000,
  (prev) => createNetworkMetric(prev),
)

export const wifiToggle = createPoll(
  { label: "Wi-Fi", value: "Loading", status: "loading" as const },
  5000,
  () => readWifiToggle(),
)

export const bluetoothToggle = createPoll(
  { label: "Bluetooth", value: "Loading", status: "loading" as const },
  8000,
  () => readBluetoothToggle(),
)

export const focusToggle = createPoll(
  { label: "Do Not Disturb", value: "Loading", status: "loading" as const },
  30000,
  () => readFocusToggle(),
)

export const networkToggle = createPoll(
  { label: "Network", value: "Loading", status: "loading" as const },
  2000,
  () => readNetworkToggle(networkMetric()),
)

export const audioSlider = createPoll(
  { label: "Volume", percent: 0, display: "Loading", status: "loading" as const },
  2000,
  () => readAudioSlider(),
)

export const brightnessSlider = createPoll(
  { label: "Brightness", percent: 0, display: "Loading", status: "loading" as const },
  5000,
  () => readBrightnessSlider(),
)

export const clockState = createPoll(
  formatClockParts(new Date()),
  1000,
  () => formatClockParts(new Date()),
)
