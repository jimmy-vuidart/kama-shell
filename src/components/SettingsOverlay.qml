import Quickshell
import Quickshell.Wayland
import QtQuick

import "../state"

Variants {
    model: Quickshell.screens

    delegate: Component {
        Item {
            id: root

            required property var modelData

            PanelWindow {
                id: window

                screen: root.modelData
                readonly property bool settingsVisible: SettingsState.shouldShowOnScreen(root.modelData)

                visible: settingsVisible
                focusable: settingsVisible
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "kama-shell-settings"
                WlrLayershell.keyboardFocus: settingsVisible
                    ? WlrKeyboardFocus.Exclusive
                    : WlrKeyboardFocus.None

                readonly property bool backgroundBlurEnabled: settingsVisible
                    && ShellTheme.isLiquidGlass
                    && CompositorState.supportsBackgroundEffect

                mask: settingsInputRegion
                BackgroundEffect.blurRegion: window.backgroundBlurEnabled ? settingsBlurRegion : null

                function refreshSettingsBlurRegion() {
                    if (window.backgroundBlurEnabled) {
                        settingsBlurRegion.changed()
                    }
                }

                function refreshSettingsInputRegion() {
                    settingsInputRegion.changed()
                }

                function focusOverlay() {
                    if (!window.settingsVisible) {
                        return
                    }

                    Qt.callLater(function() {
                        overlayContent.forceActiveFocus()
                    })
                }

                onSettingsVisibleChanged: {
                    Qt.callLater(refreshSettingsInputRegion)
                    Qt.callLater(refreshSettingsBlurRegion)
                    focusOverlay()
                }
                onBackgroundBlurEnabledChanged: Qt.callLater(refreshSettingsBlurRegion)
                onWidthChanged: {
                    Qt.callLater(refreshSettingsBlurRegion)
                    Qt.callLater(refreshSettingsInputRegion)
                }
                onHeightChanged: {
                    Qt.callLater(refreshSettingsBlurRegion)
                    Qt.callLater(refreshSettingsInputRegion)
                }

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                color: "transparent"
                surfaceFormat.opaque: false

                Region {
                    id: settingsInputRegion

                    Region {
                        x: 0
                        y: 0
                        width: window.settingsVisible ? Math.ceil(window.width) : 0
                        height: window.settingsVisible ? Math.ceil(window.height) : 0
                    }
                }

                Region {
                    id: settingsBlurRegion

                    Region {
                        x: Math.floor(settingsPanel.x)
                        y: Math.floor(settingsPanel.y)
                        width: Math.ceil(settingsPanel.width)
                        height: Math.ceil(settingsPanel.height)
                        radius: Math.ceil(ShellTheme.isFfxiv ? 10 : 28)
                    }
                }

                Item {
                    id: overlayContent

                    anchors.fill: parent
                    visible: window.settingsVisible
                    enabled: window.settingsVisible
                    focus: window.settingsVisible

                    Keys.priority: Keys.BeforeItem
                    Keys.onEscapePressed: SettingsState.hide()

                    readonly property color scrimColor: Qt.rgba(0, 0, 0, ShellTheme.isFfxiv ? 0.34 : 0.18)

                    Rectangle {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                        }
                        height: Math.max(0, settingsPanel.y)
                        color: parent.scrimColor

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.AllButtons
                            onPressed: function(mouse) {
                                mouse.accepted = true
                                SettingsState.hide()
                            }
                        }
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: Math.max(0, parent.height - settingsPanel.y - settingsPanel.height)
                        color: parent.scrimColor

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.AllButtons
                            onPressed: function(mouse) {
                                mouse.accepted = true
                                SettingsState.hide()
                            }
                        }
                    }

                    Rectangle {
                        x: 0
                        y: settingsPanel.y
                        width: Math.max(0, settingsPanel.x)
                        height: settingsPanel.height
                        color: parent.scrimColor

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.AllButtons
                            onPressed: function(mouse) {
                                mouse.accepted = true
                                SettingsState.hide()
                            }
                        }
                    }

                    Rectangle {
                        x: settingsPanel.x + settingsPanel.width
                        y: settingsPanel.y
                        width: Math.max(0, parent.width - settingsPanel.x - settingsPanel.width)
                        height: settingsPanel.height
                        color: parent.scrimColor

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.AllButtons
                            onPressed: function(mouse) {
                                mouse.accepted = true
                                SettingsState.hide()
                            }
                        }
                    }

                    SettingsPanel {
                        id: settingsPanel

                        anchors.centerIn: parent
                        width: Math.min(1100, Math.max(640, window.width - 80))
                        height: Math.min(680, Math.max(420, window.height - 120))
                        active: window.settingsVisible

                        onXChanged: Qt.callLater(window.refreshSettingsBlurRegion)
                        onYChanged: Qt.callLater(window.refreshSettingsBlurRegion)
                        onWidthChanged: Qt.callLater(window.refreshSettingsBlurRegion)
                        onHeightChanged: Qt.callLater(window.refreshSettingsBlurRegion)
                    }
                }
            }
        }
    }
}
