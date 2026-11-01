# Development notes — 0.3.0-dev, PR #2 stabilization

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
