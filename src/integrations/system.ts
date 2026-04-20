import Gio from "gi://Gio?version=2.0"
import GLib from "gi://GLib?version=2.0"

export type PollStatus = "loading" | "ready" | "empty" | "error"

export type MetricCardState = {
  label: string
  value: string
  meta: string
  status: PollStatus
}

export type SliderState = {
  label: string
  percent: number
  display: string
  status: PollStatus
}

export type ToggleState = {
  label: string
  value: string
  status: PollStatus
}

type CommandResult = {
  ok: boolean
  stdout: string
  stderr: string
}

type CpuTicks = {
  idle: number
  total: number
}

type CpuMetricPollState = MetricCardState & {
  sample: CpuTicks | null
}

type NetworkCounters = {
  interfaceName: string
  rxBytes: number
  txBytes: number
  timestampMs: number
}

type NetworkMetricPollState = MetricCardState & {
  counters: NetworkCounters | null
}

const decoder = new TextDecoder()

function readTextFile(path: string) {
  try {
    const [ok, bytes] = GLib.file_get_contents(path)
    if (!ok || !bytes) {
      return null
    }

    return decoder.decode(bytes).trim()
  } catch {
    return null
  }
}

function listDirectoryNames(path: string) {
  try {
    const dir = Gio.File.new_for_path(path)
    const enumerator = dir.enumerate_children(
      "standard::name",
      Gio.FileQueryInfoFlags.NONE,
      null,
    )

    const names: string[] = []
    let info = enumerator.next_file(null)

    while (info) {
      const name = info.get_name()
      if (name) {
        names.push(name)
      }
      info = enumerator.next_file(null)
    }

    enumerator.close(null)
    return names
  } catch {
    return []
  }
}

function runCommand(command: string): CommandResult {
  try {
    const [, stdoutBytes, stderrBytes] = GLib.spawn_command_line_sync(command)

    return {
      ok: true,
      stdout: stdoutBytes ? decoder.decode(stdoutBytes).trim() : "",
      stderr: stderrBytes ? decoder.decode(stderrBytes).trim() : "",
    }
  } catch (error) {
    return {
      ok: false,
      stdout: "",
      stderr: error instanceof Error ? error.message : String(error),
    }
  }
}

function toNumber(value: string | null) {
  if (!value) {
    return null
  }

  const parsed = Number(value.trim())
  return Number.isFinite(parsed) ? parsed : null
}

function readCpuTicks(): CpuTicks | null {
  const firstLine = readTextFile("/proc/stat")?.split("\n")[0]
  if (!firstLine?.startsWith("cpu ")) {
    return null
  }

  const values = firstLine
    .trim()
    .split(/\s+/)
    .slice(1)
    .map((value) => Number(value))

  if (values.some((value) => !Number.isFinite(value))) {
    return null
  }

  const idle = values[3] + (values[4] ?? 0)
  const total = values.reduce((sum, value) => sum + value, 0)
  return { idle, total }
}

function detectBatteryPath() {
  return listDirectoryNames("/sys/class/power_supply")
    .find((entry) => entry.startsWith("BAT"))
}

function detectActiveInterface() {
  const candidates = listDirectoryNames("/sys/class/net").filter((name) => name !== "lo")
  const active = candidates.find((name) => readTextFile(`/sys/class/net/${name}/operstate`) === "up")

  return active ?? candidates[0] ?? null
}

function readNetworkCounters() {
  const interfaceName = detectActiveInterface()
  if (!interfaceName) {
    return null
  }

  const rxBytes = toNumber(readTextFile(`/sys/class/net/${interfaceName}/statistics/rx_bytes`))
  const txBytes = toNumber(readTextFile(`/sys/class/net/${interfaceName}/statistics/tx_bytes`))

  if (rxBytes === null || txBytes === null) {
    return null
  }

  return {
    interfaceName,
    rxBytes,
    txBytes,
    timestampMs: Date.now(),
  }
}

function parseAudioPercent(stdout: string) {
  const match = stdout.match(/Volume:\s+([0-9.]+)/)
  if (!match) {
    return null
  }

  return Math.max(0, Math.min(100, Math.round(Number(match[1]) * 100)))
}

