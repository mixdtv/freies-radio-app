#!/usr/bin/env python3
"""Rewrite pubspec.yaml in-place, removing proprietary-pulling dependencies.

Run during the F-Droid build's prebuild step. Reads `fdroid-exclude-deps.txt`
(one package name per line, `#` for comments) and removes each listed package
from both `dependencies` and `dev_dependencies` in pubspec.yaml.

Only impacts the build-time pubspec inside F-Droid's build env; the committed
pubspec.yaml in the source repo is unchanged.

Pairs with lib/features/location/location_service_fdroid_stub.dart, which
the F-Droid metadata's prebuild step also copies into place so the app
compiles without the removed imports.
"""
import pathlib
import sys

import yaml

EXCLUDE_LIST_PATH = pathlib.Path("fdroid-exclude-deps.txt")
PUBSPEC_PATH = pathlib.Path("pubspec.yaml")


def load_excludes(path: pathlib.Path) -> list[str]:
    excludes = []
    for raw in path.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        excludes.append(line)
    return excludes


def main() -> int:
    if not PUBSPEC_PATH.exists():
        print(f"error: {PUBSPEC_PATH} not found; run from repo root", file=sys.stderr)
        return 1
    if not EXCLUDE_LIST_PATH.exists():
        print(f"error: {EXCLUDE_LIST_PATH} not found", file=sys.stderr)
        return 1

    excludes = load_excludes(EXCLUDE_LIST_PATH)
    print(f"excluding {len(excludes)} package(s): {excludes}", file=sys.stderr)

    with PUBSPEC_PATH.open() as f:
        spec = yaml.safe_load(f)

    removed = []
    for section in ("dependencies", "dev_dependencies"):
        deps = spec.get(section) or {}
        for pkg in excludes:
            if pkg in deps:
                del deps[pkg]
                removed.append(f"{section}.{pkg}")

    if not removed:
        print("nothing removed", file=sys.stderr)
        return 0

    with PUBSPEC_PATH.open("w") as f:
        yaml.safe_dump(
            spec, f, default_flow_style=False, sort_keys=False, allow_unicode=True
        )

    for entry in removed:
        print(f"removed {entry}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
