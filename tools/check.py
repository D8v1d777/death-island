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
    if marker in ("UNIT:", "INTEGRATION:", "CHARACTERS:", "STABILITY:"):
        summary = re.search(re.escape(marker) + r" (\d+) passed, (\d+) failed", result.stdout)
        if not summary or int(summary[1]) == 0 or int(summary[2]) != 0:
            raise SystemExit("Missing, empty or failed assertion summary: " + marker)
    if (
        result.returncode
        or ERROR.search(result.stdout)
        or (marker and marker not in result.stdout)
    ):
        raise SystemExit(f"Check failed: {' '.join(args)}")


def main() -> None:
    require_space()
    godot = os.environ.get("GODOT", "godot")
    if "--gallery" in sys.argv:
        folder = Path(os.environ.get("DEATH_ISLAND_GALLERY_DIR", str(ROOT / "build/gallery")))
        os.environ["DEATH_ISLAND_GALLERY_DIR"] = str(folder.resolve())
        os.environ["DEATH_ISLAND_SOURCE_REVISION"] = subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True
        ).strip()
        os.environ["LIBGL_ALWAYS_SOFTWARE"] = "1"
        run(["xvfb-run", "-a", godot, "--path", "src", "--audio-driver", "Dummy",
             "--fixed-fps", "30", "res://tests/integration/GameplayGallery.tscn"],
            "GALLERY: 6 actual gameplay images; failures: false", timeout=120)
        run([sys.executable, "tools/validate_gallery.py", str(folder)], "GALLERY FILES:")
        run([godot, "--headless", "--path", "src", "--script",
             str(ROOT / "tools/ValidateImages.gd"), "--", str(folder)], "IMAGE DECODE:")
        return
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
            ["xvfb-run", "-a", godot, "--path", "src", "--audio-driver", "Dummy",
             "res://tests/integration/CharacterTestRunner.tscn"],
            "CHARACTERS:",
            timeout=120,
        )
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
    run([sys.executable, "tools/validate_gallery.py", "docs/images", "--readme", "README.md"],
        "GALLERY FILES:")
    run([godot, "--headless", "--path", "src", "--script",
         str(ROOT / "tools/ValidateImages.gd"), "--", str(ROOT / "docs/images")], "IMAGE DECODE:")
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
