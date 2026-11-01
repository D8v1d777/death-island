# Death Island - NPC Relationship & Character Pipeline Implementation Design

## Phase 0 - Repository & Tooling Audit (COMPLETE)

### Current State Analysis

**Existing Systems:**
1. **CharacterRoster** (`src/scripts/utils/CharacterRoster.gd`) - Two playable characters: dave, marie
2. **Companion.gd** (`src/scripts/entities/Companion.gd`) - Hardcoded Mara-only companion with 5 commands
3. **QuestSystemGlobal.gd** - Mara trust/recruitment system (trust 0-10, recruited bool)
4. **SaveManagerGlobal.gd** - Versioned saves with v1 migration support (current v2)
5. **GameManagerGlobal.gd** - Game lifecycle, character selection on title screen
6. **WorldController.gd** - Spawns hardcoded "Mara" Companion at fixed position
7. **HUD.gd** - Dialogue menu showing Mara trust, companion orders
8. **Gallery System** - 6 captures via GameplayGallery.tscn

**Key Files to Modify:**
- `src/scripts/entities/Companion.gd` → Generalize to generic NPC
- `src/scripts/systems/QuestSystemGlobal.gd` → Replace with RelationshipSystemGlobal
- `src/scripts/autoloads/GameManagerGlobal.gd` → Remove title character selection, add party management
- `src/scripts/entities/WorldController.gd` → Generic NPC spawning
- `src/scripts/ui/hud.gd` → New dialogue/configuration UI
- `src/scripts/utils/CharacterRoster.gd` → Add NPC profiles + playable flag
- `src/scripts/autoloads/SaveManagerGlobal.gd` → Add v3 migration
- `src/tests/integration/GameplayGallery.gd` → New gallery captures

**New Files Needed:**
- `src/scripts/data/NPCDefinition.gd` - Data-driven NPC definitions
- `src/scripts/data/RelationshipDefinition.gd` - Bond levels, thresholds, rewards
- `src/scripts/data/RoleDefinition.gd` - Four role definitions
- `src/scripts/data/CropDefinition.gd` - Farming crop definitions
- `src/scripts/systems/RelationshipSystemGlobal.gd` - Per-NPC bond system
- `src/scripts/systems/PartySystemGlobal.gd` - Party/roster management
- `src/scripts/systems/FarmingSystemGlobal.gd` - Farming mechanics
- `src/scripts/systems/BaseStorageGlobal.gd` - Base inventory for NPC roles
- `src/scripts/components/NPCComponent.gd` - Generic NPC behavior component
- `src/scripts/components/FarmPlotComponent.gd` - Farm plot logic
- `src/scripts/entities/NPC.gd` - Generic NPC entity (replaces Companion)

---

## Phase 1 - System Design

### 1. Generic NPC Identity & Roster

**NPCDefinition Resource:**
```gdscript
class_name NPCDefinition extends Resource
@export var npc_id: String           # Unique stable ID (e.g., "mara", "marie", "old_fisher")
@export var display_name: String
@export var art_key: String           # Maps to Art.tres texture
@export var is_playable: bool         # Can be controlled by player
@export var starting_location: Vector3
@export var starting_relationship: int = 0  # Initial bond points
@export var profession: String = "none"     # Default role
@export var dialogue_resource: DialogueDefinition
@export var recruitment_quest: String = ""  # Quest ID to unlock
@export var portrait: Texture2D
```

**CharacterRoster Extensions:**
- Add `NPC_PROFILES` dictionary alongside `PROFILES`
- Methods: `get_npc(npc_id)`, `get_all_npcs()`, `get_playable_npcs()`, `is_npc(npc_id)`

### 2. Relationship/Bond Progression

**RelationshipSystemGlobal (Autoload):**
- `relationships: Dictionary<String, NPCRelationship>` - npc_id → relationship data
- Bond levels: 0 (Stranger) → 1 (Acquaintance) → 2 (Friend) → 3 (Trusted) → 4 (Partner) → 5 (Soulmate)
- Thresholds: [0, 50, 150, 350, 700, 1200] (configurable per NPC)
- Event-based progression: `add_bond(npc_id, amount, source: BondSource)`
- BondSource enum: TRAVEL, GATHER, COMBAT, DISCOVERY, QUEST, CAMP_TASK, DIALOGUE
- Rate limiting: max bond per source per in-game day
- Save/load: serialize all relationships