function parseBrightnessPercent(stdout: string) {
  const columns = stdout.split(",")
  if (columns.length < 4) {
    return null
  }

  return toNumber(columns[3].replace("%", ""))
}

function parseBluetoothState() {
  const result = runCommand("rfkill --json")
  if (!result.ok && !result.stdout) {
    return { label: "Bluetooth", value: "Unavailable", status: "error" as const }
  }

  if (result.stdout.includes("\"type\": \"bluetooth\"")) {
    const softBlocked = result.stdout.includes("\"soft\": \"blocked\"")
    const hardBlocked = result.stdout.includes("\"hard\": \"blocked\"")
    const isBlocked = softBlocked || hardBlocked

    return {
      label: "Bluetooth",
      value: isBlocked ? "Off" : "On",
      status: "ready" as const,
    }
  }

  return {
    label: "Bluetooth",
    value: "Not detected",
    status: "empty" as const,
  }
}

export function createLoadingMetric(label: string, meta: string): MetricCardState {
  return { label, value: "--", meta, status: "loading" }
}

export function createCpuMetric(prev: CpuMetricPollState): CpuMetricPollState {
  const sample = readCpuTicks()
  if (!sample) {
    return {
      label: "CPU",
      value: "ERR",
      meta: "Unable to read /proc/stat",
      status: "error",
      sample: prev.sample,
    }
  }

  if (!prev.sample) {
    return {
      label: "CPU",
      value: "--",
      meta: "Sampling usage",
      status: "loading",
      sample,
    }
  }

  const totalDiff = sample.total - prev.sample.total
  const idleDiff = sample.idle - prev.sample.idle
  const usage = totalDiff > 0 ? ((totalDiff - idleDiff) / totalDiff) * 100 : 0

  return {
    label: "CPU",
    value: `${Math.round(usage)}%`,
    meta: `${Math.round(100 - usage)}% idle`,
    status: "ready",
    sample,
  }
}

export function readMemoryMetric(): MetricCardState {
  const contents = readTextFile("/proc/meminfo")
  if (!contents) {
    return {
      label: "RAM",
      value: "ERR",
      meta: "Unable to read /proc/meminfo",
      status: "error",
    }
  }

  const values = new Map<string, number>()

  for (const line of contents.split("\n")) {
    const match = line.match(/^([^:]+):\s+(\d+)/)
    if (match) {
      values.set(match[1], Number(match[2]))
    }
  }

  const total = values.get("MemTotal")
  const available = values.get("MemAvailable")

  if (!total || available === undefined) {
    return {
      label: "RAM",
      value: "ERR",
      meta: "Unexpected meminfo format",
      status: "error",
    }
  }

  const used = total - available
  const usage = (used / total) * 100

  return {
    label: "RAM",
    value: `${Math.round(usage)}%`,
    meta: `${(used / 1024 / 1024).toFixed(1)} / ${(total / 1024 / 1024).toFixed(1)} GB`,
    status: "ready",
  }
}

export function readBatteryMetric(): MetricCardState {
  const upowerDevices = runCommand("upower -e")
  const batteryDevice = upowerDevices.stdout
    .split("\n")
    .find((line) => line.includes("battery"))

  if (batteryDevice) {
    const info = runCommand(`upower -i ${batteryDevice}`)
    if (info.stdout) {
      const percentage = info.stdout.match(/percentage:\s+([0-9]+%)/)
      const state = info.stdout.match(/state:\s+([a-z-]+)/)
      const time = info.stdout.match(/time to (empty|full):\s+(.+)/)

      return {
        label: "Battery",
        value: percentage?.[1] ?? "--",
        meta: time?.[2] ?? state?.[1] ?? "UPower",
        status: "ready",
      }
    }
  }

  const batteryPath = detectBatteryPath()
  if (!batteryPath) {
    return {
      label: "Battery",
      value: "AC",
      meta: "No battery detected",
      status: "empty",
    }
  }

  const capacity = readTextFile(`/sys/class/power_supply/${batteryPath}/capacity`)
  const status = readTextFile(`/sys/class/power_supply/${batteryPath}/status`)

  return {
    label: "Battery",
    value: capacity ? `${capacity}%` : "--",
    meta: status ?? "Battery present",
    status: capacity ? "ready" : "empty",
  }
}

