#!/usr/bin/env python3
"""Package and independently render-test the configured Linux ARM64 manual candidate."""

import hashlib
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import tempfile
import zipfile

from check import ERROR, ROOT, run
from storage import require_space


def sha256(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def main() -> None:
    require_space()
    revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    if subprocess.check_output(["git", "status", "--porcelain", "--untracked-files=no"], cwd=ROOT):
        raise SystemExit("Commit reviewed release inputs before packaging an identified candidate.")
    version = re.search(r'^config/version="([^"]+)"', (ROOT / "src/project.godot").read_text(), re.M)[1]
    output = ROOT / "build/manual-test-rc1"
    output.mkdir(parents=True, exist_ok=True)
    name = f"death-island-{version}-linux-arm64"
    candidate = output / name
    candidate.mkdir(exist_ok=True)
    executable = candidate / "death-island.arm64"
    godot = os.environ.get("GODOT", "godot")
    run([godot, "--headless", "--path", "src", "--editor", "--import", "--quit"])
    run([godot, "--headless", "--path", "src", "--export-release", "Linux", str(executable)], timeout=180)
    executable.chmod(0o755)
    dependencies = subprocess.run(["ldd", str(executable)], text=True, capture_output=True, check=True)
    if "not found" in dependencies.stdout:
        raise SystemExit(dependencies.stdout)
    print(dependencies.stdout)
    for filename in ["README-TESTING.txt", "RELEASE-NOTES.txt", "MANUAL-QA-CHECKLIST.txt"]:
        template = (ROOT / "docs/manual-test" / filename).read_text()
        (candidate / filename).write_text(template.replace("@VERSION@", version).replace("@REVISION@", revision))
    shutil.copy2(ROOT / "LICENSE", candidate / "LICENSE.txt")
    shutil.copy2(ROOT / "THIRD_PARTY_LICENSES.md", candidate / "THIRD_PARTY_LICENSES.txt")
    (candidate / "SHA256SUMS.txt").write_text("".join(
        f"{sha256(path)}  {path.name}\n" for path in sorted(candidate.iterdir())
        if path.is_file() and path.name != "SHA256SUMS.txt"))
    package = output / (name + ".zip")
    with zipfile.ZipFile(package, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(candidate.iterdir()):
            archive.write(path, name + "/" + path.name)
    # Validate the final ZIP, not just its staging directory. No source project,
    # editor cache or original developer save directory is available in this cwd.
    with tempfile.TemporaryDirectory(prefix="manual-export-verification-", dir=output) as temporary:
        isolated = Path(temporary)
        with zipfile.ZipFile(package) as archive:
            if archive.testzip():
                raise SystemExit("Corrupt manual-test ZIP")
            archive.extractall(isolated)
            for info in archive.infolist():
                (isolated / info.filename).chmod(stat.S_IMODE(info.external_attr >> 16))
        extracted = isolated / name
        program = extracted / executable.name
        if sha256(program) != sha256(executable):
            raise SystemExit("Extracted executable differs from packaged binary")
        probe = isolated / "PackSmoke.gd"
        shutil.copy2(ROOT / "src/tests/integration/PackSmoke.gd", probe)
        env = {**os.environ, "XDG_DATA_HOME": str(isolated / "user-data"),
               "GODOT_SILENCE_ROOT_WARNING": "1", "LIBGL_ALWAYS_SOFTWARE": "1",
               "DEATH_ISLAND_CAPTURE_DIR": str(output / "exported-screenshots")}
        commands = [
            ([str(program), "--headless", "--path", str(extracted), "--quit-after", "10"], "", 60),
            (["xvfb-run", "-a", str(program), "--path", str(extracted), "--audio-driver", "Dummy",
              "--fixed-fps", "30", "--script", str(probe)], "PACK:", 180),
        ]
        for index, (command, marker, timeout) in enumerate(commands):
            result = subprocess.run(command, cwd=extracted, env=env, capture_output=True,
                                    text=True, timeout=timeout)
            text = result.stdout + result.stderr
            print(text, end="")
            (output / f"export-verification-{index}.log").write_text(text)
            summary = re.search(r"PACK: (\d+) passed, (\d+) failed", text)
            if result.returncode or ERROR.search(text) or (marker and (
                    not summary or int(summary[1]) == 0 or int(summary[2]) != 0)):
                raise SystemExit("Extracted export verification failed")
    checksum = sha256(package)
    package.with_suffix(".zip.sha256").write_text(f"{checksum}  {package.name}\n")
    (output / "VERIFIED.txt").write_text(
        f"Source: {revision}\nVersion: {version}\nZIP: {package.name}\nSHA-256: {checksum}\n"
        "Final ZIP independently extracted; normal executable bootstrap and rendered PackSmoke passed.\n")
    print(f"MANUAL TEST VERIFIED: {package}\nSHA-256: {checksum}")


if __name__ == "__main__":
    main()
