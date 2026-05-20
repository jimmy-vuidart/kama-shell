import QtQuick

import "../../state"

Item {
    id: root

    implicitWidth: 400
    implicitHeight: 420

    property string pendingGlowColor: ShellConfig.ringGlowColor
    readonly property string normalizedPendingGlowColor: ShellConfig.normalizedColorHex(pendingGlowColor, ShellConfig.ringGlowColor)
    readonly property color pendingGlowBase: normalizedPendingGlowColor
    readonly property bool glowColorDirty: normalizedPendingGlowColor !== ShellConfig.ringGlowColor

    function resetGlowColor() {
        pendingGlowColor = ShellConfig.ringGlowColor
    }

    Column {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        spacing: 20

        Text {
            text: "Thème"
            color: ShellTheme.textSecondary
            font.pixelSize: 12
            font.weight: Font.DemiBold
            leftPadding: 2
        }

        Item {
            width: parent.width
            height: themeCards.implicitHeight

            Row {
                id: themeCards

                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                ThemePreviewCard {
                    themeId: ShellConfig.liquidGlassTheme
                    onClicked: ShellConfig.saveTheme(ShellConfig.liquidGlassTheme)
                }

                ThemePreviewCard {
                    themeId: ShellConfig.ffxivTheme
                    onClicked: ShellConfig.saveTheme(ShellConfig.ffxivTheme)
                }
            }
        }

        Column {
            width: Math.min(parent.width, 560)
            spacing: 12

            Text {
                text: "Glow du ring"
                color: ShellTheme.textSecondary
                font.pixelSize: 12
                font.weight: Font.DemiBold
                leftPadding: 2
            }

            Row {
                width: parent.width
                spacing: 14

                Rectangle {
                    width: 72
                    height: 44
                    radius: ShellTheme.controlRadius
                    antialiasing: true
                    color: Qt.rgba(root.pendingGlowBase.r, root.pendingGlowBase.g, root.pendingGlowBase.b, 0.18)
                    border.width: 1
                    border.color: Qt.rgba(root.pendingGlowBase.r, root.pendingGlowBase.g, root.pendingGlowBase.b, 0.82)

                    Rectangle {
                        anchors.centerIn: parent
                        width: 46
                        height: 6
                        radius: 3
                        antialiasing: true
                        color: Qt.rgba(root.pendingGlowBase.r, root.pendingGlowBase.g, root.pendingGlowBase.b, 0.82)
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 62
                        height: 20
                        radius: 10
                        antialiasing: true
                        color: "transparent"
                        border.width: 6
                        border.color: Qt.rgba(root.pendingGlowBase.r, root.pendingGlowBase.g, root.pendingGlowBase.b, 0.24)
                    }
                }

                Column {
                    width: parent.width - 86
                    spacing: 10

                    Row {
                        spacing: 8

                        GlowSwatch { colorValue: "#46ff96" }
                        GlowSwatch { colorValue: "#00e5ff" }
                        GlowSwatch { colorValue: "#a970ff" }
                        GlowSwatch { colorValue: "#ff4fd8" }
                        GlowSwatch { colorValue: "#ffcc45" }
                    }

                    Row {
                        spacing: 10

                        GlowColorField {
                            width: 168
                            text: root.pendingGlowColor
                            onEdited: root.pendingGlowColor = value
                        }

                        SettingsButton {
                            text: "Appliquer"
                            enabled: root.glowColorDirty
                            primary: true
                            onClicked: ShellConfig.saveRingGlowColor(root.normalizedPendingGlowColor)
                        }

                        SettingsButton {
                            text: "Réinitialiser"
                            enabled: ShellConfig.ringGlowColor !== ShellConfig.defaultRingGlowColor
                                || root.glowColorDirty
                            onClicked: {
                                root.pendingGlowColor = ShellConfig.defaultRingGlowColor
                                ShellConfig.saveRingGlowColor(ShellConfig.defaultRingGlowColor)
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: ShellConfig

        function onRingGlowColorChanged() {
            if (!root.glowColorDirty) {
                root.pendingGlowColor = ShellConfig.ringGlowColor
            }
        }
    }

    component GlowSwatch: Item {
        id: swatchRoot

        required property string colorValue
        readonly property bool selected: ShellConfig.ringGlowColor === colorValue

        width: 28
        height: 28

        Rectangle {
            anchors.fill: parent
            radius: 14
            antialiasing: true
            color: swatchRoot.colorValue
            border.width: swatchRoot.selected ? 2 : 1
            border.color: swatchRoot.selected
                ? ShellTheme.textPrimary
                : ShellTheme.controlBorder
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.pendingGlowColor = swatchRoot.colorValue
                ShellConfig.saveRingGlowColor(swatchRoot.colorValue)
            }
        }
    }

    component GlowColorField: Item {
        id: fieldRoot

        property string text: ""
        signal edited(string value)

        implicitWidth: 168
        implicitHeight: 38

        Rectangle {
            anchors.fill: parent
            radius: ShellTheme.controlRadius
            antialiasing: true
            color: input.activeFocus
                ? ShellTheme.controlFillTopActive
                : ShellTheme.controlFillTop
            border.width: 1
            border.color: /^#?[0-9a-fA-F]{3}([0-9a-fA-F]{3})?$/.test(input.text)
                ? input.activeFocus ? ShellTheme.controlBorderActive : ShellTheme.controlBorder
                : ShellTheme.criticalControlBorder

            TextInput {
                id: input

                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    right: parent.right
                    leftMargin: 14
                    rightMargin: 14
                }
                text: fieldRoot.text
                color: ShellTheme.textPrimary
                selectionColor: ShellTheme.controlBorderActive
                selectedTextColor: ShellTheme.textPrimary
                font.pixelSize: 13
                font.capitalization: Font.AllUppercase
                maximumLength: 7
                clip: true
                onTextEdited: fieldRoot.edited(text)
            }
        }
    }

    component SettingsButton: Item {
        id: buttonRoot

        property string text: ""
        property bool primary: false
        signal clicked()

        implicitWidth: Math.max(106, buttonText.implicitWidth + 28)
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
