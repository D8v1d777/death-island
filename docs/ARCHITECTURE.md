# Architecture Document — Death Island

## Overview

This document describes the technical architecture for Death Island, an Android survival RPG built with Godot 4 using GDScript.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Main.tscn                             │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │   GameWorld     │  │    UILayer      │  (CanvasLayer)    │
│  │   (Node3D)      │  │   (Control)     │                   │
│  └────────┬────────┘  └────────┬────────┘                   │
└───────────┼────────────────────┼────────────────────────────┘
            │                    │
            ▼                    ▼
┌─────────────────────────────────────────────────────────────┐
│                      Autoloads (Singletons)                  │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐            │
│  │GameManager  │ │ SaveManager │ │AudioManager │  ...       │
│  └─────────────┘ └─────────────┘ └─────────────┘            │
└─────────────────────────────────────────────────────────────┘
            │                    │
            ▼                    ▼
┌─────────────────────────────────────────────────────────────┐
│                    Gameplay Systems                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐        │
│  │ Combat   │ │ Crafting │ │ Survival │ │   AI     │        │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘        │
└─────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                              │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐            │
│  │  Items      │ │  Recipes    │ │  Enemies    │  ...       │
│  │ (Resource)  │ │ (Resource)  │ │ (Resource)  │            │
│  └─────────────┘ └─────────────┘ └─────────────┘            │
└─────────────────────────────────────────────────────────────┘
```

## Core Systems

### 1. GameManagerGlobal (Autoload)
**Responsibility**: Central game state coordination, scene transitions, pause/resume

```gdscript
# Key signals
signal game_paused
signal game_resumed
signal scene_changing(new_scene: String)
signal scene_changed(scene_name: String)

# Key methods
func change_scene(target: String) -> void
func pause_game() -> void
func resume_game() -> void
func new_game() -> void
func load_game(slot: int) -> void
```

### 2. SaveManagerGlobal (Autoload)
**Responsibility**: Save/load operations, versioning, corruption recovery

```gdscript
# Save format: binary with header
# Header: magic(4) + version(2) + checksum(4) + timestamp(8)
# Body: JSON-serialized game state

func save_game(slot: int, state: Dictionary) -> Error
func load_game(slot: int) -> Dictionary?
func delete_save(slot: int) -> void
func list_saves() -> Array[Dictionary]
func validate_save(data: PackedByteArray) -> bool
```

**Save Data Structure**:
```json
{
  "version": 1,
  "timestamp": 1700000000,
  "player": {
    "position": [x, y, z],
    "rotation": [x, y, z],
    "health": 100,
    "stamina": 100,
    "hunger": 80,
    "thirst": 70,
    "inventory": [...],
    "equipment": {...},
    "known_recipes": [...],
    "completed_quests": [...],
    "npc_trust": {...}
  },
  "world": {
    "time_of_day": 0.5,
    "resource_nodes": [...],
    "enemy_spawns": [...],
    "placed_objects": [...]
  },
  "settings": {...}
}
```

### 3. CombatSystem (Script)
**Responsibility**: Damage calculation, hit detection, knockback, status effects

```gdscript
# Damage calculation
func calculate_damage(attacker: Entity, defender: Entity, attack_data: AttackData) -> float:
    base = attack_data.base_damage * attacker.damage_multiplier
    defense = defender.armor * 0.5
    return max(1, base - defense)

# Hit detection
func raycast_attack(origin: Vector3, direction: Vector3, range: float, layers: int) -> Dictionary?
```

### 4. CraftingSystem (Script)
**Responsibility**: Recipe validation, resource consumption, result generation

```gdscript
func can_craft(recipe: RecipeDefinition, inventory: Inventory) -> bool
func craft(recipe: RecipeDefinition, inventory: Inventory) -> Array[ItemStack]
func get_available_recipes(inventory: Inventory, known_recipes: Array) -> Array[RecipeDefinition]
```

### 5. SurvivalSystem (Script)
**Responsibility**: Hunger/thirst decay, stamina regen, environmental effects

```gdscript
func process_survival(delta: float, player: Player) -> void:
    player.hunger = max(0, player.hunger - HUNGER_RATE * delta)
    player.thirst = max(0, player.thirst - THIRST_RATE * delta)
    if player.hunger == 0 or player.thirst == 0:
        player.health -= STARVATION_DAMAGE * delta
