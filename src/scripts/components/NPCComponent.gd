# gdlint: disable=max-returns
# State/role dispatch keeps independent command paths explicit.
class_name NPCComponent
extends Node
## Behavior component for generic NPCs. Handles roles, orders, inventory, and AI.
## Replaces the hardcoded Companion logic with role-based behavior.

enum State { IDLE, FOLLOW, HOLD, GATHER, RETURN, ASSIST, WORK, PATROL }

const COMMANDS := ["follow", "hold", "gather", "return", "assist", "work", "patrol"]
const CARRY_SLOTS := 4
const CARRY_WEIGHT := 12.0
const FOLLOW_SPEED := 6.0
const FOLLOW_START := 3.5
const ARRIVAL_DISTANCE := 2.5
const GATHER_RANGE := 2.0
const TASK_SECONDS := 30.0
const STUCK_SECONDS := 5.0
const TRAVEL_SECONDS := 60.0
const DANGER_RANGE := 6.0
const ASSIST_RANGE := 3.0
const ASSIST_DAMAGE := 8.0
const ASSIST_SECONDS := 2.0

var npc_id: String = ""
var role: String = "none"
var command := "follow"
var state := State.IDLE
var inventory_comp: InventoryComponent
var _target_id := ""
var _task_remaining := 0.0
var _assist_timer := 0.0
var _loot_timer := 0.0
var _stuck_time := 0.0
var _travel_time := 0.0
var _progress_position := Vector3.ZERO
var _hold_position := Vector3.ZERO
var _patrol_position := Vector3.ZERO
var _illustration: IllustratedActor
var _owner: NPC

# Role-specific vars
var _farm_plot_target := ""
var _work_timer := 0.0
var _patrol_points: Array[Vector3] = []
var _patrol_index := 0


func _ready() -> void:
	inventory_comp = InventoryComponent.new()
	inventory_comp.max_slots = CARRY_SLOTS
	inventory_comp.max_weight = CARRY_WEIGHT
	add_child(inventory_comp)


func setup(identity: String, npc_owner: NPC) -> void:
	npc_id = identity
	_owner = npc_owner
	_hold_position = npc_owner.global_position
	_progress_position = npc_owner.global_position
	_patrol_position = npc_owner.global_position

	# Setup illustration
	_illustration = IllustratedActor.new()
	_illustration.art_key = CharacterRoster.get_npc_art_key(npc_id)
	npc_owner.add_child(_illustration)

	# Setup collision
	LowPoly.collision(npc_owner, Vector3(0.6, 1.8, 0.5), Vector3(0, 0.9, 0))
	LowPoly.label(npc_owner, npc_id.to_upper(), IllustratedArt.SCREEN_UP * 3.5, Color("f0d098"))

	# Load role from relationship system
	var assigned_role := RelationshipSystemGlobal.get_assigned_role(npc_id)
	if not assigned_role.is_empty() and assigned_role != "none":
		set_role(assigned_role)

	# Initialize patrol points for defender
	if role == "defender":
		_initialize_patrol_points()


func set_role(new_role: String) -> void:
	role = new_role
	command = _get_default_command_for_role(new_role)
	state = State.IDLE
	RelationshipSystemGlobal.set_assigned_role(npc_id, new_role)


func _get_default_command_for_role(role_name: String) -> String:
	match role_name:
		"gatherer":
			return "follow"
		"defender":
			return "patrol"
		"farmer":
			return "work"
		"survivor":
			return "follow"
		_:
			return "follow"


func issue_command(next: String, target: ResourceNode = null) -> bool:
	if not COMMANDS.has(next):
		return false
	if next == "gather" and not permitted_resource(target):
		return false
	if next == "work" and role != "farmer":
		return false
	if next == "patrol" and role != "defender":
		return false

	command = next
	state = State.IDLE
	_target_id = str(target.name) if next == "gather" else ""
	_task_remaining = TASK_SECONDS if next == "gather" else 0.0
	_hold_position = _owner.global_position
	_stuck_time = 0
	_travel_time = 0
	_progress_position = _owner.global_position
	return true


