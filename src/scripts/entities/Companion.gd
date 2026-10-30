class_name Companion
extends CharacterBody3D
## Orders survive combat; resource and inventory systems own all rewards.

enum State { IDLE, FOLLOW, HOLD, GATHER, RETURN, ASSIST }

const COMMANDS := ["follow", "hold", "gather", "return", "assist"]
const CARRY_SLOTS := 4
const CARRY_WEIGHT := 12.0
const FOLLOW_SPEED := 6.0
const FOLLOW_START := 3.5
const ARRIVAL_DISTANCE := 2.5
const GATHER_RANGE := 2.0
const TASK_RADIUS := 12.0
const TASK_SECONDS := 30.0
const STUCK_SECONDS := 5.0
const TRAVEL_SECONDS := 60.0
const DANGER_RANGE := 6.0
const ASSIST_RANGE := 3.0
const ASSIST_DAMAGE := 8.0
const ASSIST_SECONDS := 2.0

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
var _illustration: IllustratedActor


func _ready() -> void:
	add_to_group("interactables")
	_hold_position = global_position
	_progress_position = global_position
	collision_layer = 4
	collision_mask = 24
	inventory_comp = InventoryComponent.new()
	inventory_comp.max_slots = CARRY_SLOTS
	inventory_comp.max_weight = CARRY_WEIGHT
	add_child(inventory_comp)
	_illustration = IllustratedActor.new()
	_illustration.art_key = "mara"
	add_child(_illustration)
	LowPoly.collision(self, Vector3(0.6, 1.8, 0.5), Vector3(0, 0.9, 0))
	LowPoly.label(self, "MARA", IllustratedArt.SCREEN_UP * 3.5, Color("f0d098"))


func issue_command(next: String, target: ResourceNode = null) -> bool:
	if not QuestSystemGlobal.recruited or not next in COMMANDS:
		return false
	if next == "gather" and not permitted_resource(target):
		return false
	command = next
	state = State.IDLE
	_target_id = str(target.name) if next == "gather" else ""
	_task_remaining = TASK_SECONDS if next == "gather" else 0.0
	_hold_position = global_position
	_stuck_time = 0
	_travel_time = 0
	_progress_position = global_position
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
		and global_position.distance_to(target.global_position) <= TASK_RADIUS
		and player.global_position.distance_to(target.global_position) <= TASK_RADIUS
	)


func _physics_process(delta: float) -> void:
	var player := GameManagerGlobal.get_player()
	if not player or not QuestSystemGlobal.recruited or player.health_comp.is_dead():
		return
	_assist_timer = maxf(0, _assist_timer - delta)
	_loot_timer = maxf(0, _loot_timer - delta)
	if command == "gather":
		_task_remaining = maxf(0, _task_remaining - delta)
		if _task_remaining == 0:
			issue_command("return")
	var danger := _nearby_danger(player)
	var direction := Vector3.ZERO
	if danger:
		state = State.ASSIST
		if global_position.distance_to(danger.global_position) <= ASSIST_RANGE:
			if _assist_timer == 0 and _clear_path(danger.global_position):
				_assist_timer = ASSIST_SECONDS
				CombatSystemGlobal.apply_damage(self, danger, ASSIST_DAMAGE, 0, 0)
				_illustration.play_action("attack")
		elif command != "hold":
			direction = _toward(danger.global_position, ASSIST_RANGE)
	else:
		direction = _execute_order(player)
	_move(direction, delta)


