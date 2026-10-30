class_name EnemyDefinition
extends Resource
## Tunable enemy archetype; loot is rolled once when a living enemy dies.

@export var enemy_id: String = ""
@export var display_name: String = ""
@export var max_health: float = 50.0
@export var attack_damage: float = 12.0
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.8
@export var windup: float = 0.8
@export var move_speed: float = 3.0
@export var detection_range: float = 9.0
@export var patrol_radius: float = 3.0
@export var xp_reward: int = 25
@export var behavior: String = "charge"
@export var tint: Color = Color("865e48")
@export var body_size: Vector3 = Vector3(1.0, 0.8, 1.6)
@export var loot_table: Array[Dictionary] = []
