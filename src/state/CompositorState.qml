pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property string backendNiri: "niri"
    readonly property string backendGenericWlr: "generic-wlr"
    readonly property string backendUnknown: "unknown"

    readonly property string niriSocket: Quickshell.env("NIRI_SOCKET") || ""
    readonly property string kamaCompositor: (Quickshell.env("KAMA_COMPOSITOR") || "").toLowerCase()
    readonly property string currentDesktop: Quickshell.env("XDG_CURRENT_DESKTOP") || ""
    readonly property string sessionDesktop: Quickshell.env("XDG_SESSION_DESKTOP") || ""
    readonly property string waylandDisplay: Quickshell.env("WAYLAND_DISPLAY") || ""

    readonly property string backend: root.computeBackend()
    readonly property bool isNiri: root.backend === root.backendNiri
    readonly property bool isWayland: root.waylandDisplay.length > 0

    readonly property bool hasNativeToplevels: true
    readonly property bool hasNiriIpc: root.isNiri && root.niriSocket.length > 0
    readonly property bool hasLayerRules: root.isNiri
    readonly property bool supportsBackgroundEffect: root.isNiri

    function computeBackend() {
        if (root.kamaCompositor === root.backendNiri) {
            return root.backendNiri
        }

        if (root.kamaCompositor === root.backendGenericWlr) {
            return root.backendGenericWlr
        }

        if (root.niriSocket.length > 0) {
            return root.backendNiri
        }

        if (
            root.currentDesktop.toLowerCase().indexOf("niri") >= 0
            || root.sessionDesktop.toLowerCase().indexOf("niri") >= 0
        ) {
            return root.backendNiri
        }

        if (root.isWayland) {
            return root.backendGenericWlr
        }

        return root.backendUnknown
    }

    Component.onCompleted: {
        console.log(
            "kama-shell compositor backend=" + root.backend,
            "niriSocket=" + (root.niriSocket.length > 0 ? "yes" : "no"),
            "kamaCompositor=" + (root.kamaCompositor || "unset"),
            "currentDesktop=" + (root.currentDesktop || "unset")
        )
    }
}
