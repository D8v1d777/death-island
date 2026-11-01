# PR #2 stabilization execution ledger

## Verified starting point

- Worktree `/root/death-island-execution`, branch `feat/dave-marie-character-pipeline`.
- Starting commit `abd4d645c0312652d00735e7f1de1a41ff22d9e9`; clean checkout.
- PR #2 open; CI [41174245356](https://github.com/D8v1d777/death-island/actions/runs/41174245356)
  completed successfully for security, lint/tests and Android debug build.
- Local `python3 tools/check.py`: lint/48-script format check/import/main launch
  passed; **48 unit and 145 integration assertions passed**.
- Existing six README images inspected: all show the old AYLA HUD; image 05 is
  cave mining, not inventory/crafting. The handoff's replacement 05 path does not
  exist at the starting revision.
- The earlier `feature/production-art-first-20261031` branch and its commits remain
  intact. The other companion worktree is untouched.
- Starting free space 23,507,922,944 bytes (21.89 GiB). Keep the agreed 15 GiB minimum
  and pause at <=18 GiB; carry the storage guard into this independently based PR.

## Initial priorities and dependencies (resolved status below)

| Priority | Verified gap | Execution / dependency |
|---|---|---|
| P0 | New-character selection is Inspector-only and the HUD still says AYLA | Add actual title-screen selection, canonical identity display, saved identity tests and both-character render evidence |
| P0 | README gallery is outdated; scenario 05 differs from requested UI capture | Regenerate all six from real gameplay, inspect each, validate files/manifest/links in CI |
| P0 | Original Dave/Marie references unavailable so far | Inspect history and available attachment metadata; do not claim interim SVGs match approved references |
| P1 | Natural resource respawn can leave a negative timer and invalidate the whole save | Clamp the timer and add real save/reload regression |
| P1 | Failed quit-save frees the current session; autosave failures can be silent | Surface failures and retain the live world on unsuccessful quit-save |
| P1 | Restored legacy recipe lists erase new starter progression recipes | Restore current starter recipes alongside saved unlocks |
| P1 | Semantically invalid enemy/quest saves can become unplayable | Validate health/death consistency and content IDs with negative fixtures |
| P1 | No character/render/gallery regression gates or full raster validation | Add narrowly scoped checks and actual rendered character/gallery CI stages |
| P2 | Equipment instances share condition; pickup-cap loot can be lost | Separate item-instance/persisted-loot work requires save-schema and transaction design after critical save fixes |
| P2 | Terrain/navigation, companion carry/gather, missing slots, quest failure content, audio and accessibility remain incomplete | Preserve existing gameplay; document concrete follow-ups rather than treating old checklists as implemented |
| Release gate | Godot 4.3 native templates and current API35 debug export are not current Play-ready | Audit the newly built artifact; coherent engine/native/AGP/API36 migration and release signing are required before production claims |

Reference-recovery delegation encountered the image-processing policy block and was
stopped. Metadata-only source investigation continues without resubmitting that
operation. A later implementation delegation hit a rate limit; no changes from it
were reported. Main-agent implementation continues.

## Completed changes and evidence

| Commit | Files / responsibility | Verified outcome |
|---|---|---|
| `ef781a3` | `tools/storage.py`, `tools/test_storage.py`, `tools/check.py`, this ledger | 15GiB floor / <=18GiB pause boundaries tested without filling the disk |
| `649595c` | `GameManagerGlobal.gd`, `player.gd`, `IllustratedActor.gd`, `IllustratedArt.gd`, `hud.gd`; `CharacterTestRunner.gd/.tscn`, `GameplayGallery.gd`; gallery/image/check tooling | Real title selection, identity/persistence/fallback coverage and reproducible validated capture pipeline |
| `4466a02` | README, six current image paths, manifest, gallery/character docs, `ci.yml`, `tools/check.py` | All six replacements generated and visually inspected; scenario 05 now inventory/crafting; CI regenerates and decodes its own gallery |
| `9fe11e3` | `resource_node.gd`, crafting system, state validation, save/game managers, world/HUD, `StabilityTestRunner.gd/.tscn`, check wrapper | Respawn no longer poisons saves; failed saves remain visible; unsuccessful quit-save retains the world; legacy starter recipes and semantic-state validation corrected |
| `d5f5a80` | game manager, `hud.gd`, `TouchControls.gd`, character runner | Text scale 1.0–1.4 with wider scaled buttons; three requested window sizes tested at 1.3x, narrow/wide snapshots inspected |
| `6b13497` | Android build/export/CI config; `tools/audit_android.py`, its tests; `PerformanceProbe.gd/.tscn`, check wrapper | Current packed characters verified, reference boards excluded, worktree-local editor config, bounded measurements and explicit release-blocker report |
| `2e30b53` | `enemy.gd`, `StateValidation.gd`, stability runner | Loot rolls once, remains persisted when capacity is full, retries without duplication/kill-credit inflation; teardown safe |
| `2af2627` | `src/tests/integration/RenderSmoke.gd` | Capture failure cannot be overwritten by a later success exit/marker |

