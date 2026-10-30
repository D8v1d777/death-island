# COMP-01 — companion utility verification (2026-10-30)

Base: GitHub `master` b3e611edc7bc43cabc17cc734f97f9cf2a0696c9, fetched and
verified with `git ls-remote origin refs/heads/master`. Worktree:
`/root/death-island-execution`, branch `feature/pending-companion-relationships`.
The older `/root/death-island` checkout and its untracked project files were preserved.

## Implemented acceptance

Mara accepts Follow, Hold, Gather, Return and Assist through dialogue and the
journal's companion-orders button. Commands and runtime states are separate:
combat temporarily overrides the current command; gathering resumes only while
the resource remains valid, within 12 m of both characters and its 30-second budget.
Depletion, capacity or timeout ends gathering and returns the carried resources.
Hold defends in melee without pursuing. Follow has arrival hysteresis.

The real InventoryComponent enforces four stack slots / 12 kg. Hand gathering uses
ResourceNode's existing 0.35-second cooldown, tool gate, four gathers and respawn.
Mara has no equipped tool, so tool-gated nodes are rejected. Pickups enter her pack.
InventoryComponent.transfer_to commits both inventories before observer signals;
partial transfers retain every untransferred item. Node/pickup claims precede
inventory callbacks to prevent duplicate rewards and snapshot duplication.

Movement uses collisions, local obstacle steering, a 5-second no-progress limit
and a 60-second continuous-travel limit. An unreachable order becomes Hold with a
message and intact supplies. No distance-triggered teleport remains. This is
bounded local steering, not a full navigation mesh; complicated routes may need
a new order from a clearer position. Fast travel can leave Mara behind; the
journal permits remote Return orders without moving items remotely.

## Save compatibility

Optional `world.companion` extends version 2: command, current/held positions,
carry inventory, authored target ID, remaining gather budget and attack cooldown.
Transient combat references are reacquired from the new world. Invalid resource
targets safely cancel on the next tick. Malformed records fail StateValidation
before world replacement or save overwrite. Version-1 migration is unchanged;
old version-2 worlds default to Follow/empty carry. Resource cooldown now persists.

## Commands and observed results

All commands ran in the worktree with Godot 4.3.stable.official.77dcf97d8 and
gdtoolkit 4.3.3 / setuptools 80.9.0.

| Command | Observed result |
|---|---|
| `python3 tools/check.py` before edits | lint/format/import/launch passed; UNIT 40/0, INTEGRATION 145/0 |
| `gdformat` on changed scripts/tests | completed; initial six files reformatted, subsequent edited files reformatted |
| `python3 tools/check.py` initial implementation | lint failed: coordinator public-method count and order function return count; no engine tests executed |
| same command, next two attempts | lint failed on coordinator directive placement; moved directive to first line |
| same command after lint fixes | lint/format/import/unit passed; INTEGRATION 191 passed / 3 failed |
| diagnosis | stack fixture hit weight limit first; replaced with four stack-size-one hoods. Decoded JSON numeric comparison changed to typed count. |
| `python3 -c 'from tools.check import run; run(["godot", "--headless", "--path", "src", "res://tests/integration/TestRunner.tscn"], "INTEGRATION:")'` | 194 passed / 0 failed |
| final `python3 tools/check.py` after watchdog/observer coverage | lint passed; 48 scripts format-clean; import passed; UNIT **40/0**; INTEGRATION **198/0**; main launch passed |
| `python3 tools/check.py --clean-import` | uncached source-only import passed; temporary project automatically removed |
| `python3 tools/check.py --render-only` | OpenGL title/island/crafting/dialogue capture passed (llvmpipe); V-Sync unsupported warning |
| `git diff --check`, `git diff`, `git ls-tree -r --name-only HEAD`, `git status --short` | whitespace clean; source tree and changed files inspected; no project/asset/CI deletions |

Integration assertions cover valid/invalid gathering, shared cooldown, finite
depletion, carry weight/stacks, partial/full-player transfer, exactly-once pickup
and transfer, observer consistency, actual enemy interruption/resumption, task
timeout, on-foot follow/return, no arrival jitter, collision-cage cancellation,
real disk round-trip, malformed rejection and legacy defaults. Existing quest,
ending, crafting, equipment, twelve-slot and backup/migration tests still pass.

No Android export, installation or physical-device acceptance is claimed by this
milestone audit. A later session build audit must identify the actual artifact.
Complex-route playtesting, touch usability, GPU performance and lifecycle remain
DEVICE-01 gates. Existing SDK fallback and Python pkg_resources warnings persist.

## Reviewed scope

Companion, inventory, ResourceNode, ItemPickup, resource registry, WorldController,
StateValidation, GameManager request delegation, HUD, integration runner and new
CompanionTests; architecture, roadmap, pending ledger and this audit. The only
lint exception is the coordinator's method-count heuristic: keeping UI intents in
the established owner avoids introducing a duplicate command manager.
