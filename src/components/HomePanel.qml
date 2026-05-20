import QtQuick

import "../state"

Item {
    id: root

    readonly property real revealTarget: panelHover.hovered ? 1 : 0
    property int animationDuration: 150
    property real revealProgress: 0
    readonly property real revealVelocity: 0
    readonly property real currentWidth: ShellGeometry.homePanelHandleWidth
        + ((ShellGeometry.homePanelExpandedWidth - ShellGeometry.homePanelHandleWidth) * revealProgress)
    readonly property real currentHeight: ShellGeometry.homePanelHandleHeight
        + ((ShellGeometry.homePanelExpandedHeight - ShellGeometry.homePanelHandleHeight) * revealProgress)

    width: currentWidth
    height: currentHeight
    clip: true

    onRevealTargetChanged: revealProgress = revealTarget

    Behavior on revealProgress {
        NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutCubic
        }
    }

    HoverHandler {
        id: panelHover
    }

    Column {
        id: contentColumn

        anchors {
            fill: parent
            leftMargin: ShellGeometry.homePanelContentLeftMargin
            rightMargin: ShellGeometry.homePanelContentRightMargin
            topMargin: ShellGeometry.homePanelContentTopMargin
            bottomMargin: ShellGeometry.homePanelContentBottomMargin
        }
        spacing: 12
        opacity: Math.max(0, (root.revealProgress - 0.28) / 0.72)
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }

        Row {
            id: header

            width: parent.width
            height: 58
            spacing: 12

            Rectangle {
                width: 40
                height: 40
                radius: ShellTheme.controlRadius
                antialiasing: true
                color: ShellTheme.controlFillTopActive
                border.width: ShellTheme.controlBorderWidth
                border.color: ShellTheme.controlBorderActive

                HouseIcon {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                }
            }

            Column {
                width: parent.width - 40 - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: "Maison"
                    color: ShellTheme.textPrimary
                    elide: Text.ElideRight
                    font.pixelSize: 20
                    font.weight: Font.Bold
                    style: ShellTheme.controlTextStyle
                    styleColor: ShellTheme.textShadow
                }

                Text {
                    width: parent.width
                    text: {
                        if (!HomeAssistantState.isConfigured)
                            return "Non configuré"
                        if (HomeAssistantState.loading && HomeAssistantState.rooms.length === 0)
                            return "Chargement…"
                        if (HomeAssistantState.error.length > 0)
                            return HomeAssistantState.error
                        const n = HomeAssistantState.rooms.length
                        return n + " pièce" + (n > 1 ? "s" : "") + " connectée" + (n > 1 ? "s" : "")
                    }
                    color: ShellTheme.textSecondary
                    elide: Text.ElideRight
                    font.pixelSize: 12
                    style: ShellTheme.controlTextStyle
                    styleColor: ShellTheme.textShadow
                }
            }
        }

        // Status message when not configured or in error
        Item {
            width: parent.width
            height: parent.height - header.height - parent.spacing
            visible: !HomeAssistantState.isConfigured
                || (HomeAssistantState.rooms.length === 0 && HomeAssistantState.error.length > 0)
                || (HomeAssistantState.rooms.length === 0 && HomeAssistantState.loading)

            Column {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        if (!HomeAssistantState.isConfigured)
                            return "⚙"
                        if (HomeAssistantState.loading)
                            return "⟳"
                        return "⚠"
                    }
                    color: ShellTheme.textSecondary
                    font.pixelSize: 28
                    style: ShellTheme.controlTextStyle
                    styleColor: ShellTheme.textShadow
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: {
                        if (!HomeAssistantState.isConfigured)
                            return "Configurez Home Assistant\ndans les paramètres"
                        if (HomeAssistantState.loading)
                            return "Connexion à Home Assistant…"
                        return HomeAssistantState.error
                    }
                    color: ShellTheme.textSecondary
                    font.pixelSize: 12
                    style: ShellTheme.controlTextStyle
                    styleColor: ShellTheme.textShadow
                }
            }
        }

        Text {
            width: parent.width
            height: 16
            text: "Pièces"
            color: ShellTheme.textSecondary
            font.pixelSize: 11
            font.weight: Font.DemiBold
            style: ShellTheme.controlTextStyle
            styleColor: ShellTheme.textShadow
            visible: HomeAssistantState.isConfigured && HomeAssistantState.rooms.length > 0
        }

        Flickable {
            width: parent.width
            height: parent.height - header.height - 16 - (parent.spacing * 2)
            contentWidth: width
            contentHeight: roomList.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            visible: HomeAssistantState.isConfigured && HomeAssistantState.rooms.length > 0

            Column {
                id: roomList

                width: parent.width
                spacing: ShellGeometry.homePanelRoomGap

                Repeater {
                    model: HomeAssistantState.rooms

                    delegate: HomeRoomRow {
                        width: roomList.width
                    }
                }
            }
        }
    }
}
