import Quickshell
import QtQuick

import "../state"

Item {
    id: root

    property bool active: false

    function focusPanel() {
        if (!root.active) {
            return
        }

        Qt.callLater(function() {
            panelFocusItem.forceActiveFocus()
        })
    }

    onActiveChanged: {
        if (active) {
            root.focusPanel()
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons

        onClicked: function(mouse) {
            mouse.accepted = true
        }
    }

    ThemedPanelSurface {
        anchors.fill: parent
        radius: ShellTheme.isFfxiv ? 10 : 28
        padding: 0
        clipContent: true
        compositorBlurActive: root.active
            && ShellTheme.isLiquidGlass
            && CompositorState.supportsBackgroundEffect

        Item {
            id: panelFocusItem

            anchors.fill: parent
            focus: root.active

            Keys.onEscapePressed: SettingsState.hide()

            Row {
                anchors.fill: parent
                spacing: 0

                SettingsMenu {
                    height: parent.height
                }

                SettingsContent {
                    width: parent.width - 240
                    height: parent.height
                }
            }
        }
    }
}
