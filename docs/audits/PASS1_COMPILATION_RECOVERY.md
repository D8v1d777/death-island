# Pass 1 — repository forensics and compilation recovery

Date: 2026-11-01. Scope: the actual local working tree, including pending Phase 1/2 work.

**Result: compilation, lint/format, fresh import, and the executed headless suites pass.**
This is not certification of the unfinished NPC/party/farming features or an Android beta.
Verification applies to the working tree, not a clean checkout of HEAD alone.

## A. Repository and revision evidence

- Repository: `D8v1d777/death-island`; active checkout: `/root/death-island-execution`.
- Branch throughout: `feat/dave-marie-character-pipeline`.
- Starting HEAD: `a99fb84b3b3e6d8a762fe0021ad9e22db0a732a6`.
- Final code HEAD: `549590be22469e2801b0639802fd8a88a6a44385`.
- Initial cached origin SHA equalled starting HEAD (0 ahead / 0 behind).
- Live `git ls-remote` instead returned `19a7a4743fed6f09cbf04d165b3e20862a46a315`.
- `git fetch origin feat/dave-marie-character-pipeline` updated the tracking ref;
  the starting checkout was actually 3 commits behind. No merge/rebase/push occurred.
- Live remote was checked again at completion and remained at that same SHA.

Initial `git status --short --branch`:

```text
## feat/dave-marie-character-pipeline...origin/feat/dave-marie-character-pipeline
 M src/project.godot
 M src/scripts/autoloads/GameManagerGlobal.gd
 M src/scripts/autoloads/SaveManagerGlobal.gd
 M src/scripts/entities/WorldController.gd
 M src/scripts/ui/hud.gd
 M src/scripts/utils/CharacterRoster.gd
 M tools/check.py
?? docs/IMPLEMENTATION_DESIGN.md
?? docs/images/05-marie-explore.webp
?? docs/images/06-campfire-cooking.webp
?? docs/images/06-inventory-crafting.webp
?? docs/images/07-shelter-building.webp
?? src/resources/definitions/RelationshipDefinition.tres
?? src/scenes/NPC.tscn
?? src/scripts/components/NPCComponent.gd
?? src/scripts/data/CropDefinition.gd
?? src/scripts/data/NPCDefinition.gd
?? src/scripts/data/RelationshipDefinition.gd
?? src/scripts/data/RoleDefinition.gd
?? src/scripts/entities/NPC.gd
?? src/scripts/systems/BaseStorageGlobal.gd
?? src/scripts/systems/FarmingSystemGlobal.gd
?? src/scripts/systems/PartySystemGlobal.gd
?? src/scripts/systems/RelationshipSystemGlobal.gd
```

Initial staging area: empty. Unstaged: 7 tracked files, 414 insertions / 31 deletions.
Untracked: 17 files. `git diff --cached --name-status` produced no output.

Initial last 10 commits (`git log --oneline -10`):

```text
a99fb84 feat: update README gallery with fresh gameplay screenshots from current build
3322fe9 merge: integrate COMP-01 companion system with Dave/Marie character pipeline
4b6669c pre-existing: commit working tree state before companion merge
ec15070 gallery: update source_revision to current HEAD and remove orphan cave-mining image
2af2627 test: keep render capture failures from reporting success
2e30b53 fix: persist undelivered enemy loot at pickup capacity
6b13497 build: verify packaged character art and expose release blockers
d5f5a80 feat: add scalable text and rendered aspect-ratio checks
9fe11e3 fix: preserve saveability and progression across runtime failures
4466a02 docs: replace README gallery with verified current gameplay
```

The other worktree, `/root/death-island`, remains at
`b3e611edc7bc43cabc17cc734f97f9cf2a0696c9` on `feature/comp-01-companion-system`.
Its existing modifications to `Companion.gd`, `WorldController.gd`,
`StateValidation.gd`, and `GameplayTestRunner.gd` were left intact. Final status
matches the initial four modified paths.

## B. Phase 1/2 inventory and report comparison

No separate implementation report was attached to the request. The only local
Phase 1/2 report found was `docs/IMPLEMENTATION_DESIGN.md`, an untracked design and
implementation-order document with unchecked acceptance criteria. It is preserved
byte-for-byte, not interpreted as proof of completed implementation.

