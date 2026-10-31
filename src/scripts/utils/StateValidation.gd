class_name StateValidation
extends RefCounted
## Bounds-check saved JSON before any live state is replaced.

const MAX_COORDINATE := 150.0


static func vector(value: Variant) -> bool:
	return (
		value is Array
		and value.size() == 3
		and number(value[0], -MAX_COORDINATE, MAX_COORDINATE)
		and number(value[1], -MAX_COORDINATE, MAX_COORDINATE)
		and number(value[2], -MAX_COORDINATE, MAX_COORDINATE)
	)


static func number(value: Variant, minimum: float, maximum: float) -> bool:
	return (
		(value is int or value is float)
		and is_finite(float(value))
		and value >= minimum
		and value <= maximum
	)


static func vec3(value: Array) -> Vector3:
	return Vector3(float(value[0]), float(value[1]), float(value[2]))


static func array3(value: Vector3) -> Array:
	return [value.x, value.y, value.z]


static func state(data: Dictionary) -> bool:
	if (
		not _bounded(data)
		or not data.get("player") is Dictionary
		or not data.get("world") is Dictionary
		or not data.get("quests", {}) is Dictionary
	):
		return false
	var player: Dictionary = data.player
	if not vector(player.get("position")) or not vector(player.get("rotation", [0, 0, 0])):
		return false
	for stat in ["health", "stamina", "hunger", "thirst"]:
		if not number(player.get(stat), 0, 1000):
			return false
	if not number(player.get("experience", 0), 0, 1000000):
		return false
	if not player.get("character_id", "dave") is String:
		return false
	if not player.get("inventory") is Dictionary or not player.get("equipment", {}) is Dictionary:
		return false
	var inventory := InventoryComponent.new()
	var valid := inventory.deserialize(player.inventory)
	inventory.free()
	if not valid or not _equipment(player.get("equipment", {})):
		return false
	var world: Dictionary = data.world
	if not number(world.get("elapsed", 360.0), 0, 1e9):
		return false
	for key in ["resources", "enemies"]:
		if not world.get(key, {}) is Dictionary:
			return false
		for entry in world.get(key, {}).values():
			if not entry is Dictionary:
				return false
			if entry.has("position") and not vector(entry.position):
				return false
			for field in ["health", "gathers", "respawn_timer"]:
				if entry.has(field) and not number(entry[field], 0, 1e6):
					return false
			for field in ["is_depleted", "dead"]:
				if entry.has(field) and not entry[field] is bool:
					return false
			if key == "enemies":
				var dead: bool = entry.get("dead", false)
				if dead != (float(entry.get("health", 1)) == 0):
					return false
	for key in ["structures", "pickups"]:
		if not world.get(key, []) is Array or world.get(key, []).size() > 64:
			return false
		for entry in world.get(key, []):
			if not entry is Dictionary or not vector(entry.get("position")):
				return false
			if (
				key == "structures"
				and not (
					entry.get("kind", "")
					in ["campfire", "workbench", "forge", "foundation", "wall", "roof", "door"]
				)
			):
				return false
			if (
				key == "pickups"
				and (
					not entry.get("item_id") is String
					or not DataCatalogGlobal.item(entry.item_id)
					or not number(entry.get("count"), 1, 99)
				)
			):
				return false
	if not data.get("known_recipes", []) is Array:
		return false
	for key in data.get("known_recipes", []):
		if not key is String or not DataCatalogGlobal.recipes.has(key):
			return false
	if not world.get("discovered", []) is Array:
		return false
	for region in world.get("discovered", []):
		if not region is String:
			return false
	return _quests(data.get("quests", {}))


static func _equipment(data: Dictionary) -> bool:
	var equipped: Variant = data.get("equipped", data)
	var durability: Variant = data.get("condition", {})
	if not equipped is Dictionary or not durability is Dictionary:
		return false
	for slot in equipped:
		if not equipped[slot] is String:
			return false
		var item := DataCatalogGlobal.item(equipped[slot])
		if not item or item.equipment_slot != slot:
			return false
	for key in durability:
		var item := DataCatalogGlobal.item(key)
		if not item or not number(durability[key], 0, item.durability):
			return false
	return true


static func _quests(data: Dictionary) -> bool:
	for key in ["states", "choices", "kills"]:
		if not data.get(key, {}) is Dictionary:
			return false
	var definitions: Dictionary = {}
	for quest: QuestDefinition in QuestSystemGlobal.QUESTS.entries:
		definitions[quest.quest_id] = quest
	for key in data.get("states", {}):
		if not definitions.has(key) or not data.states[key] in ["active", "complete", "failed"]:
			return false
	for key in data.get("choices", {}):
		if not definitions.has(key) or not data.choices[key] is String:
			return false
		var known := false
		for choice in definitions[key].choices:
			known = known or choice.id == data.choices[key]
		if not known:
			return false
	for key in data.get("kills", {}):
		if not DataCatalogGlobal.enemies.has(key) or not number(data.kills[key], 0, 1e6):
			return false
	var ending: Variant = data.get("ending", "")
	return (
		number(data.get("trust", 0), -10, 10)
		and data.get("recruited", false) is bool
		and ending is String
		and (ending.is_empty() or QuestSystemGlobal.DIALOGUE.endings.has(ending))
	)


static func _bounded(value: Variant, depth: int = 0) -> bool:
	if depth > 10:
		return false
	if value is Dictionary:
		if value.size() > 128:
			return false
		for key in value:
			if not key is String or key.length() > 128 or not _bounded(value[key], depth + 1):
				return false
	elif value is Array:
		if value.size() > 512:
			return false
		for entry in value:
			if not _bounded(entry, depth + 1):
				return false
	elif value is String:
		return value.length() <= 2048
	elif value is float:
		return is_finite(value)
	return true
