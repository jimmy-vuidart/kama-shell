import QtQuick

import "../state"
import "settings"

Item {
    id: root

    readonly property string section: SettingsState.selectedSection

    Item {
        anchors {
            fill: parent
            margins: 28
        }

        Column {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            spacing: 24

            Text {
                text: root.section === "appearance"
                    ? "Apparence"
                    : root.section === "home"
                        ? "Maison"
                        : root.section
                color: ShellTheme.textPrimary
                font.pixelSize: 20
                font.weight: Font.Bold
                style: ShellTheme.isFfxiv ? Text.Raised : Text.Normal
                styleColor: ShellTheme.textShadow
            }

            Loader {
                width: parent.width

                sourceComponent: {
                    if (root.section === "appearance") {
                        return appearanceComponent
                    }
                    if (root.section === "home") {
                        return homeComponent
                    }
                    return null
                }
            }
        }
    }

    Component {
        id: appearanceComponent
        AppearanceSection {}
    }

    Component {
        id: homeComponent
        HomeSection {}
    }
}