export function createNetworkMetric(prev: NetworkMetricPollState): NetworkMetricPollState {
  const counters = readNetworkCounters()
  if (!counters) {
    return {
      label: "Network",
      value: "Offline",
      meta: "No active interface",
      status: "empty",
      counters: null,
    }
  }

  const nmcli = runCommand("nmcli -t -f DEVICE,STATE,CONNECTION device status")
  const activeLine = nmcli.stdout
    .split("\n")
    .find((line) => line.startsWith(`${counters.interfaceName}:`))
  const connectionName = activeLine?.split(":")[2] ?? counters.interfaceName

  if (!prev.counters || prev.counters.interfaceName !== counters.interfaceName) {
    return {
      label: "Network",
      value: connectionName,
      meta: "Sampling throughput",
      status: "loading",
      counters,
    }
  }

  const elapsedSeconds = (counters.timestampMs - prev.counters.timestampMs) / 1000
  const rxRate = elapsedSeconds > 0 ? (counters.rxBytes - prev.counters.rxBytes) / elapsedSeconds : 0
  const txRate = elapsedSeconds > 0 ? (counters.txBytes - prev.counters.txBytes) / elapsedSeconds : 0

  return {
    label: "Network",
    value: connectionName,
    meta: `↓ ${Math.max(0, rxRate / 1024 / 1024).toFixed(1)} MB/s ↑ ${Math.max(0, txRate / 1024 / 1024).toFixed(1)} MB/s`,
    status: "ready",
    counters,
  }
}

export function readWifiToggle(): ToggleState {
  const nmcli = runCommand("nmcli -t -f WIFI general")
  const wifiEnabled = nmcli.stdout.split("\n")[0]

  if (wifiEnabled === "enabled") {
    const active = runCommand("nmcli -t -f ACTIVE,SSID dev wifi")
    const ssid = active.stdout
      .split("\n")
      .find((line) => line.startsWith("yes:"))
      ?.slice(4)

    return {
      label: "Wi-Fi",
      value: ssid || "Enabled",
      status: "ready",
    }
  }

  const interfaceName = detectActiveInterface()
  if (interfaceName?.startsWith("wl")) {
    return {
      label: "Wi-Fi",
      value: interfaceName,
      status: "ready",
    }
  }

  return {
    label: "Wi-Fi",
    value: "Unavailable",
    status: "empty",
  }
}

export function readBluetoothToggle(): ToggleState {
  return parseBluetoothState()
}

export function readNetworkToggle(network: MetricCardState): ToggleState {
  return {
    label: "Network",
    value: network.meta,
    status: network.status,
  }
}

export function readFocusToggle(): ToggleState {
  return {
    label: "Do Not Disturb",
    value: "Planned",
    status: "empty",
  }
}

export function readAudioSlider(): SliderState {
  const result = runCommand("wpctl get-volume @DEFAULT_AUDIO_SINK@")
  const percent = parseAudioPercent(result.stdout)

  if (percent === null) {
    return {
      label: "Volume",
      percent: 0,
      display: "Unavailable",
      status: "empty",
    }
  }

  const muted = result.stdout.includes("[MUTED]")
  return {
    label: "Volume",
    percent,
    display: muted ? `${percent}% muted` : `${percent}%`,
    status: "ready",
  }
}

export function readBrightnessSlider(): SliderState {
  const result = runCommand("brightnessctl -m")
  const percent = parseBrightnessPercent(result.stdout)

  if (percent === null) {
    return {
      label: "Brightness",
      percent: 0,
      display: "Unavailable",
      status: "empty",
    }
  }

  return {
    label: "Brightness",
    percent,
    display: `${Math.round(percent)}%`,
    status: "ready",
  }
}