func _execute_order(player: Player) -> Vector3:
	match command:
		"hold":
			state = State.HOLD
			return _toward(_hold_position, 0.3)
		"gather":
			return _gather()
		"return":
			state = State.RETURN
			if global_position.distance_to(player.global_position) <= ARRIVAL_DISTANCE:
				transfer_carried(player)
				if inventory_comp.get_all_items().is_empty():
					issue_command("follow")
				return Vector3.ZERO
			return _toward(player.global_position, ARRIVAL_DISTANCE)
	# Follow and combat-assist both escort the player outside combat.
	if _loot_timer == 0:
		_loot_timer = 1.0
		for pickup: ItemPickup in get_tree().get_nodes_in_group("pickups"):
			if global_position.distance_to(pickup.global_position) <= GATHER_RANGE:
				if _clear_path(pickup.global_position):
					pickup.collect_into(inventory_comp)
		if global_position.distance_to(player.global_position) <= ARRIVAL_DISTANCE:
			transfer_carried(player)
	var distance := global_position.distance_to(player.global_position)
	if distance > FOLLOW_START or (state == State.FOLLOW and distance > ARRIVAL_DISTANCE):
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
	if global_position.distance_to(target.global_position) <= GATHER_RANGE:
		if _clear_path(target.global_position) and target.gather_into(inventory_comp):
			_illustration.play_action("gather", ResourceNode.GATHER_COOLDOWN)
		return Vector3.ZERO
	return _toward(target.global_position, GATHER_RANGE)


func transfer_carried(player: Player) -> int:
	if not player or global_position.distance_to(player.global_position) > ARRIVAL_DISTANCE:
		return 0
	var transferred := 0
	for key in inventory_comp.get_all_items():
		# Carry weight and slots bound this loop; partial stacks remain owned by Mara.
		for index in inventory_comp.get_count(key):
			if not inventory_comp.transfer_to(player.inventory_comp, key, 1):
				break
			transferred += 1
	return transferred


func _nearby_danger(player: Player) -> Enemy:
	var closest: Enemy
	var distance := DANGER_RANGE
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		var next := global_position.distance_to(enemy.global_position)
		if not enemy.health_comp.is_dead() and next < distance:
			if player.global_position.distance_to(enemy.global_position) <= TASK_RADIUS:
				closest = enemy
				distance = next
	return closest


func _clear_path(at: Vector3) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, at + Vector3.UP, 16)
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()


func _toward(at: Vector3, stop: float) -> Vector3:
	var offset := at - global_position
	offset.y = 0
	if offset.length() <= stop:
		return Vector3.ZERO
	var direction := offset.normalized()
	# Local obstacle steering; a bounded progress watchdog cancels unreachable orders.
	for angle in [0.0, PI / 4, -PI / 4, PI / 2, -PI / 2]:
		var candidate := direction.rotated(Vector3.UP, angle)
		if _clear_path(global_position + candidate * 1.5):
			return candidate
	return direction


func _move(direction: Vector3, delta: float) -> void:
	_travel_time = 0.0 if direction == Vector3.ZERO else _travel_time + delta
	_illustration.animate_movement(direction)
	velocity = Vector3(
		direction.x * FOLLOW_SPEED,
		-1 if is_on_floor() else velocity.y - 20 * delta,
		direction.z * FOLLOW_SPEED
	)
	move_and_slide()
	if direction == Vector3.ZERO or global_position.distance_to(_progress_position) > 0.5:
		_stuck_time = 0
		_progress_position = global_position
	else:
		_stuck_time += delta
	if _stuck_time >= STUCK_SECONDS or _travel_time >= TRAVEL_SECONDS:
		issue_command("hold")
		GameManagerGlobal.message_posted.emit(
			"Mara: My path is blocked. I'll hold here with the supplies."
		)


func serialize() -> Dictionary:
	return {
		"command": command,
		"position": StateValidation.array3(global_position),
		"hold_position": StateValidation.array3(_hold_position),
		"inventory": inventory_comp.serialize(),
		"target_id": _target_id,
		"task_remaining": _task_remaining,
		"assist_timer": _assist_timer
	}


func deserialize(data: Dictionary) -> bool:
	if not StateValidation.companion(data):
		return false
	if data.is_empty():
		return true
	inventory_comp.deserialize(data.inventory)
	command = data.command
	global_position = StateValidation.vec3(data.position)
	_hold_position = StateValidation.vec3(data.hold_position)
	_target_id = data.target_id
	_task_remaining = float(data.task_remaining)
	_assist_timer = float(data.assist_timer)
	state = State.IDLE
	velocity = Vector3.ZERO
	_progress_position = global_position
	_stuck_time = 0
	return true


func can_interact() -> bool:
	return true


func get_interaction_text() -> String:
	return "Talk / command Mara"


func interact(_player: Player) -> void:
	GameManagerGlobal.open_menu("dialogue")
