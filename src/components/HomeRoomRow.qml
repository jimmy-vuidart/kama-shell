import QtQuick

import "../state"

Rectangle {
    id: root

    required property var modelData

    // HA data fields
    readonly property string roomId: modelData.id || ""
    readonly property bool lightsOn: modelData.lightsOn || false
    readonly property int lightsOnCount: modelData.lightsOnCount || 0
    readonly property int lightsTotal: modelData.lightsTotal || 0
    readonly property var lightIds: modelData.lightIds || []
    readonly property int coverPosition: modelData.coverPosition !== undefined
        ? modelData.coverPosition : -1
    readonly property var coverIds: modelData.coverIds || []
    readonly property real temperature: modelData.temperature !== undefined
        ? modelData.temperature : -1
    readonly property real targetTemperature: modelData.targetTemperature !== undefined
        ? modelData.targetTemperature : -1
    readonly property var climateIds: modelData.climateIds || []

    readonly property bool hasLights: lightIds.length > 0
    readonly property bool hasCovers: coverIds.length > 0
    readonly property bool hasClimate: climateIds.length > 0

    height: 116
    radius: ShellTheme.isFfxiv ? 8 : 18
    antialiasing: true
    color: ShellTheme.isFfxiv
        ? Qt.rgba(1, 1, 1, 0.035)
        : Qt.rgba(1, 1, 1, 0.07)
    border.width: 1
    border.color: ShellTheme.controlBorder

    Column {
        anchors {
            fill: parent
            margins: 10
        }
        spacing: 8

        // Room name header
        Text {
            width: parent.width
            height: 22
            text: root.modelData.name || ""
            color: ShellTheme.textPrimary
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 15
            font.weight: Font.Bold
            style: ShellTheme.controlTextStyle
            styleColor: ShellTheme.textShadow
        }

        // Device controls row — only visible controls are laid out
        Row {
            id: controlsRow

            width: parent.width
            spacing: 6

            // Number of visible device controls
            readonly property int numVisible:
                (root.hasLights ? 1 : 0) +
                (root.hasCovers ? 1 : 0) +
                (root.hasClimate ? 1 : 0)

            // Available width after spacing between visible controls
            readonly property real availWidth: width - spacing * Math.max(0, numVisible - 1)

            // Per-control widths based on which are visible (covers need more room for 3 buttons)
            readonly property real lightsWidth: {
                if (!root.hasLights) return 0
                if (root.hasCovers && root.hasClimate)
                    return Math.floor(availWidth * 0.26)
                if (root.hasCovers || root.hasClimate)
                    return Math.floor(availWidth * 0.42)
                return Math.floor(availWidth)
            }
            readonly property real coversWidth: {
                if (!root.hasCovers) return 0
                if (root.hasLights && root.hasClimate)
                    return Math.floor(availWidth * 0.30)
                if (root.hasLights || root.hasClimate)
                    return Math.floor(availWidth * 0.50)
                return Math.floor(availWidth)
            }
            readonly property real climateWidth: {
                if (!root.hasClimate) return 0
                return Math.floor(availWidth) - lightsWidth - coversWidth
            }

            // Lights control
            HomeDeviceControl {
                visible: root.hasLights
                width: controlsRow.lightsWidth
                label: "Lumières"
                value: root.lightsOn
                    ? root.lightsOnCount + " ON"
                    : "OFF"
                active: root.lightsOn

                onClicked: {
                    HomeAssistantState.toggleLights(root.roomId, root.lightsOn)
                }
            }

            // Covers / shutters control — Up / Stop / Down buttons
            HomeDeviceControl {
                visible: root.hasCovers
                width: controlsRow.coversWidth
                label: "Volets"
                value: ""
                active: root.hasCovers && root.coverPosition > 0
                progress: root.coverPosition >= 0 ? root.coverPosition / 100 : -1
                coverControl: true

                onUpActivated: {
                    if (root.coverIds.length > 0)
                        HomeAssistantState.openCover(root.roomId, root.coverIds[0])
                }
                onStopActivated: {
                    if (root.coverIds.length > 0)
                        HomeAssistantState.stopCover(root.roomId, root.coverIds[0])
                }
                onDownActivated: {
                    if (root.coverIds.length > 0)
                        HomeAssistantState.closeCover(root.roomId, root.coverIds[0])
                }
            }

            // Thermostat — target temp + ± buttons
            HomeDeviceControl {
                visible: root.hasClimate
                width: controlsRow.climateWidth
                label: "Thermostat"
                value: {
                    const cur = root.temperature >= 0 ? root.temperature.toFixed(1) + "°" : "—"
                    const tgt = root.targetTemperature >= 0 ? root.targetTemperature.toFixed(1) + "°" : "—"
                    return cur + " / " + tgt
                }
                active: root.hasClimate && root.targetTemperature >= 0
                adjustable: root.hasClimate && root.targetTemperature >= 0

                onDecremented: {
                    if (root.climateIds.length > 0)
                        HomeAssistantState.adjustTargetTemperature(
                            root.roomId, root.climateIds[0], -0.5)
                }
                onIncremented: {
                    if (root.climateIds.length > 0)
                        HomeAssistantState.adjustTargetTemperature(
                            root.roomId, root.climateIds[0], 0.5)
                }
            }
        }
    }
}
