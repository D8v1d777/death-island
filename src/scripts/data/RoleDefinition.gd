class_name RoleDefinition
extends Resource
## NPC role definitions. Each role has unique behavior and configuration.

enum NPCRole { NONE = -1, GATHERER = 0, DEFENDER = 1, FARMER = 2, SURVIVOR = 3 }

const ROLE_CONFIGS: Dictionary = {
	NPCRole.GATHERER:
	{
		"display_name": "Gatherer",
		"description": "Follows the player and scavenges nearby resources autonomously.",
		"follow_distance": 3.5,
		"task_radius": 12.0,
		"combat_assist": true,
		"combat_assist_damage": 8.0,
		"combat_assist_range": 3.0,
		"combat_assist_cooldown": 2.0,
		"priority_actions": ["harvest_mature", "water_crops", "plant_seeds", "prepare_plots"]
	},
	NPCRole.DEFENDER:
	{
		"display_name": "Defender",
		"description": "Stays at base and protects it from enemy attacks.",
		"follow_distance": 0.0,
		"task_radius": 0.0,
		"base_patrol_radius": 8.0,
		"combat_assist": true,
		"combat_assist_damage": 12.0,
		"combat_assist_range": 5.0,
		"combat_assist_cooldown": 1.5,
		"priority_actions": ["guard_base", "engage_threats", "return_to_post"]
	},
	NPCRole.FARMER:
	{
		"display_name": "Farmer",
		"description": "Operates the farm using base inventory for seeds, water, and tools.",
		"follow_distance": 0.0,
		"task_radius": 15.0,
		"uses_base_storage": true,
		"required_tools": ["hoe", "watering_can"],
		"priority_actions": ["harvest_mature", "water_crops", "plant_seeds", "prepare_plots"]
	},
	NPCRole.SURVIVOR:
	{
		"display_name": "Survivor",
		"description": "Accompanies the party but cannot be killed by enemies.",
		"follow_distance": 3.0,
		"task_radius": 10.0,
		"combat_assist": false,
		"damage_immunity": true,
		"priority_actions": ["follow_player", "avoid_danger"]
	}
}

@export var role_id: NPCRole = NPCRole.NONE
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var follow_distance: float = 3.5
@export var task_radius: float = 12.0
@export var base_patrol_radius: float = 8.0
@export var combat_assist: bool = false
@export var combat_assist_damage: float = 8.0
@export var combat_assist_range: float = 3.0
@export var combat_assist_cooldown: float = 2.0
@export var damage_immunity: bool = false
@export var uses_base_storage: bool = false
@export var required_tools: Array[String] = []
@export var priority_actions: Array[String] = []


static func get_config(role: NPCRole) -> Dictionary:
	return ROLE_CONFIGS.get(role, {})


static func get_display_name(role: NPCRole) -> String:
	return get_config(role).get("display_name", "None")


static func get_description(role: NPCRole) -> String:
	return get_config(role).get("description", "")


static func role_uses_base_storage(role: NPCRole) -> bool:
	return get_config(role).get("uses_base_storage", false)


static func has_damage_immunity(role: NPCRole) -> bool:
	return get_config(role).get("damage_immunity", false)


static func get_priority_actions(role: NPCRole) -> Array[String]:
	var actions: Array[String] = []
	actions.assign(get_config(role).get("priority_actions", []))
	return actions
