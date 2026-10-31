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

## Priorities and dependencies

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