| Reported work | Actual local evidence at entry |
| --- | --- |
| NPC, relationship, role, crop definitions | All four `src/scripts/data/{NPC,Relationship,Role,Crop}Definition.gd` files exist, untracked |
| Relationship resource | `src/resources/definitions/RelationshipDefinition.tres` exists, untracked |
| Per-NPC, per-role and per-crop `.tres` files | Absent; profiles/configurations are dictionaries in scripts |
| Four new core systems | All four `src/scripts/systems/{RelationshipSystem,PartySystem,BaseStorage,FarmingSystem}Global.gd` files exist, untracked |
| Generic entity/component | `src/scripts/entities/NPC.gd`, `src/scripts/components/NPCComponent.gd`, `src/scenes/NPC.tscn` exist, untracked |
| FarmPlotComponent | `src/scripts/components/FarmPlotComponent.gd` absent; plots currently live in a dictionary |
| Separate role behavior implementations | Absent; role branches are inside NPCComponent |
| CharacterRoster, GameManager, WorldController, HUD, SaveManager integration | Existing tracked files with pending modifications; actual HUD filename is lowercase `hud.gd` |
| QuestSystem replacement/delegation | Not implemented; `QuestSystemGlobal.gd` remains the legacy quest/trust/recruitment owner |
| Companion replacement | Premature: existing HUD/orders/tests/save validation still use Companion and `Mara` |
| Relationship/farming/switching acceptance tests | No dedicated Phase 1/2 tests at entry; this pass adds compilation/lifecycle/save-decode regression coverage |
| New gallery | Four untracked images exist (listed above); the six tracked gallery images already exist and were not regenerated |

`Companion.gd` remains present and unchanged in the target checkout. Its blob is
`da8adfa64daf14a30a88cfca2dfed7177975249f`. Mara is again spawned as Companion,
and its commands, carry inventory and `world.companion` save contract are active.
The generic NPC work remains alongside it, without spawning a duplicate generic Mara.

### Initial-content preservation record

Before editing, `git hash-object -w` stored the original contents of each of the
24 pending files as local Git blobs. These are content recovery references, not
commits or a claim that the files have been published. Ordinary unreachable-object
garbage collection can eventually expire these blobs. All files also remain locally
present, with the focused recovery edits where applicable.

| File | Initial blob |
| --- | --- |
| `src/project.godot` | `024173688cddeed8e3548c08c4d645460190a88a` |
| `src/scripts/autoloads/GameManagerGlobal.gd` | `811d516298a86d208dc711bb372e5ac0e3309779` |
| `src/scripts/autoloads/SaveManagerGlobal.gd` | `670de1718ad1f081c085cbf3647d5742969af7b8` |
| `src/scripts/entities/WorldController.gd` | `13a38f86867c97b4f77a14acd8e2a7ff21cb0011` |
| `src/scripts/ui/hud.gd` | `59d026e648935ff0d191c8d9acd3487fed638e39` |
| `src/scripts/utils/CharacterRoster.gd` | `a78b123fe02c5e7021abc197495bfd68258b557d` |
| `tools/check.py` | `1289ccbf304267dc060f4e6dc2eba974ab922a39` |
| `docs/IMPLEMENTATION_DESIGN.md` | `b32175e4a639ca443428544d3e82c5b9652a3ba5` |
| `docs/images/05-marie-explore.webp` | `e580c2b6eb4f4082604c65a9d0394feea1aa8d66` |
| `docs/images/06-campfire-cooking.webp` | `4e7ac0aba700d54af8be09e3e201531728e2a9a9` |
| `docs/images/06-inventory-crafting.webp` | `e07cf3ee6f6d8c7908cd054359acb18c8ecbc90a` |
| `docs/images/07-shelter-building.webp` | `0c390c54cf9904d2c4b1623f8ea1155382e071a7` |
| `src/resources/definitions/RelationshipDefinition.tres` | `a36d0c224caa7a14cc24bad1097472c6b7d85e14` |
| `src/scenes/NPC.tscn` | `32cee41c0a772b1748cb1a3b1df578d80a74db16` |
| `src/scripts/components/NPCComponent.gd` | `7379c79d37fb9f89a722f7af0aec3d4becd228f8` |
| `src/scripts/data/CropDefinition.gd` | `8120a96ddf7b52158869a0d3749b82f1ea0b6049` |
| `src/scripts/data/NPCDefinition.gd` | `ab9f9b8dbaa57176ce5e6fba84c4e93dfc028604` |
| `src/scripts/data/RelationshipDefinition.gd` | `d391e9d9fbc590ec9e50ae70ab2d56bda54e70f8` |
| `src/scripts/data/RoleDefinition.gd` | `686eb25f096e939e9cbe5418502562e0abcea29b` |
| `src/scripts/entities/NPC.gd` | `dbb282061c3c36e60630036708a243745983659d` |
| `src/scripts/systems/BaseStorageGlobal.gd` | `3b200d90ff93195058571f220dd8a259ce9899e2` |
| `src/scripts/systems/FarmingSystemGlobal.gd` | `0b5f3c1cb6255c277322cf5511e32cc7b3e39832` |
| `src/scripts/systems/PartySystemGlobal.gd` | `c1da0a51641e91df1d66995097470416e96d12d4` |
| `src/scripts/systems/RelationshipSystemGlobal.gd` | `5a3a282134898bb30c16f2383ba193799345fc66` |

