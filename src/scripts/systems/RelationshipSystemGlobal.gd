extends Node
## Persistent per-NPC relationship/bond system. Replaces Mara-specific trust.
## Each NPC has independent bond points, level, and progression.

signal relationship_changed(npc_id: String)
signal bond_level_reached(npc_id: String, new_level: int)
signal daily_bond_capped(npc_id: String, source: String)

enum BondSource { TRAVEL, GATHER, COMBAT, DISCOVERY, QUEST, CAMP_TASK, DIALOGUE }

const RELATIONSHIP_DEFINITION = preload("res://resources/definitions/RelationshipDefinition.tres")
const NPC_SCRIPT = preload("res://scripts/entities/NPC.gd")

var relationships: Dictionary = {}
var _current_day: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_lifecycle.call_deferred()


func _connect_lifecycle() -> void:
	GameManagerGlobal.game_ready.connect(_on_game_ready)
	GameManagerGlobal.menu_requested.connect(_on_menu_requested)
	QuestSystemGlobal.quests_changed.connect(_on_quest_completed)


func _on_game_ready() -> void:
	_initialize_relationships()
	_connect_day_signal()


func _connect_day_signal() -> void:
	var world := GameManagerGlobal.world
	if is_instance_valid(world) and not world.day_changed.is_connected(_on_day_changed):
		world.day_changed.connect(_on_day_changed)


func _initialize_relationships() -> void:
	for npc_data in CharacterRoster.get_all_npcs():
		var npc_id: String = npc_data.npc_id
		if not relationships.has(npc_id):
			var starting_bond: int = npc_data.starting_bond
			relationships[npc_id] = {
				"npc_id": npc_id,
				"bond_points": starting_bond,
				"bond_level": _calculate_bond_level(starting_bond),
				"status": _calculate_status(starting_bond),
				"last_interaction_day": 0,
				"daily_bond_gained": {},
				"team_up_time": 0.0,
				"shared_activities": [],
				"is_teamed_up": false,
				"assigned_role": npc_data.default_role
			}
	relationship_changed.emit("all")


func _calculate_bond_level(bond_points: int) -> int:
	return RELATIONSHIP_DEFINITION.get_bond_level(bond_points)


func _calculate_status(bond_points: int) -> String:
	var level := _calculate_bond_level(bond_points)
	return RELATIONSHIP_DEFINITION.get_status(level)


func _on_menu_requested(menu: String) -> void:
	if menu == "main":
		_initialize_relationships()


func _on_day_changed(new_day: int) -> void:
	_current_day = new_day
	for npc_id in relationships:
		relationships[npc_id].daily_bond_gained.clear()


func _on_quest_completed() -> void:
	var player := GameManagerGlobal.get_player()
	if not player:
		return
	var companion := _get_active_companion()
	if companion:
		add_bond(
			companion.npc_comp.npc_id,
			RELATIONSHIP_DEFINITION.get_daily_cap("quest"),
			BondSource.QUEST
		)


func _get_active_companion() -> NPC:
	var world := GameManagerGlobal.world
	if is_instance_valid(world):
		# Get the first NPC that is teamed up
		for npc_id in PartySystemGlobal.get_party_members():
			if npc_id != PartySystemGlobal.get_controlled_character_id():
				var npc := world.get_node_or_null(npc_id)
				if npc and npc is NPC_SCRIPT:
					return npc
	return null


func get_relationship(npc_id: String) -> Dictionary:
	if not relationships.has(npc_id):
		return {}
	return relationships[npc_id].duplicate(true)


func get_bond_points(npc_id: String) -> int:
	return relationships.get(npc_id, {}).get("bond_points", 0)


func get_bond_level(npc_id: String) -> int:
	return relationships.get(npc_id, {}).get("bond_level", 0)


func get_progress_to_next(npc_id: String) -> float:
	var bond := get_bond_points(npc_id)
	return RELATIONSHIP_DEFINITION.get_progress_to_next(bond)


func get_status(npc_id: String) -> String:
	return relationships.get(npc_id, {}).get("status", "Neutral")


func is_teamed_up(npc_id: String) -> bool:
	return relationships.get(npc_id, {}).get("is_teamed_up", false)


func get_assigned_role(npc_id: String) -> String:
	return relationships.get(npc_id, {}).get("assigned_role", "none")


func set_assigned_role(npc_id: String, role: String) -> void:
	if not relationships.has(npc_id):
		return
	relationships[npc_id].assigned_role = role
	relationship_changed.emit(npc_id)


func set_teamed_up(npc_id: String, teamed_up: bool) -> void:
	if not relationships.has(npc_id):
		return
	relationships[npc_id].is_teamed_up = teamed_up
	if teamed_up:
		relationships[npc_id].team_up_time = 0.0
	relationship_changed.emit(npc_id)


