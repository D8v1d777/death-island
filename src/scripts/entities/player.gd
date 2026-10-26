extends CharacterBody3D
class_name Player

signal health_changed(current: float, max: float)
signal stamina_changed(current: float, max: float)
signal hunger_changed(current: float, max: float)
signal thirst_changed(current: float, max: float)
signal inventory_changed
signal level_up(level: int)

@export var move_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var gravity: float = 9.8
@export var mouse_sensitivity: float = 0.002
@export var interaction_range: float = 3.0

@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var camera_pivot: Node3D = $CameraPivot
@onready var health_comp: HealthComponent = $HealthComponent
@onready var inventory_comp: InventoryComponent = $InventoryComponent
@onready var survival_comp: SurvivalComponent = $SurvivalComponent
@onready var equipment_comp: EquipmentComponent = $EquipmentComponent

var _target_velocity: Vector3 = Vector3.ZERO
var _is_sprinting: bool = false
var _camera_rotation: Vector2 = Vector2.ZERO
var _interaction_target: Node = null
var _attack_cooldown: float = 0.0

func _ready() -> void:
	health_comp.health_changed.connect(_on_health_changed)
	health_comp.died.connect(_on_died)
	survival_comp.hunger_changed.connect(_on_hunger_changed)
	survival_comp.thirst_changed.connect(_on_thirst_changed)
	survival_comp.stamina_changed.connect(_on_stamina_changed)
	survival_comp.exhausted.connect(_on_exhausted)
	inventory_comp.inventory_changed.connect(_on_inventory_changed)
	if not InputManagerGlobal.camera_dragged.is_connected(_on_camera_dragged):
		InputManagerGlobal.camera_dragged.connect(_on_camera_dragged)
	add_to_group("player")

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_camera_rotation.x -= event.relative.y * mouse_sensitivity
		_camera_rotation.y -= event.relative.x * mouse_sensitivity
		_camera_rotation.x = clamp(_camera_rotation.x, -PI/2 + 0.1, PI/2 - 0.1)

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		GameManagerGlobal.toggle_pause()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_interact()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_try_attack()

func _physics_process(delta: float) -> void:
	_is_sprinting = InputManagerGlobal.is_action_pressed("sprint") and survival_comp.stamina > 0.0
	_handle_movement(delta)
	_handle_camera()
	_update_interaction_target()
	if InputManagerGlobal.is_action_just_pressed("interact"):
		_try_interact()
	if InputManagerGlobal.is_action_just_pressed("attack_light") or InputManagerGlobal.is_action_just_pressed("attack_heavy"):
		_try_attack()
	_attack_cooldown = max(0.0, _attack_cooldown - delta)

func _handle_movement(delta: float) -> void:
	var input_dir = Vector3.ZERO

	# Get input from InputManagerGlobal (handles both keyboard and touch)
	var move_forward = InputManagerGlobal.is_action_pressed("move_forward")
	var move_backward = InputManagerGlobal.is_action_pressed("move_backward")
	var move_left = InputManagerGlobal.is_action_pressed("move_left")
	var move_right = InputManagerGlobal.is_action_pressed("move_right")

	# Also check raw input for desktop testing
	if Input.is_action_pressed("move_forward"):
		move_forward = true
	if Input.is_action_pressed("move_backward"):
		move_backward = true
	if Input.is_action_pressed("move_left"):
		move_left = true
	if Input.is_action_pressed("move_right"):
		move_right = true

	if move_forward:
		input_dir.z -= 1.0
	if move_backward:
		input_dir.z += 1.0
	if move_left:
		input_dir.x -= 1.0
	if move_right:
		input_dir.x += 1.0

	if input_dir != Vector3.ZERO:
		input_dir = input_dir.normalized()

		# Get camera basis for relative movement
		var cam_basis = camera.global_transform.basis
		var forward = -cam_basis.z
		forward.y = 0
		forward = forward.normalized()
		var right = cam_basis.x
		right.y = 0
		right = right.normalized()

		var move_dir = (forward * input_dir.z + right * input_dir.x).normalized()

		var speed = move_speed
		if _is_sprinting and survival_comp.stamina > 0:
			speed = sprint_speed
			survival_comp.consume_stamina(15.0 * delta)

		_target_velocity.x = move_dir.x * speed
		_target_velocity.z = move_dir.z * speed
	else:
		_target_velocity.x = lerp(_target_velocity.x, 0.0, 10.0 * delta)
		_target_velocity.z = lerp(_target_velocity.z, 0.0, 10.0 * delta)

	# Apply gravity
	if not is_on_floor():
		_target_velocity.y -= gravity * delta
	else:
		_target_velocity.y = 0.0

	velocity = _target_velocity
	move_and_slide()

