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

    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property bool hasAudio: !!audioSink && !!audioSink.audio
    readonly property bool audioMuted: hasAudio ? audioSink.audio.muted : false
    readonly property real audioVolume: hasAudio ? audioSink.audio.volume : 0
    readonly property string audioIndicatorIconName: !hasAudio
        ? "fluent-speaker-mute-24-regular.svg"
        : audioMuted || audioVolume <= 0.01
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
    readonly property real batteryPercentage: batteryVisible ? batteryDevice.percentage : 0
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

    readonly property int visibleStatusIconCount: root.trayItems.length
        + 3
        + (root.batteryVisible ? 1 : 0)
    readonly property int visibleStatusSpacerCount: 1
        + (root.hasTraySection ? 1 : 0)
    readonly property int visibleStatusGapCount: Math.max(
        0,
        root.visibleStatusIconCount + root.visibleStatusSpacerCount - 1
    )
    readonly property int statusNotchImplicitWidth: (ShellGeometry.statusNotchHorizontalPadding * 2)
        + ((root.visibleStatusIconCount - 1) * ShellGeometry.statusNotchIconSize)
        + ShellGeometry.statusNotchCpuIndicatorWidth
        + ShellGeometry.statusNotchCpuTrailingGap
        + (root.visibleStatusGapCount * ShellGeometry.statusNotchItemGap)
        + (root.hasTraySection ? ShellGeometry.statusNotchCpuTrailingGap : 0)

    PwObjectTracker {
        objects: [root.audioSink]
    }

    onTrayItemsChanged: root.logTrayItems()
    Component.onCompleted: {
        root.logTrayItems()

        if (cpuStatFile.waitForJob()) {
            root.updateCpuLoad(cpuStatFile.text())
        }
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

    function logTrayItems() {
        console.log(
            "status-notch tray items changed",
            "count=" + root.trayItems.length
        )

        for (let i = 0; i < root.trayItems.length; i++) {
            const item = root.trayItems[i]

            console.log(
                "status-notch tray item",
                "index=" + i,
                "id=" + String(item ? item.id : "<null>"),
                "title=" + String(item ? item.title : "<null>"),
                "tooltipTitle=" + String(item ? item.tooltipTitle : "<null>"),
                "icon=" + String(item ? item.icon : "<null>"),
                "status=" + String(item ? item.status : "<null>"),
                "category=" + String(item ? item.category : "<null>"),
                "hasMenu=" + String(item ? item.hasMenu : "<null>"),
                "onlyMenu=" + String(item ? item.onlyMenu : "<null>")
            )
        }
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

    Timer {
        interval: 2000
        repeat: true
        running: true

        onTriggered: cpuStatFile.reload()
    }
}
