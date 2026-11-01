# Quality gates

## Automated local/CI gates

From the repository root:

```bash
python3 tools/check.py
python3 tools/check.py --render-only
python3 tools/check.py --clean-import
python3 tools/check.py --gallery
python3 tools/build_android.py
git diff --check
python3 tools/audit_android.py build/death-island-debug.apk --output build/android-release-audit.json
```

`tools/check.py` runs:

0. Python source/gallery/storage/ELF and gate-failure regression tests.
1. `gdlint src/scripts src/tests`
2. `gdformat --check src/scripts src/tests`
3. `godot --headless --path src --editor --import --quit`
4. Unit scene runner (production components/transactions).
5. Integration scene runner (physics, input, gathering, crafting, combat, progression,
   actual save files/recovery/migration, live restoration and menu lifecycles).
6. Main-scene launch smoke.

It also validates the committed gallery manifest/digests/README links and decodes
all six WebPs with Godot, rejecting invalid, blank or duplicate output. Unit and
integration summaries must contain a positive assertion count and zero failures;
exit code zero or a bare marker cannot bypass the gate.
RenderSmoke retains failed capture status through completion and never prints its
success marker after a failed write; an actual unwritable-path probe verified this.

Godot 4.3 does **not** provide the previously documented `--format` command.
`--check-only` alone does not import/validate every project resource. The wrapper
checks both exit status and engine error output, and requires test summary markers.
`DEATH_ISLAND_TEST_FAIL=1` deliberately fails the integration runner to verify the
failure path. Tests use dedicated save directories, not normal player saves.

The render-only gate needs Xvfb/Mesa and uses the actual OpenGL renderer. Screenshots
are written to `build/screenshots/`. It supplements headless physics tests, which
cannot certify visual output or GPU performance.

It now runs `StabilityTestRunner` (respawn/save/legacy recipes/semantic rejection/
failed quit/retained loot), `CharacterTestRunner` (both title choices, textures,
actions, persistence, fallback and text/window-size checks), four UI smoke captures
and a bounded 60-frame performance probe. The new live respawn suite encounters
Godot 4.3's known null-mesh cleanup error with the dummy renderer, so it runs under
real OpenGL; errors are not suppressed. Core/gameplay suites remain headless.

`--gallery` uses live OpenGL and the real gameplay runner, then validates metadata
and image decoding. Default output `build/gallery/` is suitable for CI; override
`DEATH_ISLAND_GALLERY_DIR` to update `docs/images/`. See `docs/audits/GALLERY.md`.

The additional packaged-content smoke test can be run on Linux ARM64:

```bash
godot --headless --path src --export-debug Linux ../build/death-island.arm64
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a build/death-island.arm64 --audio-driver Dummy \
  --script "$PWD/src/tests/integration/PackSmoke.gd"
```

The Android gate verifies export completion, archive integrity, ARM64 native library,
size under 200 MiB and APK signing. CI uploads the debug APK and screenshots.
Verify manifest API levels and permissions with `aapt dump badging` / `dump permissions`.

The APK verifier also requires Dave/Marie imported textures and excludes reference
boards. Editor SDK configuration lives under `build/godot-config/`. CI publishes
the APK, its hash and the release audit JSON. The audit's report mode documents
blockers and **does not certify release readiness**. The stricter command:

```bash
python3 tools/audit_android.py build/death-island-debug.apk --require-release
```

currently fails, as required, for the API35 debug artifact and 4KiB native libraries.
It is an ELF/ZIP screen, not full RELRO, AAB, certificate identity or device testing.
Current official policy sources and remaining gates: `docs/audits/RELEASE_READINESS.md`.

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