**NPCRelationship Data Class:**
```gdscript
class NPCRelationship:
    var npc_id: String
    var bond_points: int = 0
    var bond_level: int = 0
    var status: RelationshipStatus = RelationshipStatus.NEUTRAL
    var last_interaction_day: int = 0
    var daily_bond_gained: Dictionary<BondSource, int> = {}
    var team_up_time: float = 0.0
    var shared_activities: Array[String] = []
```

### 3. Party/Team-Up & Role Architecture

**PartySystemGlobal (Autoload):**
- `controlled_character_id: String` - Currently played character
- `party_members: Array[String]` - NPC IDs in party (max 3 including player)
- `npc_roles: Dictionary<String, NPCRole>` - npc_id → assigned role
- `team_up_states: Dictionary<String, bool>` - npc_id → is_teamed_up
- Methods: `switch_character(new_id)`, `add_to_party(npc_id)`, `remove_from_party(npc_id)`, `assign_role(npc_id, role)`

**NPCRole Enum:**
- GATHERER: Follows player, scavenges resources
- DEFENDER: Guards base, attacks nearby enemies
- FARMER: Works farm plots using base storage
- SURVIVOR: Immune to enemy damage

**RoleBehavior Interface:**
Each role implements: `on_teamed_up()`, `on_untucked()`, `process(delta)`, `get_status_text()`, `save()`, `load()`

### 4. Character Switching

**Requirements:**
- Dave starts as default (no title screen selection)
- Switch via in-world NPC interaction at bond level 4+
- Former player becomes NPC with assigned role
- New player becomes controlled character
- Preserve: identity, appearance, stats, inventory, equipment, relationships
- World position preserved, no duplication
- Save/load maintains correct ownership

**Implementation:**
- `PartySystemGlobal.switch_character(target_npc_id)`
- Swaps `controlled_character_id`
- Transfers `Player` node control to new NPC
- Former player gets `NPCComponent` with assigned role
- CharacterRoster handles art/texture swap
- Save system serializes all party member states

### 5. Farming & Base Inventory

**CropDefinition Resource:**
```gdscript
class_name CropDefinition extends Resource
@export var crop_id: String
@export var display_name: String
@export var seed_item_id: String
@export var harvest_item_id: String
@export var growth_stages: int = 4
@export var stage_durations: Array[float] = [360, 360, 360, 360]  # minutes per stage
@export var water_required_per_stage: Array[int] = [1, 1, 1, 1]
@export var harvest_yield: int = 1
@export var regrows: bool = false
@export var regrowth_stages: int = 2
```

**FarmPlotComponent:**
- State: empty, tilled, planted (crop_id, stage, watered), mature, harvested
- Methods: `till()`, `plant(crop_id)`, `water()`, `harvest()`, `get_state()`
- Uses game time (WorldController.elapsed), persists across saves

**BaseStorageGlobal (Autoload):**
- Centralized inventory for NPC role operations
- Transactional: `reserve(items)`, `commit()`, `rollback()`
- Capacity limits, stack/weight limits
- Used by Farmer NPC for seeds/water, Gatherer for deposits

### 6. Save Migration (v2 → v3)

**New Save Fields:**
```gdscript
data["relationships"] = RelationshipSystemGlobal.serialize()
data["party"] = PartySystemGlobal.serialize()
data["farming"] = FarmingSystemGlobal.serialize()
data["base_storage"] = BaseStorageGlobal.serialize()
```

**Migration Logic:**
- Mara's trust → bond_points (trust * 50, maps to level 2-3)
- Mara's recruited → team_up_state + GATHERER role
- Legacy saves get default relationships for other NPCs
- Player character_id preserved
- Farm plots empty by default

---

## Phase 2 - Implementation Order

