# Death Island — manual-test RC1 evidence

Version: `0.3.0-dev-rc1`. Engine: Godot `4.3.stable.official.77dcf97d8`.
Branch: `feat/dave-marie-character-pipeline`.

## Preservation

Started at the clean integrated `ada0638d0a536ee90cf2112506eb1e29dc97c735`.
Both checksum sets in `/root/death-island-pass1.5-backup-20261101/` were verified
read-only. A new standalone recovery bundle was created at
`/root/death-island-manual-rc1-backup-20261101/pre-release.bundle` and verified.
SHA-256: `f22332135a12d8ea8dfaa9308bf5ba8c9b183198e29c42ee1cb2a424284871e4`.
Its `RECOVERY.md` explains restoring into a new directory. The old backup and
the separate `/root/death-island` working tree were not modified.

## CharacterChoice resolution

History `649595c` and the existing character-pipeline documentation establish
canonical Dave/Marie title selection, with Dave as default. The incomplete
foundation removed the selector but retained its tested product API. The current
manual-release instruction explicitly requires both choices, so the implementation
was restored rather than weakening that expectation.

- `CharacterChoice` has both IDs, visibly selects Dave on title entry, and updates
  the preview when changed.
- A stable Player owns the active survivor's state. The inactive survivor stores
  its separate pack, equipment, vitals and XP in validated NPC save data.
- Both directions of switching work from Pause and playable-NPC interaction.
- Loading and new voyages remove the active identity's duplicate NPC. Unknown
  switch targets and switching while dead/loading are rejected.
- Existing Companion/Mara behavior and callers remain intact.

## Artwork gate

Technical manual-test gate passed; final art approval remains pending.
Dedicated Dave/Marie resources, previews, HUD names, lossless imports, 2048×448
atlases and eight-cell mappings were checked in the real renderer and export.
New cell-bound tests initially failed for action-cell clipping/neighbor bleed.
`tools/fit_character_cells.py` measured the original vectors on expanded canvases
and corrected only cell translations, at scale **1.0**. Independent XML comparison
against the integrated sources confirmed unchanged paths, colors, poses and
proportions. All sixteen cell-bound tests then passed.

No missing approved reference images were invented, and no corrupt historical
JPEG was restored. The title and package explicitly label the existing art interim.
See `CHARACTER_PIPELINE.md` for reference/animation limitations.

## Actual local verification

Fresh results after release fixes (not copied baseline claims):

| Command/gate | Result |
| --- | --- |
| `python3 tools/check.py` | Passed |
| Python tests | 10 passed |
| GDScript lint and formatter | Passed; 64 files checked |
| Godot 4.3 headless editor import | Passed |
| `python3 tools/check.py --clean-import` | Passed without existing editor cache |
| Unit / gameplay / recovery / selection | 48 / 198 / 75 / 32 passed; zero failed |
| `python3 tools/check.py --render-only` | Passed |
| Rendered stability / characters | 42 / 92 passed; zero failed |
| Real title, gameplay, crafting, dialogue and aspect captures | Generated and inspected |
| Performance probe | 60 real-rendered frames recorded |
| `python3 tools/check.py --gallery` | Six new genuine captures; no failures |
| Gallery digest/link/container validation and decoding | Passed |
| `python3 tools/build_manual_test.py` | Linux export + extracted final ZIP passed |
| Exported rendered `PackSmoke.gd` | 50 passed, zero failed |
| `python3 tools/build_android.py` | APK exported, signature/content/permissions checked |
| Workflow YAML and embedded shell syntax | Passed using existing gdtoolkit environment |

Each game/test run used isolated user-data directories. Output was checked for
SCRIPT ERROR, ERROR, FAIL, nonempty summaries and process failures. The failed
initial artwork assertions were corrected and rerun; they were not suppressed.

The actual exported executable was extracted from its final ZIP to a clean
directory, launched normally, then driven through rendered title selection for
both survivors, movement, switching, crafting and save/load. The external test
harness loads all game resources from the embedded PCK; the pack excludes tests.
Neither a Godot editor nor a project/cache directory is required by the package.
The committed source SHA is substituted into package documents and recorded in
`build/manual-test-rc1/VERIFIED.txt` alongside the ZIP checksum.

Local evidence is in `build/manual-rc1-evidence/`,
`build/manual-test-rc1/exported-screenshots/`, and
`/tmp/opencode/death-island-rc1-*.log`. These generated diagnostics are not packaged
as game content. Final remote job outcomes and artifact links are reported at delivery.

## Notices and platform selection

- The existing desktop preset and installed templates target **Linux ARM64**.
  Windows has no preset/template here, and no Wine/runtime is available to execute
  a Windows binary. The configured, independently testable target was used rather
  than publishing an untested Windows package. Android remains the primary mobile
  configuration, with a companion APK available for device evaluation.
- `ldd` on the Linux executable resolves all required standard system libraries.
  Godot and the game pack are embedded; graphics/windowing remain OS facilities.
- `pkg_resources` is a development-linter deprecation notice. gdtoolkit 4.3.3 and
  setuptools 80.9.0 are pinned; these Python packages are not in the game runtime.
- Godot's SDK fallback selects build-tools 34.0.0, which the existing build script
  explicitly configures, while the APK targets API35. Export/signature checks pass;
  this notice alone is not an Android packaging failure.
- Xvfb/llvmpipe reports unsupported VSync changes. The software-rendered sample on
  this ARM Android development host was approximately 160 ms median / 174 ms p95,
  with 95 draw calls and about 44 MB texture memory. This is slow software rendering,
  not measured target-phone or hardware-GPU performance.

## Gallery

The six README images were newly captured from committed source
`c6064d0ecfd22ea2260c44b2ad3962945bc99b2a`, with version and all SHA-256 records in
`docs/images/gallery.json`. The final two show Marie cooking/building after a real
switch. All six were individually inspected. Existing historical images outside
the six-image showcase were preserved. Later gallery/documentation changes do not
change the captured runtime.

## Release decision and limitations

**A — blockers:** none observed for Linux ARM64 launch, selection, switching,
gameplay entry and the verified save/load flow. Windows execution is unsupported
by this candidate. The Android APK is not certified for 16-KiB-page devices or
production distribution; no physical device was connected for installation tests.

**B — manual-test limitations:** interim art and limited animation; experimental
expanded roles/farming and incomplete relationship persistence; inactive survivors'
player survival values are frozen; menus scroll on small displays; world labels can
visually intersect translucent mobile controls near screen edges; software rendering
is slow on the development host. APK checks confirm a debug-signed ARM64 API24+
package, not phone acceptance. The native libraries have 4-KiB alignment; the
existing Android release audit correctly reports production/16-KiB blockers.

**C — after manual testing:** approved-reference art, dedicated run/hit/death
drawings, expanded systems/biomes, audio polish, hardware/device profiling,
cutout/multitouch coverage and production signing/store requirements.

## Publication behavior

- Feature push or pull request: normal security, tests and build artifacts only.
- Ordinary manual dispatch: same; `publish_beta` defaults to false.
- Explicit manual dispatch with `publish_beta=true` on this feature branch:
  prerelease publication is eligible only after security and Android build gates.
- Tags/release events: no matching publication trigger is configured.
- A completed build alone does not authorize publication.

No public release or tag is created by this task. The Linux manual package is an
Actions artifact, with a SHA-256 sidecar and installation, release-note and manual
QA documents inside the ZIP. A normal feature push is permitted only after the
publication guard and local verification have passed.