Final hashes of the implementation design and all four untracked images match
their initial hashes above. No tracked image or runtime art bytes were changed.

## C. Root causes and recovery changes

Paths below are under `src/` unless prefixed with `tools/` or `docs/`.

| File(s) | Root cause and focused fix |
| --- | --- |
| `scripts/data/NPCDefinition.gd:19` | Nonexistent `StringValue` type and incompatible override of native `_validate_property(Dictionary) -> void`. Renamed the boolean field validator to `is_field_valid(String)`, retaining its validation behavior without overriding the inspector callback. |
| `scripts/data/RoleDefinition.gd:84` | Exported `uses_base_storage` and static method had the same name. Renamed the method after verifying no callers. Typed action arrays are now populated with `assign`. |
| `scripts/data/CropDefinition.gd:91` | Untyped dictionary keys cannot satisfy a typed string-array API reliably. Explicit typed-array assignment; resource creation exercised for all four existing crop configurations. |
| `scripts/systems/RelationshipSystemGlobal.gd` | Dictionary values, enum keys, and an untyped helper return were used with `:=`. Added explicit String/int/float/Dictionary and NPC return contracts at the affected declarations; used `mini` for integer gain. Quest callback read `npc_id` on NPC rather than its component; corrected that owner. Enum source keys are normalized to match the lowercase configured caps. |
| `scripts/systems/PartySystemGlobal.gd` | `Node.serialize()` and an untyped conversion helper supplied no inferable result type. Cast the actual loaded node to NPC, typed the helper result, and used typed-array assignment when decoding party members. |
| `scripts/systems/BaseStorageGlobal.gd:59` | Claimed `Array[String]` return for `InventoryComponent.get_all_items()`, which actually returns Dictionary. Matched that contract; explicitly typed reserved counts and used integer `mini` for transfers. |
| `scripts/systems/FarmingSystemGlobal.gd` | Reserved `yield` used as signal parameter and local name; renamed harvest count. Undefined `crop_def` in plot text; resolved the existing crop definition. Typed dictionary/array/numeric values at individual failing declarations. Missing plot/crop lookups now use empty dictionaries rather than null before typed assignment. |
| `scripts/components/NPCComponent.gd` | Reserved `yield` local stopped class registration, causing NPC and upstream autoload failures. Renamed it and typed config-derived distances/crop data. NONE role has no config: existing follow/task defaults now handle absent keys. |
| `scenes/NPC.tscn:1-7` | Invalid `uid://...` header syntax and case-mismatched nonexistent `HealthComponent.gd` dependency. Removed the malformed optional UID and referenced the verified lowercase script. Restored NPC collision layer/mask. |
| `scripts/ui/hud.gd:629-858` | Duplicate `_on_dialogue`, dictionary inference failures, and assignment to QuestSystem's constant DIALOGUE. Retained one handler supporting both message forms, explicitly typed UI values, and kept generic talk from mutating/reusing Mara's constant dialogue. |
| `scripts/entities/WorldController.gd:141-163`, `scripts/entities/NPC.gd:5-26` | `setup` ran before `add_child`, so `@onready` component references were null. Setup now follows scene readiness. Illustration is dynamically created under the NPC, not at the nonexistent component child path; retain the actual reference. Health signal connects once in `_ready`; exit unregisters the NPC. |
| `scripts/components/NPCComponent.gd`, `scripts/entities/NPC.gd` | A plain Node component joined a group scanned as Node3D by Player. Group membership now belongs to the NPC body. The death handler called a nonexistent relationship-system method; use RoleDefinition and the existing health restoration API. Full Survivor-role semantics remain incomplete. |
| Four new system autoloads | They precede GameManager in `project.godot`, so immediate `_ready` connections to it are premature. Deferred lifecycle wiring lets all autoloads enter the tree first. The existing autoload order and verified paths are retained. |
| `RelationshipSystemGlobal.gd:23-38`, `FarmingSystemGlobal.gd:21-70` | Relationship connected the same day callback twice. Farming referenced `WorldController` as a singleton/class, but the script registers `IslandWorld` and the signal belongs to a world instance. Connect once to the live world after `game_ready`, and use that instance's elapsed time. Fresh-world plot initialization resets its prior dictionary/counter instead of accumulating duplicates. |
| `WorldController.gd`, `GameManagerGlobal.gd` | Generic replacement removed Mara even though legacy callers were not migrated. Restored active Companion, order delegation and `world.companion` round-trip, while preserving generic NPC code. Restored the public new-game character argument; the pending Dave-default title UI is retained. |
| `scripts/autoloads/SaveManagerGlobal.gd:177-232` | Current v3 files were repeatedly sent through legacy migration, which indexed missing relationship data; this broke temporary-write verification and every save. Only older versions migrate; migration checks/initializes the relationship container. Integration expectation now checks the current save version, with additional v1/v2/v3 decode tests. |
| `scripts/utils/LowPoly.gd:53-61` | A minimal separate probe reproduced Godot 4.3 dummy-renderer `mesh_get_surface_count: m is null` on Label3D teardown. Engine source confirms Label3D owns/frees its mesh. Detach its rendering base in headless mode while retaining label state. Probe plus recovery/stability reruns are clean. |
| `tools/validate_gallery.py`, `tools/test_gallery.py`, `docs/images/gallery.json`, `tests/integration/GameplayGallery.gd` | Validator expected obsolete scenarios, rejected the title's empty character ID, and manifest lacked its source SHA. Reused reviewed fixes from remote `366cf49` / `19a7a47`; existing image hashes are identical upstream. The source SHA is upstream historical evidence, not a new capture claim. Fixed the gallery comment's lint violation. |
| Edited GDScripts | Formatted with installed gdtoolkit 4.3.3, corrected declaration ordering/unused parameters, made immutable config tables constants, and documented the state-dispatch max-returns exemption. No bulk inference replacement and no new preload references. |

