extends CharacterBody3D
class_name Enemy

signal health_changed(current: float, max: float)
signal died
signal state_changed(new_state: String)
signal detected_player(player: Node)

enum AIState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	FLEE,
	DEAD
}

@export var enemy_definition: EnemyDefinition
@export var patrol_points: Array[Vector3] = []

@onready var health_comp: HealthComponent = $HealthComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _state: AIState = AIState.IDLE
var _target: Node = null
var _patrol_index: int = 0
var _attack_timer: float = 0.0
var _state_timer: float = 0.0
var _home_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	if enemy_definition:
		health_comp.max_health = enemy_definition.max_health
		health_comp.current_health = enemy_definition.max_health

	health_comp.health_changed.connect(_on_health_changed)
	health_comp.died.connect(_on_died)

	_home_position = global_position
	_state = AIState.IDLE
	state_changed.emit("idle")

	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if health_comp.is_dead():
		return

	_attack_timer = max(0.0, _attack_timer - delta)
	_state_timer -= delta

	_update_ai(delta)
	_handle_movement(delta)

func _update_ai(delta: float) -> void:
	if not enemy_definition:
		return

	var player = _find_player()
	var distance_to_player = player.global_position.distance_to(global_position) if player else INF

	match _state:
		AIState.IDLE:
			if player and distance_to_player <= enemy_definition.detection_range:
				_state = AIState.CHASE
				_target = player
				state_changed.emit("chase")
				detected_player.emit(player)
			elif _state_timer <= 0.0:
				_state = AIState.PATROL
				state_changed.emit("patrol")
				_state_timer = randf_range(3.0, 8.0)

		AIState.PATROL:
			if player and distance_to_player <= enemy_definition.detection_range:
				_state = AIState.CHASE
				_target = player
				state_changed.emit("chase")
				detected_player.emit(player)
			elif _state_timer <= 0.0:
				_state = AIState.IDLE
				state_changed.emit("idle")
				_state_timer = randf_range(2.0, 5.0)

		AIState.CHASE:
			if not player or distance_to_player > enemy_definition.detection_range * 1.5:
				_state = AIState.IDLE
				_target = null
				state_changed.emit("idle")
				_state_timer = randf_range(2.0, 5.0)
			elif distance_to_player <= enemy_definition.attack_range:
				_state = AIState.ATTACK
				state_changed.emit("attack")

		AIState.ATTACK:
			if not player or distance_to_player > enemy_definition.attack_range * 1.2:
				_state = AIState.CHASE
				state_changed.emit("chase")
			elif _attack_timer <= 0.0:
				_attack()
				_attack_timer = enemy_definition.attack_cooldown

		AIState.FLEE:
			if distance_to_player > enemy_definition.detection_range:
				_state = AIState.IDLE
				state_changed.emit("idle")
				_state_timer = randf_range(2.0, 5.0)

func _handle_movement(delta: float) -> void:
	var move_dir = Vector3.ZERO
	var speed = enemy_definition.move_speed if enemy_definition else 3.0

	match _state:
		AIState.PATROL:
			if patrol_points.size() > 0:
				var target_point = patrol_points[_patrol_index]
				move_dir = (target_point - global_position).normalized()
				move_dir.y = 0

				if global_position.distance_to(target_point) < 1.0:
					_patrol_index = (_patrol_index + 1) % patrol_points.size()
			else:
				# Random wander
				var wander_target = _home_position + Vector3(randf_range(-enemy_definition.patrol_radius, enemy_definition.patrol_radius), 0, randf_range(-enemy_definition.patrol_radius, enemy_definition.patrol_radius))
				move_dir = (wander_target - global_position).normalized()
				move_dir.y = 0

				if global_position.distance_to(wander_target) < 1.0:
					_state = AIState.IDLE
					_state_timer = randf_range(2.0, 5.0)

		AIState.CHASE:
			if _target:
				move_dir = (_target.global_position - global_position).normalized()
				move_dir.y = 0

		AIState.ATTACK:
			# Stop moving during attack
			move_dir = Vector3.ZERO

		AIState.FLEE:
			if _target:
				move_dir = (global_position - _target.global_position).normalized()
				move_dir.y = 0
				speed *= 1.5

	if move_dir != Vector3.ZERO:
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed
		look_at(global_position + move_dir, Vector3.UP)
	else:
		velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 10.0 * delta)

	# Gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0

	move_and_slide()

func _attack() -> void:
	if not _target:
		return

	var damage = enemy_definition.attack_damage if enemy_definition else 10.0
	var result = CombatSystemGlobal.apply_damage(self, _target, damage, 0.0)

	# Play attack animation
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")

func _find_player() -> Node:
	var game_world = get_tree().root.get_node_or_null("GameWorld")
	if game_world:
		return game_world.get_node_or_null("Player")
	return null

func _on_health_changed(current: float, max: float) -> void:
	health_changed.emit(current, max)

	# Flee at low health
	if current > 0 and current / max < 0.25 and _state != AIState.FLEE:
		_state = AIState.FLEE
		state_changed.emit("flee")

func _on_died() -> void:
	_state = AIState.DEAD
	state_changed.emit("dead")

	# Drop loot
	if enemy_definition:
		_drop_loot()

	# Disable collision and movement
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)

	# Play death animation
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
		await animation_player.animation_finished

	died.emit()
	queue_free()

func _drop_loot() -> void:
	if not enemy_definition:
		return

	for loot in enemy_definition.loot_table:
		if randf() < loot.chance:
			var count = loot.count
			# Spawn pickup at position
			var pickup_scene = ResourceLoader.load("res://scenes/ItemPickup.tscn")
			if pickup_scene:
				var pickup = pickup_scene.instantiate()
				pickup.global_position = global_position + Vector3(randf_range(-0.5, 0.5), 0.5, randf_range(-0.5, 0.5))
				pickup.set_item(loot.item_id, count)
				get_parent().add_child(pickup)

func get_state() -> AIState:
	return _state

func serialize() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y, global_position.z],
		"health": health_comp.current_health,
		"state": _state,
		"patrol_index": _patrol_index
	}

func deserialize(data: Dictionary) -> void:
	if data.has("position"):
		global_position = Vector3(data["position"])
		_home_position = global_position
	if data.has("health"):
		health_comp.current_health = data["health"]
	if data.has("state"):
		_state = data["state"]
		state_changed.emit(_state_to_string(_state))
	if data.has("patrol_index"):
		_patrol_index = data["patrol_index"]

func _state_to_string(state: AIState) -> String:
	match state:
		AIState.IDLE: return "idle"
		AIState.PATROL: return "patrol"
		AIState.CHASE: return "chase"
		AIState.ATTACK: return "attack"
		AIState.FLEE: return "flee"
		AIState.DEAD: return "dead"
		_: return "unknown"