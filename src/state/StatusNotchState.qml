pragma Singleton

import Quickshell
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

    readonly property int visibleStatusIconCount: root.trayItems.length
        + 2
        + (root.batteryVisible ? 1 : 0)
    readonly property int visibleStatusGapCount: root.hasTraySection
        ? root.visibleStatusIconCount
        : Math.max(0, root.visibleStatusIconCount - 1)
    readonly property int statusNotchImplicitWidth: (ShellGeometry.statusNotchHorizontalPadding * 2)
        + (root.visibleStatusIconCount * ShellGeometry.statusNotchIconSize)
        + (root.visibleStatusGapCount * ShellGeometry.statusNotchItemGap)
        + (root.hasTraySection ? ShellGeometry.statusNotchSectionGapWidth : 0)

    PwObjectTracker {
        objects: [root.audioSink]
    }

    onTrayItemsChanged: root.logTrayItems()
    Component.onCompleted: root.logTrayItems()

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
}
