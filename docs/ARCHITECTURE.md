# Death Island architecture

## Runtime ownership

`src/scenes/Main.tscn` is a logic-free bootstrap. `GameManagerGlobal` creates the
UI and title screen, loads `GameWorld.tscn` on a background loader, then installs
one world at `/root/GameWorld` and one CanvasLayer at `/root/UILayer`. Starting or
loading a voyage replaces the world and resets its registries before restoration.

```
UI / TouchControls
    → GameManager requests → Player / gameplay systems
    → read-only content resources
    → validated state snapshots → SaveManager
```

The UI never inserts crafting output or directly changes survival/inventory state.
Godot test runners remain alive while the coordinator swaps worlds, so integration
tests exercise the same lifecycle as the game.

## Content

`DataCatalogGlobal` indexes explicit `ContentPack` resources. The packs contain
typed `ItemDefinition`, `RecipeDefinition`, `EnemyDefinition` and `QuestDefinition`
resources. Explicit references work in exported PCKs without directory-scanning or
`.remap` filename assumptions. Existing lowercase asset/script paths are retained.

* `definitions/items/Items.tres`: 25 materials, consumables, equipment and building kits.
* `definitions/recipes/Recipes.tres`: 15 recipes with aggregated costs/station requirements.
* `definitions/enemies/Enemies.tres`: boar, wolf, cave stalker and guardian.
* `definitions/Island.tres`: five fixed region rectangles, 20 resource placements,
  six enemy placements and batched foliage positions.
* `definitions/quests/Quests.tres`, `dialogue/Mara.tres`: three quests, branching
  rewards/trust and three endings.

`Art.tres` references original SVG illustrations and authored decoration placement.
`tools/illustrate.py` reproducibly creates the character atlas, illustrated props,
animals and small ground textures. `IllustratedArt` aligns transparent sprites to
the fixed camera with their feet anchored on the physics plane. `IllustratedActor`
drives walking/action frames from real gameplay events. A tiled ground shader
blends regions, and a lightweight water shader animates the shoreline. Completed
shelters derive a unified exterior from their four persisted building pieces.

Physics shapes are separate from visuals. The headless renderer retains scene
nodes/action states but omits GPU texture bindings to avoid Godot 4.3 dummy-renderer
cleanup errors. Actual OpenGL rendering is verified by the render/gallery runners.

## Components and systems

* **Player**: CharacterBody3D movement under a fixed orthographic 45-degree camera,
  InputMap keyboard/gamepad events and shared touch actions. Dodge and hit immunity
  use paused game time, not wall-clock time.
* **InventoryComponent**: aggregate item counts, stack-aware slot use, resource-defined
  weights and atomic `preview_exchange`/`exchange`. Failed insertion, batch crafting
  or quest rewards leave both ingredients and output unchanged.
* **EquipmentComponent**: references inventory ownership; condition survives re-equipping.
  Weapon/tool wear, material repairs, armor and hide-set bonus are system logic.
* **SurvivalComponent**: hunger/thirst decay, accumulated starvation/dehydration damage,
  stamina use and delayed regeneration. Consumables resolve through item definitions.
* **Enemy**: patrol → chase → windup → attack → recovery → death. Charge/circle/ambush/
  guard archetypes; one loot roll per death. Stable nodes preserve death/respawn state.
* **ResourceSystem**: registry keyed by authored IDs. Each resource owns gathering,
  cooldown, depletion and respawn; capacity failure does not consume a gather.
* **QuestSystem**: offered/active/complete progression, prerequisites, inventory and
  kill conditions, trust, recruitment and ending selection. Rewards are transactional.
* **Companion**: explicit Follow/Hold/Gather/Return/Assist orders, interrupted by
  nearby combat. Four-slot/12 kg carry inventory uses atomic two-inventory transfer;
  hand gathering shares ResourceNode cooldowns/depletion. Bounded steering cancels
  blocked orders safely. Commands, positions, carry and task budgets persist in
  optional version-2 world data; see `audits/COMP-01.md`.
* **IslandWorld**: map construction, 24-minute day, exploration/travel, nearby stations,
  shelter placement/rest, persistent world snapshots, pooled hit labels and local CSV.

## Persistence

Private application saves live in `user://save/`. There are ten manual slots (0–9),
quicksave (-1) and autosave (-2). The binary header is:

```
magic u32 | version u16 | CRC32 u32 | timestamp u64 | UTF-8 JSON
```

Version 2 stores player transform/stats/items/equipment, known recipes, region
discovery/time, node depletion, enemy state, pickups, buildings, quests/trust/ending.
The v1 reader converts inventory counts and supplies defaults for newly added
systems; it cannot reconstruct world data that the old prototype never recorded.

Reads validate size (2 MiB), depth, checksums, version, JSON types, counts, positions
and component bounds before replacing a live world. Writes verify a temporary
file, rotate three valid backups and atomically replace the primary. Recovery uses
the newest valid backup. Starting a new game does not delete manual saves. Dead
players do not overwrite living autosaves.

Autosaves occur periodically, on pause/backgrounding, discovery, travel, completed
quests, shelter rest and ending selection. Settings use a separate ConfigFile.
Bounded synchronous save work needs latency profiling on device (ADR 001).

## Build and verification

* `tools/check.py`: lint, formatter check, Godot import, real core/integration suites,
  launch smoke. Engine error output fails the gate even after a zero exit status.
* `RenderSmoke.tscn`: title/world/crafting/dialogue rendered through OpenGL into PNGs.
* `GameplayGallery.tscn`: six genuine action captures, state-change assertions and
  an evidence manifest. The README embeds the compact WebP outputs.
* `tools/build_android.py`: generated Godot Gradle project, native ARM64 SDK overlay,
  API 24/35 configuration, verified debug APK. See ADR 002 for pinned tool versions.
* `.github/workflows/ci.yml`: equivalent quality/render gates followed by APK upload.

Device frame-time, touch/lifecycle, thermal/battery, memory soak and release signing
remain separate requirements. Their status is recorded in the roadmap/audit.

## Storage management

`tools/storage.py` audits an explicit allowlist of disposable build/template files.
Deletion requires `--apply`. Build tools require at least 8 GiB free before starting;
Android intermediates can be reclaimed after verification. User saves, source and
signing keys are outside the cleanup allowlist. See ADR 003.
