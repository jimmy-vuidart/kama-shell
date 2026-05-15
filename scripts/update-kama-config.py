#!/usr/bin/env python3
"""Update user-editable kama.conf values with an atomic write."""

from __future__ import annotations

import os
import sys
import tempfile


PINNED_KEYS = {"pinnedApps", "pinned"}


def update_pinned_apps(lines: list[str], value: str) -> list[str]:
    in_dock = False
    dock_line = -1
    pinned_line = -1

    for index, line in enumerate(lines):
        stripped = line.strip()

        if stripped == "[dock]":
            in_dock = True
            dock_line = index
            continue

        if stripped.startswith("[") and stripped.endswith("]"):
            in_dock = False
            continue

        if in_dock and "=" in stripped:
            key = stripped.split("=", 1)[0].strip()
            if key in PINNED_KEYS:
                pinned_line = index
                break

    next_line = f"pinnedApps = {value}\n"

    if pinned_line >= 0:
        lines[pinned_line] = next_line
        return lines

    if dock_line >= 0:
        lines.insert(dock_line + 1, next_line)
        return lines

    if lines and not lines[-1].endswith("\n"):
        lines.append("\n")

    if lines and lines[-1].strip():
        lines.append("\n")

    lines.extend(["[dock]\n", next_line])
    return lines


def write_atomic(path: str, lines: list[str]) -> None:
    target = os.path.abspath(path)
    directory = os.path.dirname(target)
    os.makedirs(directory, exist_ok=True)

    fd, tmp_path = tempfile.mkstemp(
        prefix=f".{os.path.basename(target)}.",
        suffix=".tmp",
        dir=directory,
        text=True,
    )

    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="") as handle:
            handle.writelines(lines)
            handle.flush()
            os.fsync(handle.fileno())

        os.replace(tmp_path, target)
        fsync_directory(directory)
    except BaseException:
        try:
            os.unlink(tmp_path)
        except FileNotFoundError:
            pass
        raise


def fsync_directory(directory: str) -> None:
    try:
        fd = os.open(directory, os.O_RDONLY | getattr(os, "O_DIRECTORY", 0))
    except OSError:
        return

    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print("usage: update-kama-config.py CONFIG_PATH PINNED_APPS_VALUE", file=sys.stderr)
        return 2

    config_path = argv[1]
    pinned_apps_value = argv[2]

    try:
        with open(config_path, "r", encoding="utf-8") as handle:
            lines = handle.readlines()
    except FileNotFoundError:
        lines = []

    write_atomic(config_path, update_pinned_apps(lines, pinned_apps_value))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