File names without a directory above refer to their existing `src/scripts/` or
`src/tests/integration/` locations; `git show --stat <commit>` gives the exact full
changed-file set. All earlier branch commits remain intact; no assets in the other
worktree were modified. This branch's Dave/Marie artwork remains the user's interim
strips, not new reference-matched artwork.

## Final local validation at source `2e30b53`

| Command / gate | Result |
|---|---|
| `python3 tools/check.py --clean-import` | PASS — source-only fresh import |
| `python3 tools/check.py` | PASS — 10 Python tests, 48 unit assertions, 145 gameplay assertions, 51-script lint/format/import, main launch, README/manifest and six-image decoding |
| `python3 tools/check.py --render-only` | PASS — 42 live stability + 52 character/UI assertions; four UI smoke screens; two character snapshots; window-size captures; 60-frame desktop probe |
| `DEATH_ISLAND_GALLERY_DIR="$PWD/docs/images" python3 tools/check.py --gallery` | PASS — six real-action captures and independent container/digest/decoder checks |
| `python3 tools/validate_gallery.py docs/images --readme README.md` | PASS — six correct links, matching hashes/evidence and valid containers |
| `python3 tools/build_android.py` | PASS — 73.0MiB debug APK, archive/signature/manifest/ARM64 and packed-character checks |
| `python3 tools/audit_android.py ... --output ...` | PASS as a **report**; explicit release blockers recorded |
| `python3 tools/audit_android.py ... --require-release` | FAIL / exit 1 — release criteria are not satisfied |
| `git diff --check` | PASS |
| ADB device listing | Empty — physical device checks NOT RUN |
| Release APK/AAB signing, Play Console acceptance, native 16KiB execution | NOT RUN / blocked; no release keys or qualifying runtime/device evidence |

Before the fixes, the new stability regression run failed 15 assertions; after
correction and additional loot checks it passes 42. Godot 4.3's dummy renderer
reported its known null-mesh cleanup error for the respawn suite even after its
assertions passed. The suite therefore runs in actual OpenGL; no engine error is
filtered out. Core/gameplay headless suites pass. The first loot reload check also
caught JSON numeric normalization, corrected before the passing final run.

Final review additionally exercised an unwritable capture-directory fixture:
RenderSmoke exited **5**, emitted a failure, and emitted **no success marker**.
The normal four-screen render then passed. This validates the failure-path change
without suppressing real engine errors or committing malformed image fixtures.

### Observed desktop sample (not phone acceptance)

Raw local file: `build/screenshots/performance.json`. Godot 4.3, OpenGL Compatibility,
Mesa llvmpipe, stationary Wreckshore, 10 warmup + 60 uncapped measured frames:

- Wall-frame p50 **148.007ms**, p95 **160.938ms**, p99/sample maximum **165.253ms**.
- Peak draw calls **86**; reported texture memory **44,076,213 bytes (~42.0MiB)**.
- Static-memory monitor **34,345,657 -> 34,335,497 bytes** during this short sample.
- New-world setup **1138ms**, excluding engine startup; **not a cold-launch time**.

The software-rendered sample misses 30 FPS. These measurements do not certify
native GPU performance, leak-free long sessions, thermals or battery usage.
Remaining work and exact reasons: the current table in `docs/ROADMAP.md` and the
release/device gates in `docs/audits/RELEASE_READINESS.md`.

Final inspected free storage after the build: **23,436,525,568 bytes (21.83GiB)**;
no shared-storage work or cleanup occurred. Final source CI and review state are
available on [PR #2](https://github.com/D8v1d777/death-island/pull/2). Publication and
CI results are reported after actually observing them; baseline CI is not substituted
for final-commit CI, and no merge/release approval is implied.
