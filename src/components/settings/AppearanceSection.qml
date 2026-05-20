import QtQuick

import "../../state"

Item {
    id: root

    implicitWidth: 400
    implicitHeight: 300

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
    }
}