func permitted_resource(target: ResourceNode) -> bool:
	var player := GameManagerGlobal.get_player()
	return (
		is_instance_valid(target)
		and player != null
		and ResourceSystemGlobal.get_resource(str(target.name)) == target
		and target.can_interact()
		and target.required_tool.is_empty()
		and DataCatalogGlobal.item(target.item_id) != null
		and target.base_count > 0
		and (
			_owner.global_position.distance_to(target.global_position)
			<= RoleDefinition.get_config(RoleDefinition.NPCRole.GATHERER).task_radius
		)
		and (
			player.global_position.distance_to(target.global_position)
			<= RoleDefinition.get_config(RoleDefinition.NPCRole.GATHERER).task_radius
		)
	)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_owner):
		return

	var player := GameManagerGlobal.get_player()
	if not player or player.health_comp.is_dead():
		return

	# Update team-up time for bond progression
	if RelationshipSystemGlobal.is_teamed_up(npc_id):
		RelationshipSystemGlobal.add_team_up_time(npc_id, delta)

	_assist_timer = maxf(0, _assist_timer - delta)
	_loot_timer = maxf(0, _loot_timer - delta)
	_work_timer = maxf(0, _work_timer - delta)

	if command == "gather":
		_task_remaining = maxf(0, _task_remaining - delta)
		if _task_remaining == 0:
			issue_command("return")

	var danger := _nearby_danger(player)
	var direction := Vector3.ZERO

	if danger and _should_assist(danger):
		state = State.ASSIST
		if _owner.global_position.distance_to(danger.global_position) <= ASSIST_RANGE:
			if _assist_timer == 0 and _clear_path(danger.global_position):
				_assist_timer = ASSIST_SECONDS
				CombatSystemGlobal.apply_damage(_owner, danger, _get_assist_damage(), 0, 0)
				_illustration.play_action("attack")
		elif command != "hold" and command != "patrol":
			direction = _toward(danger.global_position, ASSIST_RANGE)
	else:
		direction = _execute_order(player)

	_move(direction, delta)


func _should_assist(danger: Enemy) -> bool:
	# Defenders only assist if danger is near base
	if role == "defender":
		var base_pos := _get_base_position()
		return (
			danger.global_position.distance_to(base_pos)
			<= RoleDefinition.get_config(RoleDefinition.NPCRole.DEFENDER).base_patrol_radius
		)
	# Gatherers and survivors assist if near player
	if role in ["gatherer", "survivor"]:
		var player := GameManagerGlobal.get_player()
		return (
			player
			and (
				danger.global_position.distance_to(player.global_position)
				<= RoleDefinition.get_config(RoleDefinition.NPCRole.GATHERER).task_radius
			)
		)
	return false


func _get_assist_damage() -> float:
	var config := RoleDefinition.get_config(_get_role_enum())
	return config.get("combat_assist_damage", 8.0)


func _get_role_enum() -> int:
	match role:
		"gatherer":
			return RoleDefinition.NPCRole.GATHERER
		"defender":
			return RoleDefinition.NPCRole.DEFENDER
		"farmer":
			return RoleDefinition.NPCRole.FARMER
		"survivor":
			return RoleDefinition.NPCRole.SURVIVOR
		_:
			return RoleDefinition.NPCRole.NONE


