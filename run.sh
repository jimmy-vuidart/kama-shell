#!/usr/bin/env bash
# run.sh — Kama-Shell runner

# KAMA_DEV=1 conditionne l'overlay de debug dans les phases futures
export KAMA_DEV=${KAMA_DEV:-1}

exec quickshell -p ./src/shell.qml "$@"
