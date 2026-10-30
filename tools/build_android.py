#!/usr/bin/env python3
"""Export an API 35 debug APK using Godot's Gradle template on Linux."""

import os
import json
import hashlib
from pathlib import Path
import platform
import re
import shutil
import subprocess
import zipfile

from check import ROOT, run
from storage import require_space

GRADLE_SHA256 = "9d926787066a081739e8200858338b4a69e837c3a821a33aca9db09dd4a41026"


def link(source: Path, target: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.is_symlink() and target.resolve() == source.resolve():
        return
    if target.exists() or target.is_symlink():
        raise SystemExit(f"Refusing to replace existing SDK overlay entry: {target}")
    target.symlink_to(source.resolve())


def main() -> None:
    require_space()
    sdk = Path(os.environ.get("ANDROID_HOME", str(Path.home() / "Android")))
    java = Path(os.environ.get("JAVA_HOME", "/usr/lib/jvm/java-21-openjdk-arm64"))
    if not (java / "bin/java").is_file():
        raise SystemExit("Set JAVA_HOME to JDK 21.")
    tools = sdk / "build-tools/34.0.0"
    if not (tools / "apksigner").is_file():
        raise SystemExit("Install Android SDK build-tools 34.0.0.")
    build = ROOT / "build"
    build.mkdir(exist_ok=True)
    if platform.machine() in {"aarch64", "arm64"}:
        # Google distributes x86 Linux SDK binaries. Use native distro binaries,
        # keeping the source SDK intact. apksigner itself is a Java program.
        overlay = build / "android-sdk-gradle"
        for tool in ["adb", "zipalign", "aapt2"]:
            binary = shutil.which(tool)
            if not binary:
                raise SystemExit(
                    f"Install native {tool} first (apt install adb zipalign)."
                )
            relative = (
                "platform-tools/adb" if tool == "adb" else f"build-tools/34.0.0/{tool}"
            )
            link(Path(binary), overlay / relative)
        for entry in tools.iterdir():
            if entry.name not in {"zipalign", "aapt2"}:
                link(entry, overlay / "build-tools/34.0.0" / entry.name)
        for entry in (sdk / "platform-tools").iterdir():
            if entry.name != "adb":
                link(entry, overlay / "platform-tools" / entry.name)
        for entry in ["platforms", "licenses", "cmdline-tools"]:
            link(sdk / entry, overlay / entry)
        sdk = overlay
    os.environ["ANDROID_HOME"] = str(sdk)
    os.environ["JAVA_HOME"] = str(java)
    os.environ["PATH"] = str(java / "bin") + os.pathsep + os.environ["PATH"]
    godot = os.environ.get("GODOT", "godot")
    prepare_gradle()
    run([godot, "--headless", "--path", "src", "--editor", "--import", "--quit"])
    config_root = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
    settings_path = config_root / "godot/editor_settings-4.3.tres"
    settings = settings_path.read_text()
    # Preserve every unrelated editor setting. Godot's --editor --script path
    # leaks the editor scene in 4.3; setting these two string properties directly
    # avoids that engine issue and works in clean CI environments too.
    for key, value in {"android_sdk_path": sdk, "java_sdk_path": java}.items():
        property_name = f"export/android/{key}"
        replacement = f"{property_name} = {json.dumps(str(value))}"
        settings, count = re.subn(
            rf"^{re.escape(property_name)} = .*?$",
            lambda _: replacement,
            settings,
            flags=re.MULTILINE,
        )
        if not count:
            settings += "\n" + replacement + "\n"
    temporary = settings_path.with_suffix(".tres.tmp")
    temporary.write_text(settings)
    temporary.replace(settings_path)
    apk = build / "death-island-debug.apk"
    run(
        [godot, "--headless", "--path", "src", "--export-debug", "Android", str(apk)],
        timeout=900,
    )
    if not apk.is_file() or apk.stat().st_size > 200 * 1024 * 1024:
        raise SystemExit("APK missing or exceeds 200 MiB.")
    with zipfile.ZipFile(apk) as archive:
        bad = archive.testzip()
        if bad:
            raise SystemExit(f"Damaged APK entry: {bad}")
        if "lib/arm64-v8a/libgodot_android.so" not in archive.namelist():
            raise SystemExit("ARM64 runtime missing from APK.")
    subprocess.run(
        [str(tools / "apksigner"), "verify", "--verbose", str(apk)], check=True
    )
    aapt = shutil.which("aapt") or str(tools / "aapt")
    manifest = subprocess.run(
        [aapt, "dump", "badging", str(apk)], check=True, text=True, capture_output=True
    ).stdout
    for expected in [
        "name='org.deathisland.game'",
        "sdkVersion:'24'",
        "targetSdkVersion:'35'",
        "native-code: 'arm64-v8a'",
    ]:
        if expected not in manifest:
            raise SystemExit(f"Unexpected APK manifest: missing {expected}")
    permissions = set(re.findall(r"uses-permission: name='([^']+)'", manifest))
    if permissions != {"android.permission.VIBRATE", "android.permission.WAKE_LOCK"}:
        raise SystemExit(f"Unexpected APK permissions: {permissions}")
    with apk.open("rb") as stream:
        checksum = hashlib.file_digest(stream, "sha256").hexdigest()
    apk.with_suffix(".apk.sha256").write_text(f"{checksum}  {apk.name}\n")
    print(f"APK: {apk} ({apk.stat().st_size / 1024 / 1024:.1f} MiB)")


def prepare_gradle() -> None:
    android = ROOT / "src/android"
    generated = android / "build"
    marker = android / ".death-island-generated"
    if generated.exists() and not marker.exists():
        raise SystemExit(
            "Existing custom src/android/build found; configure it manually."
        )
    if not generated.exists():
        data_home = Path(
            os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share"))
        )
        template = data_home / "godot/export_templates/4.3.stable/android_source.zip"
        generated.mkdir(parents=True)
        with zipfile.ZipFile(template) as archive:
            archive.extractall(generated)
        (android / ".gdignore").write_text("")
        (android / ".build_version").write_text("4.3.stable")
        marker.write_text(
            "Generated from Godot 4.3 stable; configured by tools/build_android.py\n"
        )
        configuration = generated / "config.gradle"
        configuration.write_text(
            configuration.read_text().replace(
                "androidGradlePlugin: '8.2.0'", "androidGradlePlugin: '8.2.2'"
            )
        )
        wrapper = generated / "gradle/wrapper/gradle-wrapper.properties"
        wrapper.write_text(
            wrapper.read_text().replace("gradle-8.2-bin.zip", "gradle-8.5-bin.zip")
            + f"\ndistributionSha256Sum={GRADLE_SHA256}\n"
        )
        build_file = generated / "build.gradle"
        build_file.write_text(
            build_file.read_text().replace(
                "JavaVersion.current() != versions.javaVersion",
                "!JavaVersion.current().isCompatibleWith(versions.javaVersion)",
            )
        )
        properties = generated / "gradle.properties"
        text = properties.read_text().replace("-Xmx4536m", "-Xmx1536m")
        text += "\norg.gradle.daemon=false\norg.gradle.workers.max=2\ndoNotStrip=true\n"
        if platform.machine() in {"aarch64", "arm64"}:
            aapt = shutil.which("aapt2")
            if not aapt:
                raise SystemExit("Install native aapt2 (apt install aapt).")
            text += f"android.aapt2FromMavenOverride={aapt}\n"
        properties.write_text(text)
        (generated / "gradlew").chmod(0o755)


if __name__ == "__main__":
    main()
