import QtQuick

import "../state"

Item {
    id: root

    readonly property var rooms: [
        { name: "Salon", status: "Ambiance soir", lightCount: 3, lightsOn: true, shutters: 72, temperature: 21.5 },
        { name: "Cuisine", status: "Préparation", lightCount: 2, lightsOn: true, shutters: 48, temperature: 20.0 },
        { name: "Chambre", status: "Nuit calme", lightCount: 1, lightsOn: false, shutters: 18, temperature: 18.5 },
        { name: "Bureau", status: "Concentration", lightCount: 2, lightsOn: true, shutters: 62, temperature: 20.5 }
    ]
    property real revealProgress: panelHover.hovered ? 1 : 0
    readonly property real currentWidth: ShellGeometry.homePanelHandleWidth
        + ((ShellGeometry.homePanelExpandedWidth - ShellGeometry.homePanelHandleWidth) * revealProgress)
    readonly property real currentHeight: ShellGeometry.homePanelHandleHeight
        + ((ShellGeometry.homePanelExpandedHeight - ShellGeometry.homePanelHandleHeight) * revealProgress)

    width: currentWidth
    height: currentHeight
    clip: true

    Behavior on revealProgress {
        NumberAnimation {
            duration: ShellGeometry.homePanelAnimationDuration
            easing.type: Easing.InOutCubic
        }
    }

    HoverHandler {
        id: panelHover
    }

    Column {
        id: contentColumn

        anchors {
            fill: parent
            margins: ShellTheme.panelPadding
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
                width: 46
                height: 46
                radius: ShellTheme.controlRadius
                antialiasing: true
                color: ShellTheme.controlFillTopActive
                border.width: ShellTheme.controlBorderWidth
                border.color: ShellTheme.controlBorderActive

                HouseIcon {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                }
            }

            Column {
                width: parent.width - 46 - parent.spacing
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
                    text: root.rooms.length + " pièces connectées"
                    color: ShellTheme.textSecondary
                    elide: Text.ElideRight
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
        }

        Flickable {
            width: parent.width
            height: parent.height - header.height - 16 - (parent.spacing * 2)
            contentWidth: width
            contentHeight: roomList.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: roomList

                width: parent.width
                spacing: ShellGeometry.homePanelRoomGap

                Repeater {
                    model: root.rooms

                    delegate: HomeRoomRow {
                        width: roomList.width
                    }
                }
            }
        }
    }
}
