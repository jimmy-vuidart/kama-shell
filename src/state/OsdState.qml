pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property int kindNone: 0
    readonly property int kindVolume: 1
    readonly property int kindBrightness: 2

    property int kind: kindNone
    property real level: 0
    property bool muted: false
    property bool visible: false

    property bool _ready: false

    function showVolume(vol, mut) {
        kind = kindVolume
        level = Math.max(0, Math.min(1, vol))
        muted = mut
        visible = true
        hideTimer.restart()
    }

    function showBrightness(lv) {
        kind = kindBrightness
        level = Math.max(0, Math.min(1, lv))
        muted = false
        visible = true
        hideTimer.restart()
    }

    function brightnessUp() {
        if (!brightnessUpProcess.running) {
            brightnessUpProcess.running = true
        }
    }

    function brightnessDown() {
        if (!brightnessDownProcess.running) {
            brightnessDownProcess.running = true
        }
    }

    function _parseBrightness(line) {
        const parts = String(line || "").trim().split(",")
        if (parts.length >= 4) {
            const pct = parseFloat(String(parts[3] || "0").replace("%", ""))
            if (isFinite(pct)) {
                root.showBrightness(pct / 100.0)
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 2500
        repeat: false
        onTriggered: root.visible = false
    }

    Component.onCompleted: {
        Qt.callLater(function() {
            root._ready = true
        })
    }

    Connections {
        target: StatusNotchState
        enabled: root._ready

        function onAudioVolumeChanged() {
            root.showVolume(StatusNotchState.audioVolume, StatusNotchState.audioMuted)
        }

        function onAudioMutedChanged() {
            root.showVolume(StatusNotchState.audioVolume, StatusNotchState.audioMuted)
        }
    }

    Process {
        id: brightnessUpProcess

        command: ["brightnessctl", "-m", "set", "5%+"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) { root._parseBrightness(line) }
        }
    }

    Process {
        id: brightnessDownProcess

        command: ["brightnessctl", "-m", "set", "5%-"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) { root._parseBrightness(line) }
        }
    }
}