```

### 6. AISystem (Script)
**Responsibility**: Enemy behavior trees, pathfinding, aggro management

```gdscript
# Behavior states: IDLE, PATROL, CHASE, ATTACK, FLEE, DEAD
func update_ai(enemy: Enemy, delta: float, player: Player) -> void
func find_path(start: Vector3, target: Vector3) -> Array[Vector3]
func check_aggro(enemy: Enemy, player: Player) -> bool
```

## Entity Architecture

### Base Classes

```
Entity (CharacterBody3D)
├── HealthComponent
├── StatsComponent
└── InteractionComponent

Player (Entity)
├── PlayerController (input, movement)
├── PlayerCamera (third-person)
├── InventoryComponent
├── CraftingComponent
└── SurvivalComponent

Enemy (Entity)
├── AIComponent
├── LootComponent
└── CombatComponent

NPC (Entity)
├── DialogueComponent
├── QuestComponent
├── TrustComponent
└── CompanionComponent (if recruited)

ResourceNode (StaticBody3D)
├── GatherableComponent
└── RespawnComponent
```

### Component Pattern

Each component is a separate script attached as a child node:

```gdscript
# HealthComponent.gd
extends Node
class_name HealthComponent

@export var max_health: float = 100.0
var current_health: float = 100.0

signal health_changed(new_health: float, max_health: float)
signal died

func take_damage(amount: float, source: Node = null) -> void
func heal(amount: float) -> void
func kill() -> void
```

## Data Definitions (Resources)

All game content defined as `Resource` subclasses for editor editing and runtime loading.

### ItemDefinition (Resource)
```gdscript
class_name ItemDefinition
extends Resource

@export var item_id: StringName
@export var display_name: String
@export var description: String
@export var icon: Texture2D
@export var max_stack: int = 99
@export var weight: float = 0.1
@export var item_type: ItemType  # enum: CONSUMABLE, TOOL, WEAPON, ARMOR, MATERIAL, QUEST
@export var rarity: Rarity      # enum: COMMON, UNCOMMON, RARE, EPIC, LEGENDARY
@export var consumable_effect: ConsumableEffect?  # if CONSUMABLE
@export var equipment_slot: EquipmentSlot?        # if WEAPON/ARMOR
@export var tool_power: int = 0                   # if TOOL
@export var durability: int = 0                   # 0 = infinite
```

### RecipeDefinition (Resource)
```gdscript
class_name RecipeDefinition
extends Resource

@export var recipe_id: StringName
@export var display_name: String
@export var description: String
@export var ingredients: Array[RecipeIngredient]
@export var results: Array[RecipeResult]
@export var crafting_station: CraftingStationType  # enum: NONE, WORKBENCH, FORGE, CAMPFIRE
@export var craft_time: float = 1.0
@export var required_skill_level: int = 0
@export var unlock_condition: UnlockCondition?

struct RecipeIngredient:
    var item: ItemDefinition
    var count: int
    var consumed: bool = true

struct RecipeResult:
    var item: ItemDefinition
    var count: int
    var probability: float = 1.0
```

### EnemyDefinition (Resource)
```gdscript
class_name EnemyDefinition
extends Resource

