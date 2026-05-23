pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root

    readonly property var trayItems: SystemTray.items.values || []
    readonly property bool hasTraySection: root.trayItems.length > 0

    readonly property PwNode audioSink: Pipewire.defaultAudioSink
    readonly property bool hasAudio: !!audioSink && audioSink.ready && !!audioSink.audio
    readonly property bool audioMuted: hasAudio ? audioSink.audio.muted : false
    readonly property real audioVolume: hasAudio ? audioSink.audio.volume : 0
    readonly property string audioIndicatorIconName: !hasAudio
        ? "fluent-speaker-mute-24-regular.svg"
        : audioMuted || audioVolume <= 0
            ? "fluent-speaker-mute-24-regular.svg"
            : audioVolume < 0.34
                ? "fluent-speaker-0-24-regular.svg"
                : audioVolume < 0.67
                    ? "fluent-speaker-1-24-regular.svg"
                    : "fluent-speaker-2-24-regular.svg"

    readonly property var networkDevices: Networking.devices.values || []
    readonly property var connectedNetworkDevices: root.connectedDevices()
    readonly property bool networkConnected: connectedNetworkDevices.length > 0
    readonly property bool networkUsesWifi: root.hasWifiDevice(connectedNetworkDevices)
    readonly property string networkIndicatorIconName: !networkConnected
        ? "fluent-wifi-off-24-regular.svg"
        : networkUsesWifi
            ? "fluent-wifi-1-24-regular.svg"
            : "fluent-plug-connected-24-regular.svg"

    readonly property var batteryDevice: UPower.displayDevice
    readonly property bool batteryVisible: !!batteryDevice
        && batteryDevice.ready
        && batteryDevice.isLaptopBattery
        && batteryDevice.isPresent
    readonly property real batteryPercentage: batteryVisible ? batteryDevice.percentage * 100 : 0
    readonly property string batteryIndicatorIconName: root.batteryIndicatorIconFor(batteryPercentage)

    property real previousCpuTotal: -1
    property real previousCpuIdle: -1
    property real cpuLoad: 0
    property bool cpuLoadAvailable: false
    readonly property int cpuLoadPercentage: cpuLoadAvailable
        ? Math.max(0, Math.min(100, Math.round(cpuLoad * 100)))
        : 0
    readonly property string cpuLoadText: cpuLoadAvailable
        ? cpuLoadPercentage + "%"
        : "--%"

    property real gpuLoad: 0
    property bool gpuLoadAvailable: false
    readonly property int gpuLoadPercentage: gpuLoadAvailable
        ? Math.max(0, Math.min(100, Math.round(gpuLoad * 100)))
        : 0
    readonly property string gpuLoadText: gpuLoadAvailable
        ? gpuLoadPercentage + "%"
        : "--%"

    readonly property int visibleStatusIconCount: root.trayItems.length
        + 4
        + (root.batteryVisible ? 1 : 0)
    readonly property int visibleStatusSpacerCount: 1
        + (root.hasTraySection ? 1 : 0)
    readonly property int visibleStatusGapCount: Math.max(
        0,
        root.visibleStatusIconCount + root.visibleStatusSpacerCount - 1
    )
    readonly property int statusNotchImplicitWidth: (ShellGeometry.statusNotchHorizontalPadding * 2)
        + ((root.visibleStatusIconCount - 2) * ShellGeometry.statusNotchIconSize)
        + ShellGeometry.statusNotchCpuIndicatorWidth
        + ShellGeometry.statusNotchLoadIndicatorWidth
        + ShellGeometry.statusNotchCpuTrailingGap
        + (root.visibleStatusGapCount * ShellGeometry.statusNotchItemGap)
        + (root.hasTraySection ? ShellGeometry.statusNotchCpuTrailingGap : 0)

    PwObjectTracker {
        objects: [root.audioSink]
    }

    Component.onCompleted: {
        if (cpuStatFile.waitForJob()) {
            root.updateCpuLoad(cpuStatFile.text())
        }

        root.refreshGpuLoad()
    }

    function connectedDevices() {
        const result = []

        for (let i = 0; i < root.networkDevices.length; i++) {
            const device = root.networkDevices[i]

            if (device && device.connected) {
                result.push(device)
            }
        }

        return result
    }

    function hasWifiDevice(devices) {
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].type === DeviceType.Wifi) {
                return true
            }
        }

        return false
    }

    function batteryIndicatorIconFor(percentage) {
        const value = Number(percentage || 0)

        if (value >= 90) {
            return "fluent-battery-full-24-regular.svg"
        }

        if (value >= 60) {
            return "fluent-battery-6-24-regular.svg"
        }

        if (value >= 30) {
            return "fluent-battery-3-24-regular.svg"
        }

        return "fluent-battery-0-24-regular.svg"
    }

    function updateCpuLoad(text) {
        const lines = String(text || "").split("\n")
        let cpuLine = ""

        for (let i = 0; i < lines.length; i++) {
            if (lines[i].indexOf("cpu ") === 0) {
                cpuLine = lines[i]
                break
            }
        }

        if (!cpuLine.length) {
            root.cpuLoadAvailable = false
            return
        }

        const parts = cpuLine.trim().split(/\s+/)
        if (parts.length < 5) {
            root.cpuLoadAvailable = false
            return
        }

        const idle = Number(parts[4] || 0) + Number(parts[5] || 0)
        let total = 0

        for (let i = 1; i < parts.length; i++) {
            const value = Number(parts[i] || 0)
            if (isFinite(value)) {
                total += value
            }
        }

        if (total <= 0 || idle < 0) {
            root.cpuLoadAvailable = false
            return
        }

        if (root.previousCpuTotal >= 0 && root.previousCpuIdle >= 0) {
            const totalDelta = total - root.previousCpuTotal
            const idleDelta = idle - root.previousCpuIdle

            if (totalDelta > 0) {
                root.cpuLoad = Math.max(0, Math.min(1, 1 - (idleDelta / totalDelta)))
                root.cpuLoadAvailable = true
            }
        }

        root.previousCpuTotal = total
        root.previousCpuIdle = idle
    }

    function refreshGpuLoad() {
        if (!gpuLoadProcess.running) {
            gpuLoadProcess.running = true
        }
    }

    function updateGpuLoad(line) {
        const raw = String(line || "").trim()
        const value = parseFloat(raw)

        if (!raw.length || !isFinite(value)) {
            root.gpuLoadAvailable = false
            return
        }

        root.gpuLoad = Math.max(0, Math.min(1, value / 100))
        root.gpuLoadAvailable = true
    }

    function normalizeTrayIconSource(rawIcon) {
        const raw = String(rawIcon || "").trim()
        if (!raw.length) return ""

        const iconPrefix = "image://icon/"
        const name = raw.startsWith(iconPrefix) ? raw.slice(iconPrefix.length) : raw

        const marker = "?path="
        const idx = name.indexOf(marker)

        if (idx !== -1) {
            // App provides its own icon theme dir via SNI IconThemePath (e.g. Steam)
            const iconName = name.slice(0, idx)
            const path = name.slice(idx + marker.length)
            const baseName = iconName.slice(iconName.lastIndexOf("/") + 1)
            return Qt.resolvedUrl(path + "/" + baseName + ".png")
        }

        return Quickshell.iconPath(name) || raw
    }

    FileView {
        id: cpuStatFile

        path: "/proc/stat"
        printErrors: false
        blockLoading: true
        watchChanges: false

        onLoaded: root.updateCpuLoad(text())
        onLoadFailed: root.cpuLoadAvailable = false
    }

    Process {
        id: gpuLoadProcess

        command: [
            "sh",
            "-c",
            [
                "print_percent() {",
                "    value=\"$1\"",
                "    case \"$value\" in",
                "        ''|*[!0-9.]* ) return 1 ;;",
                "        * ) printf '%s\\n' \"$value\"; return 0 ;;",
                "    esac",
                "}",
                "",
                "read_drm_sysfs() {",
                "    for f in /sys/class/drm/card*/device/gpu_busy_percent /sys/class/drm/renderD*/device/gpu_busy_percent; do",
                "        [ -r \"$f\" ] || continue",
                "        IFS= read -r value < \"$f\" || continue",
                "        print_percent \"$value\" && return 0",
                "    done",
                "    return 1",
                "}",
                "",
                "read_nvidia_smi() {",
                "    command -v nvidia-smi >/dev/null 2>&1 || return 1",
                "    value=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | sed -n '1p')",
                "    print_percent \"$value\"",
                "}",
                "",
                "read_intel_gpu_top() {",
                "    command -v intel_gpu_top >/dev/null 2>&1 || return 1",
                "    command -v python3 >/dev/null 2>&1 || return 1",
                "    value=$(timeout 2s intel_gpu_top -J -s 250 -n 2 -o - 2>/dev/null | python3 -c 'import re, sys; values = [float(v) for v in re.findall(r\"\\\"busy\\\"\\s*:\\s*([0-9.]+)\", sys.stdin.read())]; print(max(values) if values else \"\")' 2>/dev/null)",
                "    print_percent \"$value\"",
                "}",
                "",
                "read_drm_sysfs || read_intel_gpu_top || read_nvidia_smi || printf '\\n'",
            ].join("\n")
        ]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) { root.updateGpuLoad(line) }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true

        onTriggered: {
            cpuStatFile.reload()
            root.refreshGpuLoad()
        }
    }
}
