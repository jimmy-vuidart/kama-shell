#!/usr/bin/env bash

set -euo pipefail

if ! command -v spectacle >/dev/null 2>&1; then
    echo "spectacle introuvable" >&2
    exit 1
fi

exec spectacle --background --fullscreen --copy-image --nonotify
