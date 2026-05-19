#!/usr/bin/env python3
"""Fail if source-tree asset URLs are used without Qt.resolvedUrl()."""

from __future__ import annotations

import pathlib
import re
import sys


ASSET_PATTERN = re.compile(r'"(?:\.\./)+assets/')
RESOLVED_PATTERN = re.compile(r"Qt\.resolvedUrl\s*\(")


def line_has_unresolved_asset(line: str) -> bool:
    if not ASSET_PATTERN.search(line):
        return False

    return not RESOLVED_PATTERN.search(line)


def main() -> int:
    root = pathlib.Path(__file__).resolve().parents[1]
    failures: list[str] = []

    for path in sorted((root / "src").rglob("*.qml")):
        relpath = path.relative_to(root)
        for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if line_has_unresolved_asset(line):
                failures.append(f"{relpath}:{lineno}: asset URL must use Qt.resolvedUrl()")

    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
