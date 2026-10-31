#!/usr/bin/env python3
"""Run Godot gates and fail on engine errors even when Godot exits with code zero."""

import os
from pathlib import Path
import re
import subprocess
import sys
import shutil
import tempfile

from storage import require_space

ROOT = Path(__file__).resolve().parents[1]
ERROR = re.compile(r"SCRIPT ERROR:|^ERROR:|^FAIL:", re.MULTILINE)


def run(args: list[str], marker: str = "", timeout: int = 90) -> None:
    require_space()
    print(f"Running: {' '.join(args)}", flush=True)
    env = {**os.environ, "GODOT_SILENCE_ROOT_WARNING": "1"}
    result = subprocess.run(
        args,
        cwd=ROOT,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=timeout,
    )
    print(result.stdout, end="")
    require_space()
    if (
        result.returncode
        or ERROR.search(result.stdout)
        or (marker and marker not in result.stdout)
    ):
        raise SystemExit(f"Check failed: {' '.join(args)}")


def main() -> None:
    require_space()
    godot = os.environ.get("GODOT", "godot")
    if "--clean-import" in sys.argv:
        build = ROOT / "build"
        build.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(
            prefix="fresh-import-", dir=build
        ) as temporary:
            project = Path(temporary) / "src"
            shutil.copytree(
                ROOT / "src",
                project,
                ignore=shutil.ignore_patterns(".godot", "android", "keystore"),
            )
            run(
                [
                    godot,
                    "--headless",
                    "--path",
                    str(project),
                    "--editor",
                    "--import",
                    "--quit",
                ]
            )
        return
    if "--render-only" in sys.argv:
        os.environ["DEATH_ISLAND_CAPTURE_DIR"] = str(ROOT / "build/screenshots")
        os.environ["LIBGL_ALWAYS_SOFTWARE"] = "1"
        run(
            [
                "xvfb-run",
                "-a",
                godot,
                "--path",
                "src",
                "--audio-driver",
                "Dummy",
                "res://tests/integration/RenderSmoke.tscn",
            ],
            "RENDER:",
            timeout=120,
        )
        return
    if "--engine-only" not in sys.argv:
        run([sys.executable, "-m", "unittest", "discover", "-s", "tools", "-p", "test_*.py"])
        run(["gdlint", "src/scripts", "src/tests"])
        run(["gdformat", "--check", "src/scripts", "src/tests"])
    run([godot, "--headless", "--path", "src", "--editor", "--import", "--quit"])
    run(
        [godot, "--headless", "--path", "src", "res://tests/unit/TestRunner.tscn"],
        "UNIT:",
    )
    run(
        [
            godot,
            "--headless",
            "--path",
            "src",
            "res://tests/integration/TestRunner.tscn",
        ],
        "INTEGRATION:",
    )
    run([godot, "--headless", "--path", "src", "--quit-after", "10"])


if __name__ == "__main__":
    main()
