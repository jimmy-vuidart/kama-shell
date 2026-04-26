import QtQuick

import "../state"

Rectangle {
    id: root

    required property var modelData

    property bool lightsOn: modelData.lightsOn
    property int shutterLevel: modelData.shutters
    property real thermostat: modelData.temperature

    height: 106
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

        Row {
            width: parent.width
            height: 22
            spacing: 8

            Text {
                width: parent.width - statusText.width - parent.spacing
                text: root.modelData.name
                color: ShellTheme.textPrimary
                elide: Text.ElideRight
                font.pixelSize: 15
                font.weight: Font.Bold
                style: ShellTheme.controlTextStyle
                styleColor: ShellTheme.textShadow
            }

            Text {
                id: statusText

                text: root.modelData.status
                color: ShellTheme.textSecondary
                font.pixelSize: 11
                verticalAlignment: Text.AlignVCenter
                style: ShellTheme.controlTextStyle
                styleColor: ShellTheme.textShadow
            }
        }

        Row {
            width: parent.width
            height: 54
            spacing: 8

            HomeDeviceControl {
                width: 92
                label: "Lumières"
                value: root.lightsOn ? root.modelData.lightCount + " ON" : "OFF"
                active: root.lightsOn

                onClicked: root.lightsOn = !root.lightsOn
            }

            HomeDeviceControl {
                width: 108
                label: "Volets"
                value: root.shutterLevel + "%"
                active: root.shutterLevel > 0
                progress: root.shutterLevel / 100

                onClicked: root.shutterLevel = root.shutterLevel >= 90 ? 15 : root.shutterLevel + 15
            }

            HomeDeviceControl {
                width: parent.width - 92 - 108 - (parent.spacing * 2)
                label: "Thermostat"
                value: root.thermostat.toFixed(1) + " °C"
                active: true
                progress: (root.thermostat - 16) / 8

                onClicked: root.thermostat = root.thermostat >= 22.5 ? 18.0 : root.thermostat + 0.5
            }
        }
    }
}