func _execute_order(player: Player) -> Vector3:
	match command:
		"hold":
			state = State.HOLD
			return _toward(_hold_position, 0.3)
		"gather":
			return _gather()
		"return":
			state = State.RETURN
			if _owner.global_position.distance_to(player.global_position) <= ARRIVAL_DISTANCE:
				transfer_carried(player)
				if inventory_comp.get_all_items().is_empty():
					issue_command("follow")
				return Vector3.ZERO
			return _toward(player.global_position, ARRIVAL_DISTANCE)
		"patrol":
			return _patrol()
		"work":
			return _work()
		"assist":
			state = State.ASSIST
			return _toward(player.global_position, ARRIVAL_DISTANCE)

	# Follow command
	if _loot_timer == 0:
		_loot_timer = 1.0
		for pickup: ItemPickup in get_tree().get_nodes_in_group("pickups"):
			if _owner.global_position.distance_to(pickup.global_position) <= GATHER_RANGE:
				if _clear_path(pickup.global_position):
					pickup.collect_into(inventory_comp)
		if _owner.global_position.distance_to(player.global_position) <= ARRIVAL_DISTANCE:
			transfer_carried(player)

	var distance := _owner.global_position.distance_to(player.global_position)
	var follow_dist: float = RoleDefinition.get_config(_get_role_enum()).get(
		"follow_distance", FOLLOW_START
	)
	if distance > follow_dist or (state == State.FOLLOW and distance > ARRIVAL_DISTANCE):
		state = State.FOLLOW
		return _toward(player.global_position, ARRIVAL_DISTANCE)

	state = State.IDLE
	return Vector3.ZERO


func _gather() -> Vector3:
	var target := ResourceSystemGlobal.get_resource(_target_id)
	if (
		not permitted_resource(target)
		or not inventory_comp.preview_exchange({}, {target.item_id: target.base_count}).success
	):
		issue_command("return")
		return Vector3.ZERO

	state = State.GATHER
	var gather_range: float = (
		RoleDefinition.get_config(RoleDefinition.NPCRole.GATHERER).follow_distance
	)
	if _owner.global_position.distance_to(target.global_position) <= gather_range:
		if _clear_path(target.global_position) and target.gather_into(inventory_comp):
			_illustration.play_action("gather", ResourceNode.GATHER_COOLDOWN)
			RelationshipSystemGlobal.add_bond(npc_id, 5, RelationshipSystemGlobal.BondSource.GATHER)
		return Vector3.ZERO
	return _toward(target.global_position, gather_range)


func _patrol() -> Vector3:
	state = State.PATROL
	var base_pos := _get_base_position()

	if _patrol_points.is_empty():
		_initialize_patrol_points()

	if _patrol_points.is_empty():
		return _toward(base_pos, 2.0)

	var target_point := _patrol_points[_patrol_index]
	if _owner.global_position.distance_to(target_point) <= 2.0:
		_patrol_index = (_patrol_index + 1) % _patrol_points.size()
		target_point = _patrol_points[_patrol_index]

	return _toward(target_point, 2.0)


func _initialize_patrol_points() -> void:
	var base_pos := _get_base_position()
	var radius: float = (
		RoleDefinition.get_config(RoleDefinition.NPCRole.DEFENDER).base_patrol_radius
	)
	_patrol_points.clear()
	for i in range(4):
		var angle := i * PI / 2
		var point := base_pos + Vector3(sin(angle), 0, cos(angle)) * radius * 0.7
		_patrol_points.append(point)


func _get_base_position() -> Vector3:
	# Base is near the shelter area around (2, 0, 35)
	var structures := get_tree().get_nodes_in_group("structures")
	for structure: Structure in structures:
		if structure.kind == "foundation":
			return structure.global_position
	return Vector3(2, 0, 35)