@export var enemy_id: StringName
@export var display_name: String
@export var base_health: float = 50.0
@export var base_damage: float = 10.0
@export var move_speed: float = 3.0
@export var attack_range: float = 2.0
@export var detection_range: float = 15.0
@export var attack_cooldown: float = 2.0
@export var loot_table: LootTable
@export var behavior_tree: BehaviorTreeResource
@export var model_scene: PackedScene
@export var hitbox_shape: CollisionShape3D
```

## Input System

### InputMap Actions (Defined in project.godot)

| Action | Type | Desktop | Mobile |
|--------|------|---------|--------|
| `move_forward` | Axis | W | Joystick Y+ |
| `move_backward` | Axis | S | Joystick Y- |
| `move_left` | Axis | A | Joystick X- |
| `move_right` | Axis | D | Joystick X+ |
| `camera_horizontal` | Axis | Mouse X | Touch Drag X |
| `camera_vertical` | Axis | Mouse Y | Touch Drag Y |
| `attack_light` | Button | LMB | Button A |
| `attack_heavy` | Button | RMB | Button B |
| `dodge` | Button | Shift | Button C |
| `interact` | Button | E | Button D |
| `inventory` | Button | Tab | Button E |
| `pause` | Button | Esc | Button F |

### Virtual Joystick (Mobile)
- Left screen zone: 40% width × 100% height
- Dead zone: 15% radius
- Output: normalized Vector2 (-1 to 1)

### Touch Camera
- Right screen zone: 60% width × 100% height
- Drag to rotate camera around player
- Pinch for zoom (if implemented)

## Rendering Pipeline

### Compatibility Renderer (M0-M2)
- No real-time shadows (baked lightmaps only)
- Single directional light (sun) + ambient
- Maximum 4 omnidirectional lights per scene
- No SSAO, SSR, or volumetric fog
- Mobile MSAA 2x or FXAA

### Forward+ Renderer (M3+, if profiled viable)
- Enable only after 30 FPS stable on target
- Clustered lighting (max 32 lights)
- Optional: SSAO, DOF, Bloom (with quality settings)

### Texture Budget
| Category | Max Resolution | Format | Notes |
|----------|---------------|--------|-------|
| UI/Atlas | 2048×2048 | ASTC 4x4 | Single atlas for all UI |
| Character | 1024×1024 | ASTC 4x4 | Albedo + ORM packed |
| Environment | 1024×1024 | ASTC 4x4 | Tiling textures |
| Effects | 512×512 | ASTC 4x4 | Particles, decals |

### Mesh Budget
| Category | Max Triangles | Max Vertices |
|----------|--------------|--------------|
| Player | 3,000 | 1,500 |
| Enemy | 2,000 | 1,000 |
| NPC | 2,500 | 1,200 |
| Prop (large) | 1,500 | 800 |
| Prop (small) | 500 | 300 |
| Foliage (billboard) | 2 quads | 4 |

## Scene Management

### Main Scene Structure
```
Main.tscn
├── GameManagerGlobal (autoload)
├── SaveManagerGlobal (autoload)
├── AudioManagerGlobal (autoload)
├── InputManagerGlobal (autoload)
├── LoggerGlobal (autoload)
├── GameWorld (Node3D)
│   ├── Player (instance)
│   ├── Environment (Node3D)
│   │   ├── Terrain
│   │   ├── Foliage
│   │   ├── ResourceNodes
│   │   └── EnemySpawns
│   └── DynamicObjects (Node3D)
│       ├── Enemies
│       ├── NPCs
│       └── DroppedItems
└── UILayer (CanvasLayer)
    ├── HUD (Control)
    ├── PauseMenu (Control)
    ├── InventoryUI (Control)
    ├── CraftingUI (Control)
    ├── DialogueUI (Control)
    └── LoadingScreen (Control)
```

### Scene Transitions
- Use `SceneTree.change_scene_to_file()` for major transitions
- Keep `GameWorld` persistent; swap only environment sub-scenes
- Show `LoadingScreen` during async resource loading
- Save before transition, load after

## Networking (Not Applicable)
Death Island is **offline-first, single-player**. No networking code in M0-M4.

## Security Considerations

- No network = no remote attack surface
- Save files: binary format + checksum + version validation
- No `eval()`, `loadstring()`, or dynamic code execution
- Input validation at all system boundaries
- Android Keystore for any encryption keys (if needed later)

## Extensibility Points

1. **New Items**: Add `ItemDefinition` resource → appears in editor
2. **New Recipes**: Add `RecipeDefinition` → auto-discovered by CraftingSystem
3. **New Enemies**: Add `EnemyDefinition` + behavior tree → spawnable
4. **New Quests**: Add quest data resource → QuestSystem handles
5. **New Regions**: Add environment scene → GameWorld manages instancing

---

*Update this document when architecture changes. Significant changes require ADR in `docs/DECISIONS/`.*