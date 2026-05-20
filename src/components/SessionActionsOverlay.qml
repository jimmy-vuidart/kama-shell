import Quickshell
import Quickshell.Wayland
import QtQuick

import "../state"

Variants {
    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: window

            required property var modelData

            readonly property bool panelVisible: SessionActionsState.shouldShowOnScreen(modelData)
            readonly property bool backgroundBlurEnabled: panelVisible
                && ShellTheme.isLiquidGlass
                && CompositorState.supportsBackgroundEffect

            screen: modelData
            visible: panelVisible
            focusable: panelVisible
            color: "transparent"
            surfaceFormat.opaque: false
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "kama-shell-session-actions"
            WlrLayershell.keyboardFocus: panelVisible
                ? WlrKeyboardFocus.OnDemand
                : WlrKeyboardFocus.None

            BackgroundEffect.blurRegion: window.backgroundBlurEnabled ? sessionActionsBlurRegion : null

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            function refreshSessionActionsBlurRegion() {
                if (window.backgroundBlurEnabled) {
                    sessionActionsBlurRegion.changed()
                }
            }

            function panelX(panelWidth) {
                const anchor = SessionActionsState.anchorRect
                const desired = anchor.x + anchor.width - panelWidth

                return window.clamp(desired, 8, window.width - panelWidth - 8)
            }

            function panelY(panelHeight) {
                const anchor = SessionActionsState.anchorRect
                const above = anchor.y - panelHeight - 10
                const below = anchor.y + anchor.height + 10

                if (above >= 8) {
                    return above
                }

                return window.clamp(below, 8, window.height - panelHeight - 8)
            }

            function clamp(value, minValue, maxValue) {
                return Math.max(minValue, Math.min(value, Math.max(minValue, maxValue)))
            }

            onBackgroundBlurEnabledChanged: Qt.callLater(refreshSessionActionsBlurRegion)
            onWidthChanged: Qt.callLater(refreshSessionActionsBlurRegion)
            onHeightChanged: Qt.callLater(refreshSessionActionsBlurRegion)

            Region {
                id: sessionActionsBlurRegion

                Region {
                    x: Math.floor(panelLoader.item ? panelLoader.item.x : 0)
                    y: Math.floor(panelLoader.item ? panelLoader.item.y : 0)
                    width: Math.ceil(panelLoader.item ? panelLoader.item.width : 0)
                    height: Math.ceil(panelLoader.item ? panelLoader.item.height : 0)
                    radius: Math.ceil(ShellTheme.isFfxiv ? 8 : 22)
                }
            }

            Item {
                anchors.fill: parent
                focus: window.panelVisible

                Keys.onEscapePressed: SessionActionsState.hide()

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    enabled: !SessionActionsState.busy
                    onPressed: SessionActionsState.hide()
                }

                Loader {
                    id: panelLoader

                    active: window.panelVisible
                    sourceComponent: SessionActionsPanel {
                        id: sessionActionsPanel

                        compositorBlurActive: window.backgroundBlurEnabled
                        x: window.panelX(width)
                        y: window.panelY(height)
                        onXChanged: Qt.callLater(window.refreshSessionActionsBlurRegion)
                        onYChanged: Qt.callLater(window.refreshSessionActionsBlurRegion)
                        onWidthChanged: Qt.callLater(window.refreshSessionActionsBlurRegion)
                        onHeightChanged: Qt.callLater(window.refreshSessionActionsBlurRegion)
                    }
                }
            }
        }
    }
}