### 2.1 Data Definitions (Resources)
1. `NPCDefinition.gd` - NPC data structure
2. `RelationshipDefinition.gd` - Bond levels, thresholds
3. `RoleDefinition.gd` - Four role configs
4. `CropDefinition.gd` - Farming crops (3+ crops)
5. Create `.tres` resources for each NPC, role, crop

### 2.2 Core Systems (Autoloads)
1. `RelationshipSystemGlobal.gd` - Per-NPC bond system
2. `PartySystemGlobal.gd` - Party management, character switching
3. `BaseStorageGlobal.gd` - Base inventory for NPC roles
4. `FarmingSystemGlobal.gd` - Farm plot management, crop growth

### 2.3 Generic NPC Entity
1. `NPCComponent.gd` - Behavior component (replaces Companion logic)
2. `NPC.gd` - Entity script using NPCComponent
3. Role behavior implementations
4. Update `WorldController.gd` to spawn NPCs from definitions

### 2.4 Integration
1. Update `QuestSystemGlobal.gd` → delegate to RelationshipSystemGlobal
2. Update `GameManagerGlobal.gd` - remove title selection, add party init
3. Update `HUD.gd` - new dialogue/configuration panels
4. Update `SaveManagerGlobal.gd` - v3 migration

---

## Acceptance Criteria Per Phase

### Phase 2 Complete When:
- [ ] Multiple NPCs can exist simultaneously with independent relationships
- [ ] Mara's trust migrates to bond system correctly
- [ ] Legacy saves load without errors
- [ ] New NPCs (Marie, others) can be added via data only
- [ ] Unit tests pass for relationship progression

### Phase 3 Complete When:
- [ ] Dave starts by default (no title character select)
- [ ] In-world NPC interaction shows Talk/Team Up/Configure
- [ ] Bond level 4 unlocks "Switch to play as [NPC]" dialogue
- [ ] Character switching works both ways
- [ ] No duplicate characters, state preserved

### Phase 4 Complete When:
- [ ] All 4 roles implemented and assignable per NPC
- [ ] Gatherer follows and gathers autonomously
- [ ] Defender guards base and attacks enemies
- [ ] Farmer plants/waters/harvests using base storage
- [ ] Survivor takes no enemy damage
- [ ] Roles persist through save/load

### Phase 5 Complete When:
- [ ] 3+ crops with different growth times/yields
- [ ] Player can farm manually (till, plant, water, harvest)
- [ ] Farmer NPC operates same system autonomously
- [ ] Crop state persists save/load
- [ ] No free resource generation

### Phase 7 Complete When:
- [ ] Gallery shows 6 new captures (no title screen)
- [ ] Captures: NPC bond 4 dialogue, config panel, gatherer, defender, farmer, harvest
- [ ] validate_gallery.py passes
- [ ] README.md links match actual files

---

## Testing Strategy

### Unit Tests (tools/test_*.py + Godot unit tests)
- Relationship progression math
- Bond level thresholds
- Role behavior logic
- Farming crop growth calculations
- Save migration v2→v3

### Integration Tests (Godot headless)
- NPC spawning from definitions
- Character switching round-trip
- Team-up with role behaviors
- Farming loop with Farmer NPC
- Save/load with all new systems

### Gallery/Visual Tests
- Capture 6 new gameplay screenshots
- Validate via tools/validate_gallery.py
- Verify README links

---

## Blockers & Risks

1. **Save Migration Complexity** - Need careful v2→v3 mapping, test with real saves
2. **Character Switching Architecture** - Player node management must be robust
3. **NPC AI Performance** - Multiple NPCs with roles on Android ARM64
4. **Art Pipeline** - New NPC art keys must exist in Art.tres
5. **Gallery Validation** - Must update validate_gallery.py FILES list

---

## Next Steps

1. Create data definition scripts (NPCDefinition, RelationshipDefinition, RoleDefinition, CropDefinition)
2. Create example .tres resources
3. Implement RelationshipSystemGlobal
4. Implement PartySystemGlobal
5. Generalize Companion → NPC with NPCComponent
6. Continue through phases sequentially