The initial downstream errors in GameManager, Player, ResourceNode, ResourceSystem,
NPC, WorldController and GameplayGallery resolved after their actual dependencies
compiled. Fresh import proves recovery does not depend on a stale class cache.

## D. Commands and real results

Executed from `/root/death-island-execution`. Existing tools: Godot
`4.3.stable.official.77dcf97d8`, Python `3.14.4`, gdlint/gdformat `4.3.3`;
`tools/requirements.txt` pins gdtoolkit 4.3.3 and setuptools 80.9.0. No installs.

For engine tests, `XDG_DATA_HOME` points below `/tmp/opencode/death-island-pass1-*`.
The suites' test-save cleanup therefore cannot address the user's normal saves.

| Command | Observed result |
| --- | --- |
| `godot --headless --path src --editor --import --quit` (baseline) | Exit 0 despite many SCRIPT ERROR/ERROR diagnostics; failed compilation, not a pass |
| `python3 tools/check.py` (baseline) | Python 10/10; stopped at 55 lint problems; engine suites not reached |
| First repaired import | Clean script/resource import; integration subsequently exposed migration errors |
| First integration run | 149 passed / 27 failed plus script errors; saves failed |
| Later full check before label fix | Recovery 75/0 but renderer ERROR output; wrapper correctly failed |
| `XDG_DATA_HOME=/tmp/opencode/death-island-pass1-final python3 tools/check.py` (final) | Exit 0; Python 10/10, lint clean, format 63 files clean, Godot import clean, six existing gallery files/hashes/links valid, six images decoded, UNIT 48/0, INTEGRATION 198/0, RECOVERY 75/0, launch smoke clean |
| `XDG_DATA_HOME=/tmp/opencode/death-island-pass1-final python3 tools/check.py --clean-import` | Exit 0; temporary source copy imported with no preexisting `.godot` cache; no script/resource errors |
| `XDG_DATA_HOME=/tmp/opencode/death-island-pass1-stability GODOT_SILENCE_ROOT_WARNING=1 timeout 60s godot --headless --path src res://tests/integration/StabilityTestRunner.tscn` (final) | Exit 0, STABILITY 42/0, no engine errors |
| `git diff --check` | Clean |

