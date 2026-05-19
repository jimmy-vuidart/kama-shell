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

            readonly property bool osdVisible: OsdState.visible
            readonly property bool backgroundBlurEnabled: osdVisible
                && ShellTheme.isLiquidGlass
                && CompositorState.supportsBackgroundEffect

            screen: modelData
            visible: true
            color: "transparent"
            surfaceFormat.opaque: false
            exclusionMode: ExclusionMode.Ignore
            focusable: false
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "kama-shell-osd"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            mask: Region {}

            BackgroundEffect.blurRegion: window.backgroundBlurEnabled ? osdBlurRegion : null

            function refreshBlurRegion() {
                if (window.backgroundBlurEnabled) {
                    osdBlurRegion.changed()
                }
            }

            onBackgroundBlurEnabledChanged: Qt.callLater(refreshBlurRegion)
            onWidthChanged: Qt.callLater(refreshBlurRegion)
            onHeightChanged: Qt.callLater(refreshBlurRegion)

            Region {
                id: osdBlurRegion

                Region {
                    x: Math.floor(panel.x)
                    y: Math.floor(panel.y)
                    width: Math.ceil(panel.width)
                    height: Math.ceil(panel.height)
                    radius: Math.ceil(panel.height / 2)
                }
            }

            OsdPanel {
                id: panel

                readonly property int bottomMargin: 56
                property real slideOffset: window.osdVisible ? 0 : 10

                x: Math.round((window.width - width) / 2)
                y: window.height - height - bottomMargin
                compositorBlurActive: window.backgroundBlurEnabled

                opacity: window.osdVisible ? 1 : 0
                transform: Translate { y: panel.slideOffset }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on slideOffset {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                onXChanged: Qt.callLater(window.refreshBlurRegion)
                onYChanged: Qt.callLater(window.refreshBlurRegion)
                onWidthChanged: Qt.callLater(window.refreshBlurRegion)
                onHeightChanged: Qt.callLater(window.refreshBlurRegion)
            }
        }
    }
}
