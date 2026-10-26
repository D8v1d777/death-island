extends Resource
class_name EnemyDefinition

enum AIType {
	PASSIVE,
	AGGRESSIVE,
	TERRITORIAL,
	FLEEING
}

@export var enemy_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var max_health: float = 50.0
@export var damage: float = 10.0
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.5
@export var move_speed: float = 3.0
@export var detection_range: float = 10.0
@export var attack_damage: float = 15.0
@export var xp_reward: int = 25
@export var loot_table: Array[Dictionary] = []  # [{"item_id": "wood", "count": 1, "chance": 0.5}, ...]
@export var ai_type: AIType = AIType.AGGRESSIVE
@export var patrol_radius: float = 5.0

func _validate_property(property: String) -> bool:
	match property:
		"enemy_id":
			return enemy_id != ""
		"max_health":
			return max_health > 0.0
		"damage":
			return damage >= 0.0
		"attack_range":
			return attack_range > 0.0
		"attack_cooldown":
			return attack_cooldown > 0.0
		"move_speed":
			return move_speed >= 0.0
		"detection_range":
			return detection_range > 0.0
		"loot_table":
			for loot in loot_table:
				if not loot.has("item_id") or not loot.has("count") or not loot.has("chance"):
					return false
				if loot.chance < 0.0 or loot.chance > 1.0:
					return false
			return true
		_:
			return true