Standalone unit/integration/recovery runs were also executed during recovery.
One new regression-runner revision initially had a WeakRef inference error, then
incorrect speaker/numeric-JSON assertions; those test defects were corrected and
the full final suite was run. They were not counted as passes.

Final output still includes gdtoolkit's `pkg_resources` deprecation notice and the
editor's `Could not find version of build tools that matches Target SDK, using
34.0.0` notice. Neither is a script error; Android export itself was not tested.

Raw verification logs are local, under `/tmp/opencode/`:

- `death-island-pass1-baseline-import.log`, `death-island-pass1-baseline-check.log`
- `death-island-pass1-import-2.log`, `death-island-pass1-integration.log`
- `death-island-pass1-integration-2.log`, `death-island-pass1-recovery*.log`
- `death-island-pass1-final-check.log`, `death-island-pass1-final-stability.log`
- `death-island-pass1-clean-import.log`

## E. Remaining blockers (source-inspection findings unless stated otherwise)

1. No separate supplied implementation-completion report to compare. The local
   design is the comparison source, not evidence of completed phases.
2. Character switching remains incomplete: conversion helpers deserialize before
   scene readiness; NPC snapshots omit Player-required health/survival/equipment;
   `marie_npc` is not a canonical playable ID; Dave has no NPC profile; replacement
   node naming and HUD rebinding are unfinished. Switching was not certified by
   these recovery tests.
3. New-system persistence is not integrated. There are no calls to the four
   systems' serialize/deserialize APIs from the production save/world coordinator.
   Migration data is not applied to live relationships; bond level migration is
   incomplete. Generic NPC semantic save validation and health/state ownership
   also need completion. Passing legacy save tests does not certify those fields.
4. New relationships/party/base storage lack a complete new-game/load reset policy.
   Party synchronization handles Mara only; generic team-up/role behavior and
   Survivor immunity do not yet satisfy the design acceptance criteria.
5. Farming has no plot component/scene or registered seed/crop/tool item resources.
   `potato_seed`, `corn_seed`, `tomato_seed`, `herb_seed`, `hoe`, `watering_can` are
   absent from the item catalog. Growth/watering/regrowth and atomic base-storage
   transactions require gameplay work and dedicated tests.
6. The retained pending title UI starts Dave directly, while README/gallery and
   `CharacterTestRunner.gd` still expect `CharacterChoice`. Render/character/gallery
   capture runners were not executed in this no-image-generation pass; this is a
   known follow-up, not a claimed passing render gate.
7. Android build/export, on-device controls/lifecycle/performance and release
   validation were not run. The existing APK was not rebuilt or certified.
8. Runtime pipeline recovery still lives in the dirty working tree. It must be
   included deliberately when preparing a reproducible feature commit/PR.

## F. Final local versus remote work

Two focused commits were made after successful verification:

- `b8463e7` — recover existing gallery validation gates (reviewed upstream fixes).
- `549590b` — detach headless labels from dummy mesh instances.

At this report's completion: **2 local commits ahead, 3 remote commits behind**;
staging area empty. Remote-only history:

```text
19a7a47 test: use valid source revision in gallery fixture
be26ba4 ci: publish verified Android beta APK for testers
366cf49 fix: restore gallery validation and CI checks
```

The gallery validator/test/runner fixes are equivalent locally; remote CI changes
and gallery-documentation changes have not been integrated. Remote manifest and
local manifest have the same evidence/image hashes with different whitespace.

Eight tracked files remain modified: the original seven paths plus
`src/tests/integration/GameplayTestRunner.gd`. Twenty files remain untracked:
the original seventeen, `RecoveryTestRunner.gd`, `RecoveryTestRunner.tscn`, and this
audit. The interdependent pending Phase 1/2 work was not swept into a large feature
commit. All initial files remain; both worktrees' pending work is preserved.

No asset generation, paid asset calls, subagents, dependency installations, save
deletion outside isolated test data, destructive Git operations, or pushes occurred.
