#!/usr/bin/env bash
# run.sh — Kama-Shell runner

set -euo pipefail

# KAMA_DEV=1 conditionne l'overlay de debug dans les phases futures
export KAMA_DEV=${KAMA_DEV:-1}

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
SHELL_ENTRY="$SCRIPT_DIR/src/shell.qml"

is_gnome_session() {
    local desktop="${XDG_CURRENT_DESKTOP:-}"
    local session="${DESKTOP_SESSION:-}"
    local mode="${GNOME_SHELL_SESSION_MODE:-}"

    [[ "$desktop" == *GNOME* ]] || [[ "$session" == *gnome* ]] || [[ -n "$mode" ]]
}

run_quickshell() {
    exec quickshell -p "$SHELL_ENTRY" "$@"
}

run_nested_hyprland() {
    if ! command -v Hyprland >/dev/null 2>&1; then
        echo "Hyprland introuvable, lancement direct de Quickshell." >&2
        run_quickshell "$@"
    fi

    local tmpdir config args_escaped
    tmpdir=$(mktemp -d)
    config="$tmpdir/hyprland.conf"
    args_escaped=$(printf '%q ' "$@")

    cat >"$config" <<EOF
monitor=,preferred,auto,1

general {
    border_size = 0
    gaps_in = 0
    gaps_out = 0
}

decoration {
    rounding = 0
    shadow:enabled = false
    blur:enabled = false
}

animations {
    enabled = false
}

misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
    vrr = 0
}

input {
    follow_mouse = 1
}

bind = SUPER, escape, exit
exec-once = bash -lc 'cd $(printf '%q' "$SCRIPT_DIR") && KAMA_NESTED_HYPRLAND=1 "$SCRIPT_DIR/run.sh" $args_escaped'
EOF

    WLR_BACKENDS=wayland Hyprland --config "$config"
    local status=$?
    rm -rf "$tmpdir"
    return "$status"
}

if [[ "${KAMA_NESTED_HYPRLAND:-0}" == "1" ]]; then
    run_quickshell "$@"
fi

if [[ -n "${WAYLAND_DISPLAY:-}" ]] && is_gnome_session; then
    run_nested_hyprland "$@"
fi

run_quickshell "$@"
