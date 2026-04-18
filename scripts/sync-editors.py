#!/usr/bin/env python3
"""Merge editors/settings.shared.json (+ local + overrides) into editors/dist/settings.*.json."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any


def _strip_line_comment(line: str) -> str:
    """Remove // comments without touching // inside strings (e.g. file://)."""
    i = 0
    in_string = False
    escape = False
    while i < len(line):
        c = line[i]
        if escape:
            escape = False
            i += 1
            continue
        if c == "\\" and in_string:
            escape = True
            i += 1
            continue
        if c == '"':
            in_string = not in_string
            i += 1
            continue
        if not in_string and i + 1 < len(line) and line[i : i + 2] == "//":
            return line[:i].rstrip()
        i += 1
    return line


def load_jsonc(path: Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8")
    text = re.sub(r"/\*[\s\S]*?\*/", "", text)
    lines = [_strip_line_comment(line) for line in text.splitlines()]
    text = "\n".join(lines)
    text = re.sub(r",(\s*)\}", r"\1}", text)
    text = re.sub(r",(\s*)\]", r"\1]", text)
    return json.loads(text)


def deep_merge(base: dict[str, Any], patch: dict[str, Any]) -> dict[str, Any]:
    for k, v in patch.items():
        if k in base and isinstance(base[k], dict) and isinstance(v, dict):
            deep_merge(base[k], v)
        else:
            base[k] = v
    return base


def deep_copy(d: dict[str, Any]) -> dict[str, Any]:
    return json.loads(json.dumps(d))


def main() -> None:
    dotfiles = Path(sys.argv[1]).resolve()
    editors = dotfiles / "editors"
    dist = editors / "dist"
    dist.mkdir(parents=True, exist_ok=True)

    shared_path = editors / "settings.shared.json"
    if not shared_path.is_file():
        print(f"missing {shared_path}", file=sys.stderr)
        sys.exit(1)

    shared = load_jsonc(shared_path)
    local_path = editors / "settings.local.json"
    if local_path.is_file():
        deep_merge(shared, load_jsonc(local_path))

    for app in ("cursor", "vscode", "antigravity"):
        merged = deep_copy(shared)
        ov = editors / "overrides" / f"{app}.json"
        if ov.is_file():
            extra = load_jsonc(ov)
            if extra:
                deep_merge(merged, extra)
        out = dist / f"settings.{app}.json"
        out.write_text(json.dumps(merged, indent=2) + "\n", encoding="utf-8")
        print(f"wrote {out}", file=sys.stderr)


if __name__ == "__main__":
    main()
