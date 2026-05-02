#!/usr/bin/env bash

set -euo pipefail

if [[ -n "${NIRI_SOCKET:-}" ]] && command -v niri >/dev/null 2>&1; then
    exec niri msg action screenshot-screen --write-to-disk=false
fi

if ! command -v grim >/dev/null 2>&1; then
    echo "grim introuvable" >&2
    exit 1
fi

if ! command -v wl-copy >/dev/null 2>&1; then
    echo "wl-copy introuvable" >&2
    exit 1
fi

grim - | wl-copy
