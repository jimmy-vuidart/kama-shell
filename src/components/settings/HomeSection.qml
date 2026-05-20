import QtQuick

import "../../state"

Item {
    id: root

    implicitWidth: 520
    implicitHeight: 360

    property string pendingUrl: ShellConfig.homeAssistantUrl
    property string pendingToken: ShellConfig.homeAssistantToken
    readonly property bool dirty: pendingUrl.trim().replace(/\/+$/, "") !== ShellConfig.homeAssistantUrl
        || pendingToken.trim() !== ShellConfig.homeAssistantToken

    function resetFields() {
        pendingUrl = ShellConfig.homeAssistantUrl
        pendingToken = ShellConfig.homeAssistantToken
    }

    Column {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        spacing: 18

        Text {
            text: "Home Assistant"
            color: ShellTheme.textSecondary
            font.pixelSize: 12
            font.weight: Font.DemiBold
            leftPadding: 2
        }

        Column {
            width: Math.min(parent.width, 560)
            spacing: 14

            SettingsTextField {
                id: urlField

                width: parent.width
                label: "URL"
                placeholderText: "http://homeassistant.local:8123"
                text: root.pendingUrl
                onEdited: root.pendingUrl = value
            }

            SettingsTextField {
                id: tokenField

                width: parent.width
                label: "Token"
                placeholderText: "Token d'accès longue durée"
                password: true
                text: root.pendingToken
                onEdited: root.pendingToken = value
            }
        }

        Row {
            spacing: 10

            SettingsButton {
                text: "Enregistrer"
                enabled: root.dirty
                primary: true
                onClicked: ShellConfig.saveHomeAssistantConfig(root.pendingUrl, root.pendingToken)
            }

            SettingsButton {
                text: "Annuler"
                enabled: root.dirty
                onClicked: root.resetFields()
            }
        }
    }

    Connections {
        target: ShellConfig

        function onHomeAssistantUrlChanged() {
            if (!root.dirty) {
                root.pendingUrl = ShellConfig.homeAssistantUrl
            }
        }

        function onHomeAssistantTokenChanged() {
            if (!root.dirty) {
                root.pendingToken = ShellConfig.homeAssistantToken
            }
        }
    }

    component SettingsTextField: Item {
        id: fieldRoot

        required property string label
        property string text: ""
        property string placeholderText: ""
        property bool password: false
        signal edited(string value)

        implicitWidth: 460
        implicitHeight: 72

        Column {
            anchors.fill: parent
            spacing: 7

            Text {
                text: fieldRoot.label
                color: ShellTheme.textSecondary
                font.pixelSize: 12
                font.weight: Font.DemiBold
                leftPadding: 2
            }

            Rectangle {
                width: parent.width
                height: 44
                radius: ShellTheme.controlRadius
                antialiasing: true
                color: input.activeFocus
                    ? ShellTheme.controlFillTopActive
                    : ShellTheme.controlFillTop
                border.width: 1
                border.color: input.activeFocus
                    ? ShellTheme.controlBorderActive
                    : ShellTheme.controlBorder

                Text {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        right: parent.right
                        leftMargin: 16
                        rightMargin: 16
                    }
                    visible: input.text.length === 0 && !input.activeFocus
                    text: fieldRoot.placeholderText
                    color: Qt.rgba(
                        ShellTheme.textSecondary.r,
                        ShellTheme.textSecondary.g,
                        ShellTheme.textSecondary.b,
                        0.52
                    )
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }

                TextInput {
                    id: input

                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        right: parent.right
                        leftMargin: 16
                        rightMargin: 16
                    }
                    text: fieldRoot.text
                    color: ShellTheme.textPrimary
                    selectionColor: ShellTheme.controlBorderActive
                    selectedTextColor: ShellTheme.textPrimary
                    font.pixelSize: 14
                    clip: true
                    echoMode: fieldRoot.password ? TextInput.Password : TextInput.Normal
                    onTextEdited: fieldRoot.edited(text)
                }
            }
        }
    }

    component SettingsButton: Item {
        id: buttonRoot

        property string text: ""
        property bool primary: false
        signal clicked()

        implicitWidth: Math.max(112, buttonText.implicitWidth + 32)
        implicitHeight: 38
        opacity: enabled ? 1 : 0.42

        Rectangle {
            anchors.fill: parent
            radius: ShellTheme.controlRadius
            antialiasing: true
            color: buttonRoot.primary
                ? ShellTheme.controlFillTopActive
                : ShellTheme.controlFillTop
            border.width: 1
            border.color: buttonRoot.primary
                ? ShellTheme.controlBorderActive
                : ShellTheme.controlBorder
        }

        Text {
            id: buttonText

            anchors.centerIn: parent
            text: buttonRoot.text
            color: ShellTheme.textPrimary
            font.pixelSize: 13
            font.weight: ShellTheme.controlTextWeight
        }

        MouseArea {
            anchors.fill: parent
            enabled: buttonRoot.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: buttonRoot.clicked()
        }
    }
}
