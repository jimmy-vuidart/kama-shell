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

    Item {
        id: contentItem

        anchors {
            fill: parent
            leftMargin: ShellGeometry.homePanelContentLeftMargin
            rightMargin: ShellGeometry.homePanelContentRightMargin
            topMargin: ShellGeometry.homePanelContentTopMargin
            bottomMargin: ShellGeometry.homePanelContentBottomMargin
        }
        opacity: Math.max(0, (root.revealProgress - 0.28) / 0.72)
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }

        // Header: house icon + title
        Row {
            id: header

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: 58
            spacing: 12

            Rectangle {
                width: 40
                height: 40
                anchors.verticalCenter: parent.verticalCenter
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
                        if (HomeAssistantState.error.length > 0 && HomeAssistantState.rooms.length === 0)
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

        // Body area — below header
        Item {
            anchors {
                left: parent.left
                right: parent.right
                top: header.bottom
                bottom: parent.bottom
                topMargin: 12
            }

            // Status message — when no rooms to display
            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: !HomeAssistantState.isConfigured
                    || HomeAssistantState.rooms.length === 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        if (!HomeAssistantState.isConfigured)
                            return "⚙"
                        if (HomeAssistantState.loading)
                            return "⟳"
                        if (HomeAssistantState.error.length > 0)
                            return "⚠"
                        return "✓"
                    }
                    color: ShellTheme.textSecondary
                    font.pixelSize: 28
                    style: ShellTheme.controlTextStyle
                    styleColor: ShellTheme.textShadow
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: contentItem.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: {
                        if (!HomeAssistantState.isConfigured)
                            return "Configurez Home Assistant\ndans les paramètres"
                        if (HomeAssistantState.loading)
                            return "Connexion à Home Assistant…"
                        if (HomeAssistantState.error.length > 0)
                            return HomeAssistantState.error
                        return "Aucune pièce connectée"
                    }
                    color: ShellTheme.textSecondary
                    font.pixelSize: 12
                    style: ShellTheme.controlTextStyle
                    styleColor: ShellTheme.textShadow
                }
            }

            // Rooms content — when rooms are available
            Item {
                anchors.fill: parent
                visible: HomeAssistantState.isConfigured && HomeAssistantState.rooms.length > 0

                Text {
                    id: sectionLabel

                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: 16
                    text: "Pièces"
                    color: ShellTheme.textSecondary
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    style: ShellTheme.controlTextStyle
                    styleColor: ShellTheme.textShadow
                }

                Flickable {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: sectionLabel.bottom
                        bottom: parent.bottom
                        topMargin: 12
                    }
                    contentWidth: width
                    contentHeight: roomList.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

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
    }
}
