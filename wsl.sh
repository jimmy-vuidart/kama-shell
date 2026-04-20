#!/usr/bin/env bash
# Script de lancement Hyprland (nested WSLg) + Quickshell

set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_FILE="$ROOT_DIR/shell.qml"
LOG_DIR="${TMPDIR:-/tmp}/glass-shell"
HYPR_LOG="$LOG_DIR/hyprland.log"
QS_LOG="$LOG_DIR/quickshell.log"

mkdir -p "$LOG_DIR"

info() {
    printf '[INFO] %s\n' "$*"
}

warn() {
    printf '[WARN] %s\n' "$*"
}

err() {
    printf '[ERR ] %s\n' "$*" >&2
}

die() {
    err "$*"
    exit 1
}

require_cmd() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1 || die "Commande manquante: $cmd"
}

ensure_runtime_dir() {
    if [ -z "${XDG_RUNTIME_DIR:-}" ]; then
        export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    fi

    if ! mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null; then
        if [ -n "${WSL_DISTRO_NAME:-}" ] && [ -d "/mnt/wslg/runtime-dir" ]; then
            warn "XDG_RUNTIME_DIR inaccessible, fallback vers /mnt/wslg/runtime-dir"
            export XDG_RUNTIME_DIR="/mnt/wslg/runtime-dir"
        else
            die "Impossible de créer XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
        fi
    fi

    chmod 700 "$XDG_RUNTIME_DIR" 2>/dev/null || true
}

ensure_parent_socket_access() {
    if [ -S "$XDG_RUNTIME_DIR/$PARENT_WAYLAND" ]; then
        return
    fi

    if [ -n "${PARENT_SOCKET_PATH:-}" ] && [ -S "$PARENT_SOCKET_PATH" ]; then
        ln -snf "$PARENT_SOCKET_PATH" "$XDG_RUNTIME_DIR/$PARENT_WAYLAND" || {
            die "Impossible de relier le socket parent $PARENT_SOCKET_PATH vers $XDG_RUNTIME_DIR/$PARENT_WAYLAND"
        }
        info "Socket parent relié: $XDG_RUNTIME_DIR/$PARENT_WAYLAND -> $PARENT_SOCKET_PATH"
        return
    fi

    die "Socket Wayland parent inaccessible dans $XDG_RUNTIME_DIR"
}

detect_parent_wayland() {
    if [ -n "${WSL_DISTRO_NAME:-}" ] && [ -S "/mnt/wslg/runtime-dir/wayland-0" ]; then
        PARENT_WAYLAND="wayland-0"
        PARENT_SOCKET_PATH="/mnt/wslg/runtime-dir/$PARENT_WAYLAND"
        return
    fi

    if [ -n "${WAYLAND_DISPLAY:-}" ] && [ -S "$XDG_RUNTIME_DIR/${WAYLAND_DISPLAY}" ]; then
        PARENT_WAYLAND="$WAYLAND_DISPLAY"
        PARENT_SOCKET_PATH="$XDG_RUNTIME_DIR/$PARENT_WAYLAND"
        return
    fi

    if [ -S "$XDG_RUNTIME_DIR/wayland-0" ]; then
        PARENT_WAYLAND="wayland-0"
        PARENT_SOCKET_PATH="$XDG_RUNTIME_DIR/$PARENT_WAYLAND"
        return
    fi

    if [ -S "/mnt/wslg/runtime-dir/wayland-0" ]; then
        PARENT_WAYLAND="wayland-0"
        PARENT_SOCKET_PATH="/mnt/wslg/runtime-dir/$PARENT_WAYLAND"
        return
    fi

    die "Aucun socket Wayland parent détecté. Vérifie que WSLg fonctionne (teste une app GUI Linux)."
}

find_hyprland_socket() {
    local baseline="$1"
    local timeout="${2:-20}"
    local i
    local candidate

    for ((i=0; i<timeout; i++)); do
        for candidate in "$XDG_RUNTIME_DIR"/wayland-*; do
            [ -S "$candidate" ] || continue
            candidate="$(basename "$candidate")"
            if [[ " $baseline " != *" $candidate "* ]] && [ "$candidate" != "$PARENT_WAYLAND" ]; then
                printf '%s\n' "$candidate"
                return 0
            fi
        done
        sleep 1
    done

    return 1
}

collect_wayland_sockets() {
    local entries=()
    local path
    for path in "$XDG_RUNTIME_DIR"/wayland-*; do
        [ -S "$path" ] && entries+=("$(basename "$path")")
    done
    printf '%s\n' "${entries[*]:-}"
}

print_diagnostics() {
    info "Diagnostics WSL/Wayland"
    info "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-<unset>}"
    info "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-<unset>}"
    info "Parent Wayland socket=${PARENT_SOCKET_PATH:-<unset>}"
    info "WSL_DISTRO_NAME=${WSL_DISTRO_NAME:-<unset>}"
    info "Sockets Wayland: $(collect_wayland_sockets)"
    info "Hyprland log: $HYPR_LOG"
    info "Quickshell log: $QS_LOG"
}

fix_mesa_wsl() {
    # WSLg: Weston ne partage pas le DRM device → forcer software renderer pour Qt
    export LIBGL_ALWAYS_SOFTWARE=1
    export GALLIUM_DRIVER=llvmpipe
    export QT_OPENGL=software
    export QT_QUICK_BACKEND=software
    info "Mesa: software renderer (llvmpipe) + Qt software OpenGL"
}

