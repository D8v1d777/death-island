# Manual-test candidate — 0.3.0-dev-rc1

- Dave is the visible default in restored title selection; Marie and the matching
  runtime preview are selectable. Pause-menu switching retains each survivor's
  own pack, equipment, vitals and experience through save/load.
- Existing Dave/Marie vector cells were translated into safe atlas bounds; all
  original drawing geometry, colors and proportions are preserved. Artwork remains
  explicitly interim; final approved-reference conversion is still blocked.
- Six current rendered README captures replace the old showcase. The final two
  show Marie after switching, cooking and building with Mara present.
- The existing Linux ARM64 portable export is packaged and exercised independently
  after ZIP extraction; Android remains a separately checked sideload artifact.
- Beta publication now requires explicit manual dispatch opt-in after security,
  test and Android build gates. Ordinary pushes only run CI/build artifacts.

See [candidate audit](docs/audits/MANUAL_TEST_RC1.md) and the
[manual testing instructions](docs/manual-test/README-TESTING.txt). Experimental
farming/expanded roles, final art, phone acceptance and production distribution
remain outside this candidate's verified scope.

## Historical development notes — 0.3.0-dev, PR #2 stabilization

This is a **playable development build**, not a production release.

## Added and corrected

- Dave/Marie selection from the title screen; correct HUD identity and save/load.
- Dedicated interim strips with size/ID/resource fallback checks and both-character
  rendered snapshots. Original approved references are still required for final art.
- Six freshly verified README gameplay captures, including inventory/crafting.
- Resource-respawn save regression, legacy recipe progression and semantic save
  validation fixes; visible save failures and protected quit behavior.
- Enemy loot survives world pickup capacity and reload, without rerolling rewards.
- Scalable text and rendered window-size checks, including corrected button width.
- Fresh-import, nonempty-test-summary, gallery decoder/digest/link and Android
  artifact checks; explicit release-blocker and bounded performance reports.

## Compatibility and known limits

Existing v2 saves remain readable; missing character IDs default to Dave. New
optional pending-loot fields preserve undelivered rewards. Downgrading to an older
build that ignores new fields is not certified. Historical save-directory discovery
and durable item-instance migration remain follow-ups.

No physical Android acceptance has been performed. The APK is debug signed,
targets API35 and its native libraries fail 16KiB alignment; no release AAB or
Play compliance is claimed. Full art/animation, companion utility depth, expanded
terrain/content, cutout-aware controls, audio polish and sustained profiling remain.
See [roadmap](docs/ROADMAP.md), [build evidence](docs/audits/BUILD_VERIFICATION.md)
and [release gates](docs/audits/RELEASE_READINESS.md).

Report reproducible issues at https://github.com/D8v1d777/death-island/issues with
build/commit, device/API, reproduction steps and relevant logs. Keep signing
credentials and personal save data out of public reports.
