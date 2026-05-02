#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
APP_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
QS_PATH="${KAMA_QS_PATH:-}"
SHELL_ENTRY="${KAMA_SHELL_ENTRY:-$APP_DIR/src/shell.qml}"
SCREEN_NAME="${1:-}"

if [[ -z "$QS_PATH" ]]; then
    QS_PATH=$(command -v qs || true)
fi

QS_PATH="${QS_PATH:-/usr/bin/qs}"

if [[ -z "$SCREEN_NAME" ]] && [[ -n "${NIRI_SOCKET:-}" ]] && command -v niri >/dev/null 2>&1; then
    if command -v python3 >/dev/null 2>&1; then
        SCREEN_NAME=$(
            niri msg --json focused-output 2>/dev/null \
                | python3 -c 'import json, sys; print((json.load(sys.stdin) or {}).get("name", ""))' 2>/dev/null \
                || true
        )
    else
        SCREEN_NAME=$(
            niri msg --json focused-output 2>/dev/null \
                | sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
                || true
        )
    fi
fi

"$QS_PATH" ipc \
    --path "$SHELL_ENTRY" \
    --any-display \
    call kama-shell toggleLauncher "$SCREEN_NAME"