find_hyprland_existing_socket() {
    local path
    for path in "$XDG_RUNTIME_DIR"/wayland-*; do
        [ -S "$path" ] || continue
        local name
        name="$(basename "$path")"
        # Exclure le socket parent WSLg
        [ "$name" = "$PARENT_WAYLAND" ] && continue
        # Vérifier si c'est Hyprland via hyprctl
        if HYPRLAND_INSTANCE_SIGNATURE="" WAYLAND_DISPLAY="$name" hyprctl monitors &>/dev/null 2>&1; then
            printf '%s\n' "$name"
            return 0
        fi
    done
    return 1
}

launch_quickshell() {
    local hyprland_socket="$1"

    export WAYLAND_DISPLAY="$hyprland_socket"
    export QT_QPA_PLATFORM=wayland
    export XDG_CURRENT_DESKTOP=Hyprland
    export XDG_SESSION_TYPE=wayland
    export LANG="${LANG:-C.UTF-8}"

    fix_mesa_wsl

    info "Lancement Quickshell sur $WAYLAND_DISPLAY"
    if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
        dbus-run-session quickshell --path "$SHELL_FILE" 2>&1 | tee "$QS_LOG"
    else
        quickshell --path "$SHELL_FILE" 2>&1 | tee "$QS_LOG"
    fi
}

start_sway_nested() {
    local baseline_sockets="$1"

    export WLR_BACKENDS=wayland
    export WLR_RENDERER=pixman
    export WLR_LIBINPUT_NO_DEVICES=1
    export LIBGL_ALWAYS_SOFTWARE=1
    export XDG_SESSION_TYPE=wayland
    export XDG_CURRENT_DESKTOP=sway

    info "Lancement sway nested (parent=$PARENT_WAYLAND)"
    WAYLAND_DISPLAY="$PARENT_WAYLAND" sway --unsupported-gpu >"$LOG_DIR/sway.log" 2>&1 &
    SWAY_PID=$!

    sleep 2
    if ! kill -0 "$SWAY_PID" 2>/dev/null; then
        tail -n 40 "$LOG_DIR/sway.log" 2>/dev/null || true
        die "Sway a quitté immédiatement. Voir $LOG_DIR/sway.log"
    fi

    HYPRLAND_SOCKET="$(find_hyprland_socket "$baseline_sockets" 15)" || {
        tail -n 40 "$LOG_DIR/sway.log" 2>/dev/null || true
        die "Socket sway introuvable. Voir $LOG_DIR/sway.log"
    }

    info "Socket sway détecté: $HYPRLAND_SOCKET"
}

start_hyprland_nested() {
    local baseline_sockets="$1"

    export WLR_BACKENDS=wayland
    export WLR_LIBINPUT_NO_DEVICES=1
    export WLR_NO_HARDWARE_CURSORS=1
    export WLR_RENDERER_ALLOW_SOFTWARE=1
    export QT_QPA_PLATFORM=wayland
    export XDG_SESSION_TYPE=wayland
    export XDG_CURRENT_DESKTOP=Hyprland

    info "Lancement Hyprland nested (parent=$PARENT_WAYLAND)"
    WAYLAND_DISPLAY="$PARENT_WAYLAND" Hyprland >"$HYPR_LOG" 2>&1 &
    HYPR_PID=$!

    sleep 1
    if ! kill -0 "$HYPR_PID" 2>/dev/null; then
        tail -n 80 "$HYPR_LOG" 2>/dev/null || true
        die "Hyprland a quitté immédiatement. Voir $HYPR_LOG"
    fi

    HYPRLAND_SOCKET="$(find_hyprland_socket "$baseline_sockets" 25)" || {
        tail -n 80 "$HYPR_LOG" 2>/dev/null || true
        die "Socket Hyprland introuvable. Voir $HYPR_LOG"
    }

    info "Socket Hyprland détecté: $HYPRLAND_SOCKET"
}

main() {
    local mode="sway"
    while [[ "${1:-}" == --* ]]; do
        case "$1" in
            --direct)   mode="direct"; shift ;;
            --sway)     mode="sway";   shift ;;
            --hyprland) mode="hypr";   shift ;;
            *) die "Option inconnue: $1 (valides: --direct, --sway, --hyprland)" ;;
        esac
    done

    require_cmd quickshell
    require_cmd dbus-run-session

    [ -f "$SHELL_FILE" ] || die "Fichier introuvable: $SHELL_FILE"

    ensure_runtime_dir
    detect_parent_wayland
    ensure_parent_socket_access

    if [ -z "${WSL_DISTRO_NAME:-}" ]; then
        warn "WSL_DISTRO_NAME absent: ce script est prévu pour WSL2 + WSLg"
    fi

    local baseline_sockets
    baseline_sockets="$(collect_wayland_sockets)"

    case "$mode" in
        direct)
            info "Mode direct: Quickshell sur $PARENT_WAYLAND (sans compositeur nested)"
            launch_quickshell "$PARENT_WAYLAND"
            ;;
        sway)
            require_cmd sway
            start_sway_nested "$baseline_sockets"
            print_diagnostics
            launch_quickshell "$HYPRLAND_SOCKET"
            ;;
        hypr)
            require_cmd Hyprland
            start_hyprland_nested "$baseline_sockets"
            print_diagnostics
            launch_quickshell "$HYPRLAND_SOCKET"
            ;;
    esac
}

main "$@"
