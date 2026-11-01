#!/usr/bin/env python3
"""Audit/prune an explicit allowlist of reproducible development artifacts."""

import argparse
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]
GIB = 1024**3
MIN_FREE = 15 * GIB
PAUSE_FREE = 18 * GIB


def require_space(path: Path = ROOT) -> None:
    free = shutil.disk_usage(path).free
    if free < MIN_FREE:
        raise SystemExit(
            f"Build stopped: {free / GIB:.2f} GiB free; below the 15 GiB minimum."
        )
    if free <= PAUSE_FREE:
        raise SystemExit(
            f"Build stopped: {free / GIB:.2f} GiB free; pause and inspect at 18 GiB or below."
        )


def size(path: Path) -> int:
    if path.is_symlink():
        return 0
    if path.is_file():
        return path.stat().st_size
    if path.is_dir():
        return sum(size(child) for child in path.iterdir())
    return 0


def candidates() -> list[Path]:
    templates = Path.home() / ".local/share/godot/export_templates/4.3.stable"
    result = [
        templates / "templates.tpz",
        templates / "ios.zip",
        templates / "macos.zip",
        ROOT / "src/android/build/build",
        ROOT / "build/android-sdk",
        ROOT / "build/android-sdk-gradle/platform-tools-2",
        Path.home() / ".gradle/.tmp",
    ]
    for pattern in ["windows_*.exe", "web_*.zip", "linux_*.arm32", "linux_*.x86_*"]:
        result.extend(sorted(templates.glob(pattern)))
    return [path for path in result if path.exists() and not path.is_symlink()]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--apply", action="store_true", help="Delete the listed disposable artifacts"
    )
    args = parser.parse_args()
    before = shutil.disk_usage(ROOT).free
    total = 0
    for path in candidates():
        amount = size(path)
        print(f"{amount / GIB:6.3f} GiB  {path}")
        total += amount
        if args.apply:
            if path.is_dir():
                shutil.rmtree(path)
            else:
                path.unlink()
    after = shutil.disk_usage(ROOT).free
    print(f"Disposable total: {total / GIB:.3f} GiB")
    print(f"Free before: {before / GIB:.3f} GiB; free now: {after / GIB:.3f} GiB")


if __name__ == "__main__":
    main()