func _work() -> Vector3:
	state = State.WORK

	if role != "farmer":
		issue_command("follow")
		return Vector3.ZERO

	# Farmer work: prioritize harvest -> water -> plant -> till
	var plots := FarmingSystemGlobal.get_plots_in_range(_owner.global_position, 15.0)

	# 1. Harvest mature crops
	for plot_id in plots:
		var plot := FarmingSystemGlobal.get_plot(plot_id)
		if plot.state == "mature":
			_farm_plot_target = plot_id
			if _owner.global_position.distance_to(plot.position) <= 2.0:
				if _work_timer == 0:
					_work_timer = 2.0
					var harvest_count := FarmingSystemGlobal.harvest_plot(
						plot_id, BaseStorageGlobal.inventory
					)
					if harvest_count > 0:
						_illustration.play_action("gather", 2.0)
						RelationshipSystemGlobal.add_bond(
							npc_id, 10, RelationshipSystemGlobal.BondSource.CAMP_TASK
						)
			else:
				return _toward(plot.position, 2.0)
			return Vector3.ZERO

	# 2. Water crops that need water
	for plot_id in plots:
		var plot := FarmingSystemGlobal.get_plot(plot_id)
		if plot.state == "planted":
			_farm_plot_target = plot_id
			if _owner.global_position.distance_to(plot.position) <= 2.0:
				if _work_timer == 0:
					_work_timer = 1.5
					if FarmingSystemGlobal.water_plot(plot_id, BaseStorageGlobal.inventory):
						_illustration.play_action("craft", 1.5)
						RelationshipSystemGlobal.add_bond(
							npc_id, 5, RelationshipSystemGlobal.BondSource.CAMP_TASK
						)
			else:
				return _toward(plot.position, 2.0)
			return Vector3.ZERO

	# 3. Plant seeds in empty tilled plots
	for plot_id in plots:
		var plot := FarmingSystemGlobal.get_plot(plot_id)
		if plot.state == "tilled":
			# Try to plant from base storage
			var crop_ids := CropDefinition.get_all_crop_ids()
			for crop_id in crop_ids:
				var crop_def: Dictionary = CropDefinition.CROP_DEFINITIONS.get(crop_id, {})
				var seed_item: String = crop_def.get("seed_item_id", "")
				if BaseStorageGlobal.has_item(seed_item, 1):
					_farm_plot_target = plot_id
					if _owner.global_position.distance_to(plot.position) <= 2.0:
						if _work_timer == 0:
							_work_timer = 2.0
							if FarmingSystemGlobal.plant_crop(
								plot_id, crop_id, BaseStorageGlobal.inventory
							):
								_illustration.play_action("build", 2.0)
								RelationshipSystemGlobal.add_bond(
									npc_id, 8, RelationshipSystemGlobal.BondSource.CAMP_TASK
								)
					else:
						return _toward(plot.position, 2.0)
					return Vector3.ZERO

	# 4. Till empty plots if tools available
	for plot_id in plots:
		var plot := FarmingSystemGlobal.get_plot(plot_id)
		if plot.state == "empty" and BaseStorageGlobal.has_item("hoe", 1):
			_farm_plot_target = plot_id
			if _owner.global_position.distance_to(plot.position) <= 2.0:
				if _work_timer == 0:
					_work_timer = 3.0
					if FarmingSystemGlobal.till_plot(plot_id):
						_illustration.play_action("build", 3.0)
						RelationshipSystemGlobal.add_bond(
							npc_id, 5, RelationshipSystemGlobal.BondSource.CAMP_TASK
						)
			else:
				return _toward(plot.position, 2.0)
			return Vector3.ZERO

	# No work available, return to base
	return _toward(_get_base_position(), 2.0)


func transfer_carried(player: Player) -> int:
	if not player or _owner.global_position.distance_to(player.global_position) > ARRIVAL_DISTANCE:
		return 0
	var transferred := 0
	for key in inventory_comp.get_all_items():
		for index in inventory_comp.get_count(key):
			if not inventory_comp.transfer_to(player.inventory_comp, key, 1):
				break
			transferred += 1
	return transferred


func _nearby_danger(player: Player) -> Enemy:
	var closest: Enemy
	var distance := DANGER_RANGE
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		var next := _owner.global_position.distance_to(enemy.global_position)
		if not enemy.health_comp.is_dead() and next < distance:
			if (
				player.global_position.distance_to(enemy.global_position)
				<= RoleDefinition.get_config(_get_role_enum()).get("task_radius", DANGER_RANGE)
			):
				closest = enemy
				distance = next
	return closest


func _clear_path(at: Vector3) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(
		_owner.global_position + Vector3.UP, at + Vector3.UP, 16
	)
	return _owner.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()


