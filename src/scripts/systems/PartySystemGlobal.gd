extends Node
## Party/roster management and character switching system.
## Controls which character the player currently controls and NPC party membership.

signal party_changed
signal character_switched(old_character_id: String, new_character_id: String)
signal npc_joined_party(npc_id: String)
signal npc_left_party(npc_id: String)

const NPC_SCRIPT = preload("res://scripts/entities/NPC.gd")

var controlled_character_id: String = "dave"
var party_members: Array[String] = ["dave"]  # Character IDs currently in party
var npc_entities: Dictionary = {}  # npc_id -> NPC node reference
var _pending_switch: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_lifecycle.call_deferred()


func _connect_lifecycle() -> void:
	GameManagerGlobal.game_ready.connect(_on_game_ready)
	RelationshipSystemGlobal.relationship_changed.connect(_on_relationship_changed)


func _on_game_ready() -> void:
	_initialize_party()


func _initialize_party() -> void:
	var player := GameManagerGlobal.get_player()
	controlled_character_id = player.character_id if player else "dave"
	party_members = [controlled_character_id]
	_pending_switch = ""
	party_changed.emit()


func _on_relationship_changed(npc_id: String) -> void:
	# Auto-update party when relationships change (e.g., recruitment)
	if npc_id == "all" or npc_id == "mara":
		var mara_rel := RelationshipSystemGlobal.get_relationship("mara")
		if mara_rel.get("is_teamed_up", false) and not "mara" in party_members:
			party_members.append("mara")
			npc_joined_party.emit("mara")
			party_changed.emit()
		elif not mara_rel.get("is_teamed_up", false) and "mara" in party_members:
			party_members.erase("mara")
			npc_left_party.emit("mara")
			party_changed.emit()


func get_controlled_character_id() -> String:
	return controlled_character_id


func get_party_members() -> Array[String]:
	return party_members.duplicate()


func is_in_party(character_id: String) -> bool:
	return character_id in party_members


func get_npc_entity(npc_id: String):
	return npc_entities.get(npc_id)


func register_npc_entity(npc_id: String, npc_node) -> void:
	npc_entities[npc_id] = npc_node


func unregister_npc_entity(npc_id: String) -> void:
	npc_entities.erase(npc_id)


func can_switch_to(npc_id: String) -> bool:
	var identity := npc_id.strip_edges().to_lower()
	var player := GameManagerGlobal.get_player()
	return (
		(identity in CharacterRoster.PROFILES or identity in ["dave_npc", "marie_npc"])
		and player != null
		and not GameManagerGlobal.is_loading
		and not player.health_comp.is_dead()
		and QuestSystemGlobal.ending.is_empty()
		and CharacterRoster.normalize_id(identity) != player.character_id
	)


func switch_character(target_npc_id: String) -> bool:
	if not can_switch_to(target_npc_id):
		return false
	var world := GameManagerGlobal.world as IslandWorld
	var player_node := GameManagerGlobal.get_player()
	var target_id := CharacterRoster.normalize_id(target_npc_id)
	var target_npc := world.get_node_or_null(CharacterRoster.playable_npc_id(target_id)) as NPC
	if not target_npc or target_npc.health_comp.is_dead():
		return false
	var old_character_id := player_node.character_id
	var old_player_data := player_node.serialize()
	var target_data := target_npc.player_state.duplicate(true)
	if target_data.is_empty():
		target_data = {
			"health": target_npc.health_comp.current_health,
			"stamina": 100,
			"hunger": 100,
			"thirst": 100,
			"inventory": {},
			"equipment": {},
			"experience": 0
		}
	target_data["character_id"] = target_id
	target_data["position"] = StateValidation.array3(target_npc.global_position)
	# Validate and combine NPC carry before mutating either character's ownership.
	var inventory := InventoryComponent.new()
	var valid := inventory.deserialize(target_data.get("inventory", {}))
	valid = valid and inventory.exchange({}, target_npc.npc_comp.inventory_comp.serialize())
	target_data["inventory"] = inventory.serialize()
	inventory.free()
	if not valid or not StateValidation.state({"player": target_data, "world": {}}):
		return false
	var old_npc := world.spawn_npc(
		CharacterRoster.playable_npc_id(old_character_id), player_node.global_position
	)
	old_npc.player_state = old_player_data
	old_npc.health_comp.deserialize({"current_health": old_player_data.health})
	world.remove_npc(str(target_npc.name))
	# The live Player and its component signals remain bound; only owned state swaps.
	player_node.deserialize(target_data)
	_initialize_party()
	character_switched.emit(old_character_id, target_id)
	return true


func add_to_party(npc_id: String) -> bool:
	if not CharacterRoster.has_npc(npc_id):
		return false
	if npc_id in party_members:
		return true
	party_members.append(npc_id)
	npc_joined_party.emit(npc_id)
	party_changed.emit()
	return true


func remove_from_party(npc_id: String) -> bool:
	if npc_id == "dave":  # Dave can't be removed
		return false
	if not npc_id in party_members:
		return true
	party_members.erase(npc_id)
	npc_left_party.emit(npc_id)
	party_changed.emit()
	return true


func get_available_switch_targets() -> Array[String]:
	var targets: Array[String] = []
	for npc_id in party_members:
		if can_switch_to(npc_id):
			targets.append(npc_id)
	return targets


func serialize() -> Dictionary:
	return {
		"controlled_character_id": controlled_character_id,
		"party_members": party_members.duplicate()
	}


func deserialize(data: Dictionary) -> void:
	controlled_character_id = data.get("controlled_character_id", "dave")
	party_members.assign(data.get("party_members", ["dave"]))
	# Ensure dave is always in party
	if not "dave" in party_members:
		party_members.insert(0, "dave")
	party_changed.emit()
