class_name NPCDefinition
extends Resource
## Data-driven NPC definition. All NPCs defined here, not hardcoded.

@export var npc_id: String = ""
@export var display_name: String = ""
@export var art_key: String = ""
@export var is_playable: bool = false
@export var starting_location: Vector3 = Vector3.ZERO
@export var starting_bond: int = 0
@export var default_role: String = "none"
@export var dialogue_resource: Resource
@export var recruitment_quest_id: String = ""
@export var portrait: Texture2D
@export var description: String = ""
@export var base_stats: Dictionary = {"health": 100, "stamina": 100, "attack": 10, "defense": 5}


func is_field_valid(property: String) -> bool:
	if property == "npc_id":
		return not npc_id.is_empty() and npc_id.is_valid_identifier()
	if property == "art_key":
		return not art_key.is_empty()
	return true
