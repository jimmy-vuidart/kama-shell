#!/usr/bin/env bash
# run.sh — Kama-Shell runner

set -euo pipefail

# KAMA_DEV=1 conditionne l'overlay de debug dans les phases futures
export KAMA_DEV=${KAMA_DEV:-1}

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
SHELL_ENTRY="$SCRIPT_DIR/src/shell.qml"
LOG_FILE="${KAMA_RUN_LOG_FILE:-}"

setup_logging() {
    if [[ -z "$LOG_FILE" ]]; then
        return
    fi

    mkdir -p -- "$(dirname -- "$LOG_FILE")"
    touch "$LOG_FILE"
    exec >>"$LOG_FILE" 2>&1
}

is_gnome_session() {
    local desktop="${XDG_CURRENT_DESKTOP:-}"
    local session="${DESKTOP_SESSION:-}"
    local mode="${GNOME_SHELL_SESSION_MODE:-}"

    [[ "$desktop" == *GNOME* ]] || [[ "$session" == *gnome* ]] || [[ -n "$mode" ]]
}

run_quickshell() {
    local quickshell_args=()
    local verbose_count=0
    local i

    if [[ "${KAMA_QS_LOG_TIMES:-0}" == "1" ]]; then
        quickshell_args+=(--log-times)
    fi

    if [[ -n "${KAMA_QS_LOG_RULES:-}" ]]; then
        quickshell_args+=(--log-rules "$KAMA_QS_LOG_RULES")
    fi

    if [[ -n "${KAMA_QS_DEBUG_PORT:-}" ]]; then
        quickshell_args+=(--debug "$KAMA_QS_DEBUG_PORT")
    fi

    if [[ "${KAMA_QS_WAIT_FOR_DEBUG:-0}" == "1" ]]; then
        quickshell_args+=(--waitfordebug)
    fi

    verbose_count=${KAMA_QS_VERBOSE:-0}
    for ((i = 0; i < verbose_count; i++)); do
        quickshell_args+=(-v)
    done

    exec quickshell "${quickshell_args[@]}" -p "$SHELL_ENTRY" "$@"
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
    setup_logging
    run_quickshell "$@"
fi

if [[ -n "${WAYLAND_DISPLAY:-}" ]] && is_gnome_session; then
    setup_logging
    run_nested_hyprland "$@"
fi

setup_logging
run_quickshell "$@"
