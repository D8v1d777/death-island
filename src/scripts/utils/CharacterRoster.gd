class_name CharacterRoster
extends RefCounted
## Canonical playable-character IDs and runtime art mappings.
## Reference sheets are not animation atlases; runtime uses packed 8-frame SVG strips.

const PROFILES: Dictionary = {
	"dave": {"display_name": "Dave", "art_key": "dave"},
	"marie": {"display_name": "Marie", "art_key": "marie"},
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