func _handle_camera() -> void:
	camera_pivot.rotation = Vector3(_camera_rotation.x, _camera_rotation.y, 0.0)
	camera.rotation = Vector3.ZERO

func _on_camera_dragged(delta: Vector2) -> void:
	var sensitivity = InputManagerGlobal.get_touch_sensitivity()
	var horizontal_sign = 1.0 if InputManagerGlobal.get_invert_camera_x() else -1.0
	var vertical_sign = 1.0 if InputManagerGlobal.get_invert_camera_y() else -1.0
	_camera_rotation.y += delta.x * sensitivity * horizontal_sign
	_camera_rotation.x += delta.y * sensitivity * vertical_sign
	_camera_rotation.x = clamp(_camera_rotation.x, -PI / 2.0 + 0.1, PI / 2.0 - 0.1)

func _update_interaction_target() -> void:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position + camera.global_transform.basis.z * -interaction_range)
	query.collision_mask = 1 << 3 | 1 << 4 | 1 << 6  # ResourceNode, WorldGeometry, Interactable
	query.exclude = [get_rid()]

	var result = space_state.intersect_ray(query)
	if result:
		var collider = Object.instance_from_id(result.collider_id)
		if collider and collider.has_method("can_interact") and collider.can_interact():
			_interaction_target = collider
			return

	_interaction_target = null

func _try_interact() -> void:
	if _interaction_target and _interaction_target.has_method("interact"):
		_interaction_target.interact(self)

func _try_attack() -> void:
	if _attack_cooldown > 0:
		return

	_attack_cooldown = 0.5

	# Raycast for attack
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position + camera.global_transform.basis.z * -2.5)
	query.collision_mask = 1 << 1  # Enemy layer
	query.exclude = [get_rid()]

	var result = space_state.intersect_ray(query)
	if result:
		var collider = Object.instance_from_id(result.collider_id)
		if collider and collider.is_in_group("enemies"):
			var damage_result = CombatSystemGlobal.apply_damage(self, collider, 20.0, 0.0, 0.1)
			var hit_sound = load("res://assets/audio/sfx/hit.ogg")
			if hit_sound:
				AudioManagerGlobal.play_sfx_3d(hit_sound, collider.global_position)
			if damage_result.killed:
				_on_enemy_defeated(collider)

func _on_enemy_defeated(enemy: Node) -> void:
	var definition = enemy.get("enemy_definition")
	if definition == null:
		return
	for drop in definition.loot_table:
		if randf() <= float(drop.get("chance", 0.0)):
			var item_id: String = str(drop.get("item_id", ""))
			var count: int = int(drop.get("count", 0))
			var item_definition = ResourceLoader.load("res://resources/definitions/items/%s.tres" % item_id)
			var weight = item_definition.weight if item_definition else 0.1
			inventory_comp.add_item(item_id, count, weight)

func _on_health_changed(current: float, max: float) -> void:
	health_changed.emit(current, max)

func _on_died() -> void:
	# Handle player death
	GameManagerGlobal.pause_game()
	# TODO: Show death screen

func _on_hunger_changed(value: float) -> void:
	hunger_changed.emit(value, survival_comp.max_hunger)

func _on_thirst_changed(value: float) -> void:
	thirst_changed.emit(value, survival_comp.max_thirst)

func _on_stamina_changed(value: float) -> void:
	stamina_changed.emit(value, survival_comp.max_stamina)

func _on_exhausted() -> void:
	_is_sprinting = false

func _on_inventory_changed() -> void:
	inventory_changed.emit()

func set_sprinting(sprinting: bool) -> void:
	_is_sprinting = sprinting and survival_comp.stamina > 0

func is_sprinting() -> bool:
	return _is_sprinting

func get_interaction_target() -> Node:
	return _interaction_target