func add_team_up_time(npc_id: String, delta: float) -> void:
	if not relationships.has(npc_id):
		return
	if relationships[npc_id].is_teamed_up:
		relationships[npc_id].team_up_time += delta
		# Award bond for team-up time (1 bond per minute of team-up, capped daily)
		var minutes: float = relationships[npc_id].team_up_time / 60.0
		if minutes >= 1.0:
			var bond_gain := int(minutes)
			relationships[npc_id].team_up_time -= bond_gain * 60.0
			add_bond(npc_id, bond_gain, BondSource.TRAVEL)


func add_bond(npc_id: String, amount: int, source: BondSource) -> bool:
	if not relationships.has(npc_id) or amount <= 0:
		return false

	var rel: Dictionary = relationships[npc_id]
	var source_name: String = BondSource.keys()[source].to_lower()
	var daily_cap := RELATIONSHIP_DEFINITION.get_daily_cap(source_name)
	var already_gained: int = rel.daily_bond_gained.get(source_name, 0)

	if already_gained >= daily_cap:
		daily_bond_capped.emit(npc_id, source_name)
		return false

	var actual_gain := mini(amount, daily_cap - already_gained)
	rel.bond_points += actual_gain
	rel.daily_bond_gained[source_name] = already_gained + actual_gain

	var old_level: int = rel.bond_level
	rel.bond_level = _calculate_bond_level(rel.bond_points)
	rel.status = _calculate_status(rel.bond_points)

	if rel.bond_level > old_level:
		bond_level_reached.emit(npc_id, rel.bond_level)
		# Award trust bonus from relationship definition
		var trust_bonus := 0
		if rel.bond_level == 2:
			trust_bonus = 1
		elif rel.bond_level == 3:
			trust_bonus = 1
		elif rel.bond_level == 4:
			trust_bonus = 2
		elif rel.bond_level == 5:
			trust_bonus = 3
		if trust_bonus > 0:
			QuestSystemGlobal.trust = clampi(QuestSystemGlobal.trust + trust_bonus, -10, 10)

	relationship_changed.emit(npc_id)
	return true


func add_shared_activity(npc_id: String, activity: String) -> void:
	if not relationships.has(npc_id):
		return
	var rel: Dictionary = relationships[npc_id]
	if not activity in rel.shared_activities:
		rel.shared_activities.append(activity)


func can_switch_character(npc_id: String) -> bool:
	if not relationships.has(npc_id):
		return false
	return RELATIONSHIP_DEFINITION.can_switch_character(relationships[npc_id].bond_level)


func serialize() -> Dictionary:
	var data: Dictionary = {}
	for npc_id in relationships:
		var rel: Dictionary = relationships[npc_id]
		data[npc_id] = {
			"bond_points": rel.bond_points,
			"bond_level": rel.bond_level,
			"status": rel.status,
			"last_interaction_day": rel.last_interaction_day,
			"daily_bond_gained": rel.daily_bond_gained.duplicate(),
			"team_up_time": rel.team_up_time,
			"shared_activities": rel.shared_activities.duplicate(),
			"is_teamed_up": rel.is_teamed_up,
			"assigned_role": rel.assigned_role
		}
	return data


func deserialize(data: Dictionary) -> void:
	relationships.clear()
	for npc_id in data:
		var rel_data: Dictionary = data[npc_id]
		relationships[npc_id] = {
			"npc_id": npc_id,
			"bond_points": rel_data.get("bond_points", 0),
			"bond_level": rel_data.get("bond_level", 0),
			"status": rel_data.get("status", "Neutral"),
			"last_interaction_day": rel_data.get("last_interaction_day", 0),
			"daily_bond_gained": rel_data.get("daily_bond_gained", {}),
			"team_up_time": float(rel_data.get("team_up_time", 0.0)),
			"shared_activities": rel_data.get("shared_activities", []),
			"is_teamed_up": rel_data.get("is_teamed_up", false),
			"assigned_role": rel_data.get("assigned_role", "none")
		}
	# Ensure all NPCs have entries
	for npc_data in CharacterRoster.get_all_npcs():
		if not relationships.has(npc_data.npc_id):
			var starting_bond: int = npc_data.starting_bond
			relationships[npc_data.npc_id] = {
				"npc_id": npc_data.npc_id,
				"bond_points": starting_bond,
				"bond_level": _calculate_bond_level(starting_bond),
				"status": _calculate_status(starting_bond),
				"last_interaction_day": 0,
				"daily_bond_gained": {},
				"team_up_time": 0.0,
				"shared_activities": [],
				"is_teamed_up": false,
				"assigned_role": npc_data.default_role
			}


func migrate_from_legacy(trust: int, recruited: bool) -> void:
	# Mara's trust (0-10) maps to bond points: trust * 50
	# trust 0-1 -> level 0-1, trust 2 -> level 2, trust 3 -> level 3
	if relationships.has("mara"):
		var bond_points := trust * 50
		relationships["mara"].bond_points = bond_points
		relationships["mara"].bond_level = _calculate_bond_level(bond_points)
		relationships["mara"].status = _calculate_status(bond_points)
		relationships["mara"].is_teamed_up = recruited
		if recruited:
			relationships["mara"].assigned_role = "gatherer"
		relationship_changed.emit("mara")
