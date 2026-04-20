export function joinClasses(...values: Array<string | false | null | undefined>) {
  return values.filter(Boolean).join(" ")
}

export function formatPercent(value: number) {
  return `${Math.round(value)}%`
}

export function formatGiBFromKiB(value: number) {
  return `${(value / 1024 / 1024).toFixed(1)} GB`
}

export function formatBytesPerSecond(bytesPerSecond: number) {
  if (!Number.isFinite(bytesPerSecond) || bytesPerSecond < 0) {
    return "0 B/s"
  }

  const units = ["B/s", "KB/s", "MB/s", "GB/s"]
  let value = bytesPerSecond
  let unitIndex = 0

  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024
    unitIndex += 1
  }

  const digits = value >= 10 || unitIndex === 0 ? 0 : 1
  return `${value.toFixed(digits)} ${units[unitIndex]}`
}

export function formatClockParts(date: Date) {
  const time = date.toLocaleTimeString([], {
    hour: "2-digit",
    minute: "2-digit",
  })

  const day = date.toLocaleDateString([], {
    month: "short",
    day: "2-digit",
    year: "numeric",
  }).toUpperCase()

  return { time, date: day }
}
