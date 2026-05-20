pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property bool isConfigured: ShellConfig.homeAssistantUrl.length > 0
        && ShellConfig.homeAssistantToken.length > 0

    property var rooms: []
    property bool loading: false
    property string error: ""
    property bool connected: false
    property bool _refreshing: false

    // Jinja2 template: builds rooms with entity data, skipping areas without smart entities.
    // Uses state_attr() and is_state test (more reliable than map('states') in HA templates).
    readonly property string _haTemplate:
        "{% set r=namespace(rooms=[]) %}" +
        "{% for a in areas() %}" +
        "{% set dn=namespace(l=[],c=[],cl=[]) %}" +
        "{% for e in area_entities(a) %}" +
        "{% if e.startswith('light.') %}{% set dn.l=dn.l+[e] %}" +
        "{% elif e.startswith('cover.') %}{% set dn.c=dn.c+[e] %}" +
        "{% elif e.startswith('climate.') %}{% set dn.cl=dn.cl+[e] %}" +
        "{% endif %}{% endfor %}" +
        "{% if dn.l|count>0 or dn.c|count>0 or dn.cl|count>0 %}" +
        "{% set lon=dn.l|select('is_state','on')|list|count %}" +
        "{% set cp=state_attr(dn.c[0],'current_position')|default(-1) if dn.c else -1 %}" +
        "{% set ct=state_attr(dn.cl[0],'current_temperature')|default(-1) if dn.cl else -1 %}" +
        "{% set tt=state_attr(dn.cl[0],'temperature')|default(-1) if dn.cl else -1 %}" +
        "{% set r.rooms=r.rooms+[{" +
        "'id':a,'name':area_name(a)," +
        "'lightIds':dn.l,'lightsOnCount':lon,'lightsTotal':dn.l|count,'lightsOn':lon>0," +
        "'coverIds':dn.c,'coverPosition':cp," +
        "'climateIds':dn.cl,'temperature':ct,'targetTemperature':tt" +
        "}] %}" +
        "{% endif %}{% endfor %}" +
        "{{r.rooms|tojson}}"

    function refresh() {
        if (!root.isConfigured || root._refreshing) return
        root._refreshing = true
        if (root.rooms.length === 0) root.loading = true

        const url = ShellConfig.homeAssistantUrl + "/api/template"
        const token = ShellConfig.homeAssistantToken
        const xhr = new XMLHttpRequest()
        xhr.open("POST", url, true)
        xhr.setRequestHeader("Authorization", "Bearer " + token)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            root._refreshing = false
            root.loading = false
            if (xhr.status === 200) {
                try {
                    const parsed = JSON.parse(xhr.responseText)
                    if (Array.isArray(parsed)) {
                        root.rooms = parsed
                        root.connected = true
                        root.error = ""
                    } else {
                        root.error = "Format inattendu"
                    }
                } catch (e) {
                    root.error = "Réponse invalide"
                    console.warn("[HomeAssistant] parse error:", e.message,
                        xhr.responseText.slice(0, 200))
                }
            } else if (xhr.status === 0) {
                root.error = "Connexion impossible"
                root.connected = false
            } else if (xhr.status === 401) {
                root.error = "Token invalide"
                root.connected = false
            } else {
                root.error = "Erreur HTTP " + xhr.status
                root.connected = false
            }
        }
        xhr.send(JSON.stringify({ template: root._haTemplate }))
    }

    function _service(domain, service, data) {
        if (!root.isConfigured) return
        const url = ShellConfig.homeAssistantUrl + "/api/services/" + domain + "/" + service
        const token = ShellConfig.homeAssistantToken
        const xhr = new XMLHttpRequest()
        xhr.open("POST", url, true)
        xhr.setRequestHeader("Authorization", "Bearer " + token)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status >= 200 && xhr.status < 300) {
                delayedRefresh.restart()
            } else {
                console.warn("[HomeAssistant] service error:", domain, service, xhr.status)
            }
        }
        xhr.send(JSON.stringify(data))
    }

    function _roomIndexById(areaId) {
        for (let i = 0; i < root.rooms.length; i++) {
            if (root.rooms[i].id === areaId) return i
        }
        return -1
    }

    function _patch(areaId, patch) {
        const idx = _roomIndexById(areaId)
        if (idx < 0) return
        const updated = root.rooms.slice()
        updated[idx] = Object.assign({}, updated[idx], patch)
        root.rooms = updated
    }

    function toggleLights(areaId, currentlyOn) {
        const idx = _roomIndexById(areaId)
        if (idx < 0) return
        const total = root.rooms[idx].lightsTotal
        _patch(areaId, {
            lightsOn: !currentlyOn,
            lightsOnCount: currentlyOn ? 0 : total
        })
        _service("light", currentlyOn ? "turn_off" : "turn_on", { area_id: areaId })
    }

    function toggleCover(areaId, entityId, currentPosition) {
        // Open if closed or unknown, close if open
        const newPos = currentPosition > 0 ? 0 : 100
        _patch(areaId, { coverPosition: newPos })
        const service = newPos === 100 ? "open_cover" : "close_cover"
        _service("cover", service, { entity_id: entityId })
    }

    function adjustTargetTemperature(areaId, entityId, delta) {
        const idx = _roomIndexById(areaId)
        if (idx < 0 || !entityId) return
        const current = root.rooms[idx].targetTemperature
        if (current < 0) return
        const min = 10
        const max = 30
        const raw = current + delta
        const clamped = Math.max(min, Math.min(max, raw))
        const rounded = Math.round(clamped * 2) / 2
        _patch(areaId, { targetTemperature: rounded })
        _service("climate", "set_temperature", {
            entity_id: entityId,
            temperature: rounded
        })
    }

    Timer {
        id: refreshTimer
        interval: 30000
        repeat: true
        running: root.isConfigured
        onTriggered: root.refresh()
    }

    Timer {
        id: delayedRefresh
        interval: 1500
        repeat: false
        onTriggered: root.refresh()
    }

    Component.onCompleted: {
        if (root.isConfigured) root.refresh()
    }

    Connections {
        target: ShellConfig
        function onHomeAssistantUrlChanged() {
            root.rooms = []
            root.error = ""
            root.connected = false
            if (root.isConfigured) root.refresh()
        }
        function onHomeAssistantTokenChanged() {
            root.rooms = []
            root.error = ""
            root.connected = false
            if (root.isConfigured) root.refresh()
        }
    }
}
