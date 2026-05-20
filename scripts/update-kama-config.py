#!/usr/bin/env python3
"""Update user-editable kama.conf values with an atomic write.

Usage:
  update-kama-config.py pinned-apps CONFIG_PATH VALUE
  update-kama-config.py set-key CONFIG_PATH SECTION.KEY VALUE
  update-kama-config.py set-keys CONFIG_PATH SECTION.KEY VALUE [SECTION.KEY VALUE ...]
"""

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


def update_key(lines: list[str], section_dot_key: str, value: str) -> list[str]:
    dot = section_dot_key.find(".")
    if dot < 0:
        raise ValueError(f"SECTION.KEY must contain a dot, got: {section_dot_key!r}")

    section = section_dot_key[:dot].strip()
    key = section_dot_key[dot + 1:].strip()

    if not section or not key:
        raise ValueError(f"Empty section or key in: {section_dot_key!r}")

    section_header = f"[{section}]"
    in_target = False
    section_line = -1
    key_line = -1
    insert_line = -1

    for index, line in enumerate(lines):
        stripped = line.strip()

        if stripped == section_header:
            in_target = True
            section_line = index
            insert_line = index + 1
            continue

        if stripped.startswith("[") and stripped.endswith("]"):
            if in_target:
                break
            in_target = False
            continue

        if in_target:
            insert_line = index + 1
            if "=" in stripped:
                existing_key = stripped.split("=", 1)[0].strip()
                if existing_key == key:
                    key_line = index
                    break

    next_line = f"{key} = {value}\n"

    if key_line >= 0:
        lines[key_line] = next_line
        return lines

    if section_line >= 0:
        lines.insert(insert_line, next_line)
        return lines

    if lines and not lines[-1].endswith("\n"):
        lines.append("\n")

    if lines and lines[-1].strip():
        lines.append("\n")

    lines.extend([f"{section_header}\n", next_line])
    return lines


def update_keys(lines: list[str], pairs: list[tuple[str, str]]) -> list[str]:
    for section_dot_key, value in pairs:
        lines = update_key(lines, section_dot_key, value)
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
    if len(argv) < 2:
        print(
            "usage: update-kama-config.py pinned-apps CONFIG_PATH VALUE\n"
            "       update-kama-config.py set-key CONFIG_PATH SECTION.KEY VALUE\n"
            "       update-kama-config.py set-keys CONFIG_PATH SECTION.KEY VALUE [SECTION.KEY VALUE ...]",
            file=sys.stderr,
        )
        return 2

    subcommand = argv[1]

    if subcommand == "pinned-apps":
        if len(argv) != 4:
            print("usage: update-kama-config.py pinned-apps CONFIG_PATH VALUE", file=sys.stderr)
            return 2
        config_path, pinned_apps_value = argv[2], argv[3]
        try:
            with open(config_path, "r", encoding="utf-8") as handle:
                lines = handle.readlines()
        except FileNotFoundError:
            lines = []
        write_atomic(config_path, update_pinned_apps(lines, pinned_apps_value))
        return 0

    if subcommand == "set-key":
        if len(argv) != 5:
            print("usage: update-kama-config.py set-key CONFIG_PATH SECTION.KEY VALUE", file=sys.stderr)
            return 2
        config_path, section_dot_key, value = argv[2], argv[3], argv[4]
        try:
            with open(config_path, "r", encoding="utf-8") as handle:
                lines = handle.readlines()
        except FileNotFoundError:
            lines = []
        try:
            write_atomic(config_path, update_key(lines, section_dot_key, value))
        except ValueError as exc:
            print(f"error: {exc}", file=sys.stderr)
            return 2
        return 0

    if subcommand == "set-keys":
        if len(argv) < 6 or len(argv[3:]) % 2 != 0:
            print(
                "usage: update-kama-config.py set-keys CONFIG_PATH SECTION.KEY VALUE [SECTION.KEY VALUE ...]",
                file=sys.stderr,
            )
            return 2
        config_path = argv[2]
        pairs = list(zip(argv[3::2], argv[4::2]))
        try:
            with open(config_path, "r", encoding="utf-8") as handle:
                lines = handle.readlines()
        except FileNotFoundError:
            lines = []
        try:
            write_atomic(config_path, update_keys(lines, pairs))
        except ValueError as exc:
            print(f"error: {exc}", file=sys.stderr)
            return 2
        return 0

    print(
        f"unknown subcommand: {subcommand!r}\n"
        "usage: update-kama-config.py pinned-apps CONFIG_PATH VALUE\n"
        "       update-kama-config.py set-key CONFIG_PATH SECTION.KEY VALUE\n"
        "       update-kama-config.py set-keys CONFIG_PATH SECTION.KEY VALUE [SECTION.KEY VALUE ...]",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
