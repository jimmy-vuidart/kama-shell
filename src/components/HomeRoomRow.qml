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

    height: 114
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

        // Device controls row
        Row {
            width: parent.width
            spacing: 6
            readonly property real controlsWidth: width - (spacing * 2)

            // Lights
            HomeDeviceControl {
                id: lightControl

                width: Math.floor(parent.controlsWidth * 0.29)
                label: "Lumières"
                value: root.hasLights
                    ? (root.lightsOn ? root.lightsOnCount + " ON" : "OFF")
                    : "—"
                active: root.lightsOn
                enabled: root.hasLights

                onClicked: {
                    if (root.hasLights) {
                        HomeAssistantState.toggleLights(root.roomId, root.lightsOn)
                    }
                }
            }

            // Covers / shutters
            HomeDeviceControl {
                id: coverControl

                width: Math.floor(parent.controlsWidth * 0.30)
                label: "Volets"
                value: root.hasCovers && root.coverPosition >= 0
                    ? root.coverPosition + "%"
                    : "—"
                active: root.hasCovers && root.coverPosition > 0
                progress: root.hasCovers && root.coverPosition >= 0
                    ? root.coverPosition / 100
                    : -1
                enabled: root.hasCovers && root.coverPosition >= 0

                onClicked: {
                    if (root.hasCovers && root.coverIds.length > 0) {
                        HomeAssistantState.toggleCover(
                            root.roomId,
                            root.coverIds[0],
                            root.coverPosition
                        )
                    }
                }
            }

            // Thermostat
            HomeDeviceControl {
                width: parent.controlsWidth - lightControl.width - coverControl.width
                label: "Thermostat"
                value: root.hasClimate && root.targetTemperature >= 0
                    ? root.targetTemperature.toFixed(1) + "°C"
                    : "—"
                secondaryValue: root.hasClimate && root.temperature >= 0
                    ? root.temperature.toFixed(1) + "°C ambiante"
                    : ""
                active: root.hasClimate && root.targetTemperature >= 0
                adjustable: root.hasClimate && root.targetTemperature >= 0
                enabled: root.hasClimate

                onDecremented: {
                    if (root.hasClimate && root.climateIds.length > 0) {
                        HomeAssistantState.adjustTargetTemperature(
                            root.roomId,
                            root.climateIds[0],
                            -0.5
                        )
                    }
                }

                onIncremented: {
                    if (root.hasClimate && root.climateIds.length > 0) {
                        HomeAssistantState.adjustTargetTemperature(
                            root.roomId,
                            root.climateIds[0],
                            0.5
                        )
                    }
                }
            }
        }
    }
}
