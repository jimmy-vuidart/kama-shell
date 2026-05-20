import QtQuick

import "../../state"

Item {
    id: root

    required property string themeId
    property string themeName: themeId === ShellConfig.ffxivTheme ? "FFXIV" : "Liquid Glass"

    readonly property bool isSelected: ShellConfig.visualTheme === root.themeId

    signal clicked

    implicitWidth: 280
    implicitHeight: 180

    Rectangle {
        id: card

        anchors.fill: parent
        radius: 16
        antialiasing: true
        clip: true

        color: "transparent"
        border.width: root.isSelected ? 2 : 1.5
        border.color: root.isSelected
            ? ShellTheme.panelBorderHighlight
            : Qt.rgba(1, 1, 1, 0.18)

        Image {
            id: previewImage

            anchors.fill: parent
            anchors.margins: card.border.width
            source: Qt.resolvedUrl("../../assets/previews/theme-" + root.themeId + ".png")
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
            visible: status === Image.Ready
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: card.border.width
            visible: previewImage.status !== Image.Ready
            color: root.themeId === ShellConfig.ffxivTheme
                ? Qt.rgba(20 / 255, 19 / 255, 18 / 255, 1)
                : Qt.rgba(18 / 255, 24 / 255, 36 / 255, 1)

            Text {
                anchors.centerIn: parent
                text: root.themeName
                color: Qt.rgba(0.95, 0.98, 1, 0.6)
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: card.border.width
            }
            height: 36
            color: Qt.rgba(0, 0, 0, 0.52)

            Text {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: 12
                }
                text: root.themeName
                color: ShellTheme.textPrimary
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            Rectangle {
                anchors {
                    verticalCenter: parent.verticalCenter
                    right: parent.right
                    rightMargin: 12
                }
                width: 18
                height: 18
                radius: 9
                antialiasing: true
                color: root.isSelected ? ShellTheme.panelBorderHighlight : "transparent"
                border.width: 1.5
                border.color: root.isSelected
                    ? ShellTheme.panelBorderHighlight
                    : Qt.rgba(1, 1, 1, 0.4)

                Rectangle {
                    anchors.centerIn: parent
                    width: 8
                    height: 8
                    radius: 4
                    antialiasing: true
                    color: Qt.rgba(0.08, 0.1, 0.14, 1)
                    visible: root.isSelected
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: root.isSelected ? 2 : 0
            border.color: ShellTheme.panelBorderHighlight
            antialiasing: true
            visible: root.isSelected
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: root.clicked()
    }
}
