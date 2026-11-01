class_name CharacterRoster
extends RefCounted
## Canonical playable-character IDs and runtime art mappings.
## Reference sheets are not animation atlases; runtime uses packed 8-frame SVG strips.

const PROFILES: Dictionary = {
	"dave": {"display_name": "Dave", "art_key": "dave"},
	"marie": {"display_name": "Marie", "art_key": "marie"},
}

const NPC_PROFILES: Dictionary = {
	"mara":
	{
		"display_name": "Mara",
		"art_key": "mara",
		"is_playable": false,
		"starting_location": Vector3(4, 0, 32),
		"starting_bond": 0,
		"default_role": "gatherer",
		"description": "Ship's engineer. Practical, loyal, knows the island's machinery."
	},
	"marie_npc":
	{
		"display_name": "Marie",
		"art_key": "marie",
		"is_playable": true,
		"starting_location": Vector3(-2, 0, 38),
		"starting_bond": 0,
		"default_role": "survivor",
		"description": "Resourceful survivor. Skilled at foraging and staying alive."
	},
	"old_fisher":
	{
		"display_name": "Old Fisher",
		"art_key": "survivor",
		"is_playable": false,
		"starting_location": Vector3(12, 0, 44),
		"starting_bond": 0,
		"default_role": "defender",
		"description": "Grizzled veteran of the shores. Knows every tide and current."
	}
}


static func has_character(character_id: String) -> bool:
	return PROFILES.has(character_id.strip_edges().to_lower())


static func normalize_id(character_id: String) -> String:
	var normalized := character_id.strip_edges().to_lower()
	return normalized if PROFILES.has(normalized) else "dave"


static func display_name(character_id: String) -> String:
	return str(PROFILES[normalize_id(character_id)].display_name)


static func art_key(character_id: String) -> String:
	return str(PROFILES[normalize_id(character_id)].art_key)


static func has_npc(npc_id: String) -> bool:
	return NPC_PROFILES.has(npc_id.strip_edges().to_lower())


static func get_npc(npc_id: String) -> Dictionary:
	var normalized := npc_id.strip_edges().to_lower()
	return NPC_PROFILES.get(normalized, {})


static func get_all_npcs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for npc_id in NPC_PROFILES:
		var data: Dictionary = NPC_PROFILES[npc_id].duplicate(true)
		data["npc_id"] = npc_id
		result.append(data)
	return result


static func get_playable_npcs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for npc_id in NPC_PROFILES:
		if NPC_PROFILES[npc_id].is_playable:
			var data: Dictionary = NPC_PROFILES[npc_id].duplicate(true)
			data["npc_id"] = npc_id
			result.append(data)
	return result


static func is_npc(npc_id: String) -> bool:
	return NPC_PROFILES.has(npc_id.strip_edges().to_lower())


static func is_playable_npc(npc_id: String) -> bool:
	var normalized := npc_id.strip_edges().to_lower()
	return NPC_PROFILES.has(normalized) and NPC_PROFILES[normalized].is_playable


static func get_npc_art_key(npc_id: String) -> String:
	var normalized := npc_id.strip_edges().to_lower()
	if NPC_PROFILES.has(normalized):
		return str(NPC_PROFILES[normalized].art_key)
	return "survivor"


static func get_npc_starting_location(npc_id: String) -> Vector3:
	var normalized := npc_id.strip_edges().to_lower()
	if NPC_PROFILES.has(normalized):
		return NPC_PROFILES[normalized].starting_location
	return Vector3.ZERO


static func get_npc_default_role(npc_id: String) -> String:
	var normalized := npc_id.strip_edges().to_lower()
	if NPC_PROFILES.has(normalized):
		return str(NPC_PROFILES[normalized].default_role)
	return "none"