func _toward(at: Vector3, stop: float) -> Vector3:
	var offset := at - _owner.global_position
	offset.y = 0
	if offset.length() <= stop:
		return Vector3.ZERO
	var direction := offset.normalized()
	for angle in [0.0, PI / 4, -PI / 4, PI / 2, -PI / 2]:
		var candidate := direction.rotated(Vector3.UP, angle)
		if _clear_path(_owner.global_position + candidate * 1.5):
			return candidate
	return direction


func _move(direction: Vector3, delta: float) -> void:
	_travel_time = 0.0 if direction == Vector3.ZERO else _travel_time + delta
	_illustration.animate_movement(direction)
	_owner.velocity = Vector3(
		direction.x * FOLLOW_SPEED,
		-1 if _owner.is_on_floor() else _owner.velocity.y - 20 * delta,
		direction.z * FOLLOW_SPEED
	)
	_owner.move_and_slide()
	if direction == Vector3.ZERO or _owner.global_position.distance_to(_progress_position) > 0.5:
		_stuck_time = 0
		_progress_position = _owner.global_position
	else:
		_stuck_time += delta
	if _stuck_time >= STUCK_SECONDS or _travel_time >= TRAVEL_SECONDS:
		issue_command("hold")
		GameManagerGlobal.message_posted.emit(
			"%s: My path is blocked. I'll hold here." % _owner.name
		)


func serialize() -> Dictionary:
	return {
		"npc_id": npc_id,
		"role": role,
		"command": command,
		"position": StateValidation.array3(_owner.global_position),
		"hold_position": StateValidation.array3(_hold_position),
		"patrol_position": StateValidation.array3(_patrol_position),
		"inventory": inventory_comp.serialize(),
		"target_id": _target_id,
		"task_remaining": _task_remaining,
		"assist_timer": _assist_timer,
		"farm_plot_target": _farm_plot_target,
		"patrol_index": _patrol_index
	}


func deserialize(data: Dictionary) -> bool:
	npc_id = data.get("npc_id", "")
	role = data.get("role", "none")
	command = data.get("command", "follow")
	_owner.global_position = StateValidation.vec3(data.get("position", [0, 0, 0]))
	_hold_position = StateValidation.vec3(data.get("hold_position", [0, 0, 0]))
	_patrol_position = StateValidation.vec3(data.get("patrol_position", [0, 0, 0]))
	inventory_comp.deserialize(data.get("inventory", {}))
	_target_id = data.get("target_id", "")
	_task_remaining = float(data.get("task_remaining", 0.0))
	_assist_timer = float(data.get("assist_timer", 0.0))
	_farm_plot_target = data.get("farm_plot_target", "")
	_patrol_index = data.get("patrol_index", 0)
	state = State.IDLE
	_owner.velocity = Vector3.ZERO
	_progress_position = _owner.global_position
	_stuck_time = 0
	_travel_time = 0
	return true


func can_interact() -> bool:
	return true


func get_interaction_text() -> String:
	var bond_level := RelationshipSystemGlobal.get_bond_level(npc_id)
	var role_text := role.capitalize() if not role.is_empty() else "No role"
	return "Talk / Configure %s (Bond Lv.%d)" % [role_text, bond_level]


func interact(_player: Player) -> void:
	GameManagerGlobal.open_npc_dialogue(npc_id)


func get_status_text() -> String:
	match command:
		"follow":
			return (
				"Following %s"
				% CharacterRoster.display_name(PartySystemGlobal.get_controlled_character_id())
			)
		"hold":
			return "Holding position"
		"gather":
			return "Gathering %s" % (_target_id if not _target_id.is_empty() else "resources")
		"return":
			return "Returning with supplies"
		"patrol":
			return "Patrolling base"
		"work":
			return (
				"Farming: %s" % (_farm_plot_target if not _farm_plot_target.is_empty() else "idle")
			)
		"assist":
			return "Assisting in combat"
		_:
			return "Idle"
