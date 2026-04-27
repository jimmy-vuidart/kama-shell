#!/usr/bin/env python3

import json
import re
import subprocess
import sys


UUID_PATTERN = re.compile(r"\{[0-9a-fA-F-]{36}\}")


def busctl_json(*args):
    result = subprocess.run(
        ["busctl", "--user", "--json=short", "call", *args],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    if result.returncode != 0:
        return None

    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        return None


def variant_value(mapping, key, default=None):
    value = mapping.get(key) if isinstance(mapping, dict) else None

    if isinstance(value, dict) and "data" in value:
        return value["data"]

    return default if value is None else value


def get_window_info(match_id):
    match = UUID_PATTERN.search(match_id)

    if not match:
        return {}

    payload = busctl_json(
        "org.kde.KWin",
        "/KWin",
        "org.kde.KWin",
        "getWindowInfo",
        "s",
        match.group(0),
    )

    if not payload or not payload.get("data"):
        return {}

    info = payload["data"][0]
    return info if isinstance(info, dict) else {}


def normalized_match(match):
    if not isinstance(match, list) or len(match) < 4:
        return None

    match_id = str(match[0] or "").strip()
    title = str(match[1] or "").strip()
    icon_name = str(match[2] or "").strip()

    if not match_id:
        return None

    info = get_window_info(match_id)
    desktop_file = str(variant_value(info, "desktopFile", "") or "").strip()
    resource_class = str(variant_value(info, "resourceClass", "") or "").strip()
    resource_name = str(variant_value(info, "resourceName", "") or "").strip()
    caption = str(variant_value(info, "caption", "") or "").strip()
    skip_taskbar = bool(variant_value(info, "skipTaskbar", False))

    if skip_taskbar:
        return None

    title = caption or title
    app_id = desktop_file or resource_class or resource_name or icon_name or title
    icon_name = icon_name or desktop_file or resource_class or resource_name

    if not title and not app_id and not icon_name:
        return None

    return {
        "matchId": match_id,
        "title": title or app_id or icon_name,
        "appId": app_id,
        "desktopId": desktop_file,
        "resourceClass": resource_class,
        "resourceName": resource_name,
        "iconName": icon_name,
        "activated": False,
    }


def main():
    payload = busctl_json(
        "org.kde.KWin",
        "/WindowsRunner",
        "org.kde.krunner1",
        "Match",
        "s",
        "",
    )

    matches = payload["data"][0] if payload and payload.get("data") else []
    windows = []
    seen_match_ids = set()

    for match in matches:
        window = normalized_match(match)

        if window is None or window["matchId"] in seen_match_ids:
            continue

        seen_match_ids.add(window["matchId"])
        windows.append(window)

    json.dump({"windows": windows}, sys.stdout, separators=(",", ":"))
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
