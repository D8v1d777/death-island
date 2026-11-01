class_name RelationshipDefinition
extends Resource
## Bond level thresholds and progression rewards. Data-driven relationship progression.

@export var bond_level_names: Array[String] = [
	"Stranger", "Acquaintance", "Friend", "Trusted", "Partner", "Soulmate"
]

@export var bond_thresholds: Array[int] = [0, 50, 150, 350, 700, 1200]

@export var max_bond_level: int = 5

@export var daily_bond_caps: Dictionary = {
	"travel": 30,
	"gather": 20,
	"combat": 25,
	"discovery": 15,
	"quest": 50,
	"camp_task": 10,
	"dialogue": 5
}

@export var bond_rewards: Dictionary = {
	"level_1": {"unlock": "basic_dialogue"},
	"level_2": {"unlock": "team_up", "trust_bonus": 1},
	"level_3": {"unlock": "configure_role", "trust_bonus": 1},
	"level_4": {"unlock": "character_switch", "trust_bonus": 2},
	"level_5": {"unlock": "special_ending", "trust_bonus": 3}
}

@export var relationship_statuses: Array[String] = [
	"Hostile", "Unfriendly", "Neutral", "Friendly", "Close", "Intimate"
]


func get_bond_level(bond_points: int) -> int:
	for i in range(max_bond_level + 1):
		if i == max_bond_level or bond_points < bond_thresholds[i + 1]:
			return i
	return max_bond_level


func get_progress_to_next(bond_points: int) -> float:
	var level := get_bond_level(bond_points)
	if level >= max_bond_level:
		return 1.0
	var current_threshold := bond_thresholds[level]
	var next_threshold := bond_thresholds[level + 1]
	return float(bond_points - current_threshold) / float(next_threshold - current_threshold)


func get_status(bond_level: int) -> String:
	var idx := clampi(bond_level, 0, relationship_statuses.size() - 1)
	return relationship_statuses[idx]


func can_switch_character(bond_level: int) -> bool:
	return bond_level >= 4


func get_daily_cap(source: String) -> int:
	return daily_bond_caps.get(source, 10)
