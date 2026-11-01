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
	controlled_character_id = "dave"
	party_members = ["dave"]
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
	if not CharacterRoster.is_playable_npc(npc_id):
		return false
	if not RelationshipSystemGlobal.can_switch_character(npc_id):
		return false
	if npc_id == controlled_character_id:
		return false
	return true


func switch_character(target_npc_id: String) -> bool:
	if not can_switch_to(target_npc_id):
		return false

	var world := GameManagerGlobal.world
	var player_node := GameManagerGlobal.get_player()
	if not is_instance_valid(world) or not player_node:
		return false

	var old_character_id := controlled_character_id

	# Get the target NPC node
	var target_npc := world.get_node_or_null(target_npc_id) as NPC
	if not target_npc or not (target_npc is NPC_SCRIPT):
		return false

	# Store old player state
	var old_player_data := player_node.serialize()
	old_player_data["character_id"] = old_character_id

	# Get target NPC data
	var target_npc_data := target_npc.serialize()
	target_npc_data["character_id"] = target_npc_id

	# Swap the characters
	# 1. Convert old player to NPC
	var old_npc := _convert_player_to_npc(player_node, old_character_id, old_player_data)
	if not old_npc:
		return false

	# 2. Convert target NPC to player
	var new_player := _convert_npc_to_player(target_npc, target_npc_id, target_npc_data)
	if not new_player:
		# Rollback
		_convert_npc_to_player(old_npc, old_character_id, old_player_data)
		return false

	# Update party
	party_members.erase(target_npc_id)
	if not old_character_id in party_members:
		party_members.append(old_character_id)

	controlled_character_id = target_npc_id

	# Update NPC entity references
	npc_entities[old_character_id] = old_npc
	npc_entities.erase(target_npc_id)

	# Update relationship system
	RelationshipSystemGlobal.set_teamed_up(old_character_id, true)
	RelationshipSystemGlobal.set_teamed_up(target_npc_id, false)

	character_switched.emit(old_character_id, target_npc_id)
	party_changed.emit()

	return true


func _convert_player_to_npc(player: Player, npc_id: String, player_data: Dictionary) -> NPC:
	var world := GameManagerGlobal.world
	if not is_instance_valid(world):
		return null

	# Create NPC at player position
	var npc_scene := load("res://scenes/NPC.tscn") as PackedScene
	var npc := npc_scene.instantiate() as NPC
	npc.name = npc_id
	npc.global_position = player.global_position
	npc.deserialize(player_data)

	# Set NPC role from relationship system
	var role := RelationshipSystemGlobal.get_assigned_role(npc_id)
	npc.set_role(role)

	# Add to world
	world.add_child(npc)

	# Remove old player
	player.queue_free()

	return npc


func _convert_npc_to_player(npc, character_id: String, npc_data: Dictionary) -> Player:
	var world := GameManagerGlobal.world
	if not is_instance_valid(world):
		return null

	# Create player at NPC position
	var player_scene := load("res://scenes/Player.tscn") as PackedScene
	var player := player_scene.instantiate() as Player
	player.name = "Player"
	player.global_position = npc.global_position
	player.deserialize(npc_data)
	player.set_character_id(character_id)

	# Add to world
	world.add_child(player)

	# Remove NPC
	npc.queue_free()

	return player


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
