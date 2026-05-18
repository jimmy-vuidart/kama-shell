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
    readonly property var visibleTrayItems: root.trayItems.slice(0, ShellGeometry.statusNotchMaxTrayItems)
    readonly property int overflowTrayCount: Math.max(0, root.trayItems.length - root.visibleTrayItems.length)
    readonly property bool hasTraySection: root.visibleTrayItems.length > 0 || root.overflowTrayCount > 0

    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property bool hasAudio: !!audioSink && !!audioSink.audio
    readonly property bool audioMuted: hasAudio ? audioSink.audio.muted : false
    readonly property real audioVolume: hasAudio ? audioSink.audio.volume : 0
    readonly property string audioIconName: !hasAudio
        ? "audio-volume-muted-symbolic"
        : audioMuted || audioVolume <= 0.01
            ? "audio-volume-muted-symbolic"
            : audioVolume < 0.34
                ? "audio-volume-low-symbolic"
                : audioVolume < 0.67
                    ? "audio-volume-medium-symbolic"
                    : "audio-volume-high-symbolic"
    readonly property string audioIconSource: DockIconResolver.resolveIconSource(audioIconName)

    readonly property var networkDevices: Networking.devices.values || []
    readonly property var connectedNetworkDevices: root.connectedDevices()
    readonly property bool networkConnected: connectedNetworkDevices.length > 0
    readonly property bool networkUsesWifi: root.hasWifiDevice(connectedNetworkDevices)
    readonly property string networkIconName: !networkConnected
        ? "network-offline-symbolic"
        : networkUsesWifi
            ? "network-wireless-signal-good-symbolic"
            : "network-wired-symbolic"
    readonly property string networkIconSource: DockIconResolver.resolveIconSource(networkIconName)

    readonly property var batteryDevice: UPower.displayDevice
    readonly property bool batteryVisible: !!batteryDevice
        && batteryDevice.ready
        && batteryDevice.isLaptopBattery
        && batteryDevice.isPresent
    readonly property real batteryPercentage: batteryVisible ? batteryDevice.percentage : 0
    readonly property string batteryIconName: batteryVisible && batteryDevice.iconName
        ? batteryDevice.iconName
        : "battery-missing-symbolic"
    readonly property string batteryIconSource: DockIconResolver.resolveIconSource(batteryIconName)

    readonly property int visibleStatusIconCount: root.visibleTrayItems.length
        + (root.overflowTrayCount > 0 ? 1 : 0)
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

    function logTrayItems() {
        console.log(
            "status-notch tray items changed",
            "count=" + root.trayItems.length,
            "visible=" + root.visibleTrayItems.length,
            "overflow=" + root.overflowTrayCount
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
