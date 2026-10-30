# Quality gates

## Automated local/CI gates

From the repository root:

```bash
python3 tools/check.py
python3 tools/check.py --render-only
python3 tools/build_android.py
git diff --check
```

`tools/check.py` runs:

1. `gdlint src/scripts src/tests`
2. `gdformat --check src/scripts src/tests`
3. `godot --headless --path src --editor --import --quit`
4. Unit scene runner (production components/transactions).
5. Integration scene runner (physics, input, gathering, crafting, combat, progression,
   actual save files/recovery/migration, live restoration and menu lifecycles).
6. Main-scene launch smoke.

Godot 4.3 does **not** provide the previously documented `--format` command.
`--check-only` alone does not import/validate every project resource. The wrapper
checks both exit status and engine error output, and requires test summary markers.
`DEATH_ISLAND_TEST_FAIL=1` deliberately fails the integration runner to verify the
failure path. Tests use dedicated save directories, not normal player saves.

The render-only gate needs Xvfb/Mesa and uses the actual OpenGL renderer. Screenshots
are written to `build/screenshots/`. It supplements headless physics tests, which
cannot certify visual output or GPU performance.

The additional packaged-content smoke test can be run on Linux ARM64:

```bash
godot --headless --path src --export-debug Linux ../build/death-island.arm64
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a build/death-island.arm64 --audio-driver Dummy \
  --script "$PWD/src/tests/integration/PackSmoke.gd"
```

The Android gate verifies export completion, archive integrity, ARM64 native library,
size under 200 MiB and APK signing. CI uploads the debug APK and screenshots.
Verify manifest API levels and permissions with `aapt dump badging` / `dump permissions`.

## Mandatory device/release gates

These remain required before calling the entire game complete:

* Target phone: full gathering → crafting → combat → quest → save/relaunch journey.
* Actual multi-finger movement/camera/actions, gamepad menus and screen aspect ratios.
* Cold launch under 10 seconds, stable 30 FPS, p99 frame time under 50 ms.
* Runtime memory under 1.5 GiB; growth under 50 MiB over a one-hour session.
* Thirty-minute thermal test and battery use under 15% per hour.
* Background/resume, low-storage failure, reinstall/upgrade and corrupted-save recovery.
* Complete art/audio/animation/accessibility and milestone acceptance review.
* Signed release APK/AAB, current Play requirements and third-party notices review.

Coverage targets remain 80% for core systems and complete save critical-path coverage.
Assertion counts are **not** line-coverage measurements; no percentage is claimed
without instrumentation. Likewise a successful APK build does not certify installation
or device performance. See `docs/audits/BUILD_VERIFICATION.md` for observed results.
