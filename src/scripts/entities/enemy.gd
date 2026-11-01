class_name Enemy
extends CharacterBody3D
## Readable windup/recovery AI. Defeated enemies retain stable save identities.

enum AIState { IDLE, PATROL, CHASE, WINDUP, ATTACK, RECOVER, DEAD }

const GRAVITY := 20.0
const RESPAWN_SECONDS := 240.0
const LOOT_RETRY_SECONDS := 1.0

@export var enemy_definition: EnemyDefinition

var _state := AIState.PATROL
var _timer := 0.0
var _home := Vector3.ZERO
var _wander := Vector3.ZERO
var _attack_direction := Vector3.ZERO
var _knockback := Vector3.ZERO
var _respawn_timer := 0.0
var _body: Sprite3D
var _title: Label3D
var _pending_loot: Dictionary = {}
var _loot_retry := 0.0

@onready var health_comp: HealthComponent = $HealthComponent
@onready var visual: Node3D = $Visual


func _ready() -> void:
	add_to_group("enemies")
	_home = global_position
	_wander = _home + Vector3(2, 0, 2)
	health_comp.max_health = enemy_definition.max_health
	health_comp.current_health = enemy_definition.max_health
	health_comp.died.connect(_on_died)
	var height := 4.2 if enemy_definition.behavior == "guard" else 2.2
	_body = IllustratedArt.sprite(visual, enemy_definition.enemy_id, height)
	IllustratedArt.shadow(visual, 2.2)
	LowPoly.collision(
		self, enemy_definition.body_size, Vector3(0, enemy_definition.body_size.y / 2, 0)
	)
	_title = LowPoly.label(
		self, enemy_definition.display_name, IllustratedArt.SCREEN_UP * height, Color("eebc93")
	)


func _physics_process(delta: float) -> void:
	if _state == AIState.DEAD:
		if not _pending_loot.is_empty():
			_loot_retry -= delta
			if _loot_retry <= 0:
				_deliver_loot()
				_loot_retry = LOOT_RETRY_SECONDS
		if enemy_definition.behavior != "guard" and _pending_loot.is_empty():
			_respawn_timer -= delta
			if _respawn_timer <= 0:
				_respawn()
		return
	var player := GameManagerGlobal.get_player()
	if not player or player.health_comp.is_dead():
		return
	_timer -= delta
	var offset := player.global_position - global_position
	var distance := offset.length()
	var direction := Vector3.ZERO
	var speed := enemy_definition.move_speed
	_title.visible = distance < 14
	match _state:
		AIState.IDLE, AIState.PATROL:
			if distance < enemy_definition.detection_range:
				_state = AIState.CHASE
			elif enemy_definition.behavior != "ambush":
				if global_position.distance_to(_wander) < 0.7:
					_wander = _home + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
				direction = (_wander - global_position).normalized()
				speed *= 0.4
		AIState.CHASE:
			if distance > enemy_definition.detection_range * 1.8:
				_state = AIState.PATROL
			elif distance < enemy_definition.attack_range + 0.6:
				_state = AIState.WINDUP
				_timer = enemy_definition.windup
				_attack_direction = offset.normalized()
				_set_color(Color("f09a4b"))
			else:
				direction = offset.normalized()
				if enemy_definition.behavior == "circle" and distance < 5:
					direction = direction.rotated(Vector3.UP, 0.55)
		AIState.WINDUP:
			if _timer <= 0:
				_state = AIState.ATTACK
				_timer = 0.2
		AIState.ATTACK:
			if enemy_definition.behavior == "charge":
				direction = _attack_direction
				speed *= 2
			if _timer <= 0:
				if distance <= enemy_definition.attack_range + 0.6:
					CombatSystemGlobal.apply_damage(
						self,
						player,
						enemy_definition.attack_damage,
						player.equipment_comp.armor(),
						0
					)
				_state = AIState.RECOVER
				_timer = enemy_definition.attack_cooldown
				_set_color(enemy_definition.tint)
		AIState.RECOVER:
			if _timer <= 0:
				_state = AIState.CHASE
	_knockback = _knockback.move_toward(Vector3.ZERO, delta * 15)
	direction.y = 0
	velocity.x = direction.x * speed + _knockback.x
	velocity.z = direction.z * speed + _knockback.z
	velocity.y = -0.5 if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()
	if direction.length_squared() > 0.1:
		_body.flip_h = direction.x < 0
	if global_position.y < -5:
		global_position = _home


func _set_color(color: Color) -> void:
	_body.modulate = Color.WHITE if color == enemy_definition.tint else color


func knockback(force: Vector3) -> void:
	_knockback = force


func _on_died() -> void:
	_state = AIState.DEAD
	_respawn_timer = RESPAWN_SECONDS
	visible = false
	collision_layer = 0
	collision_mask = 0
	QuestSystemGlobal.record_kill(enemy_definition.enemy_id)
	for drop in enemy_definition.loot_table:
		if randf() <= float(drop.chance):
			_pending_loot[drop.item_id] = int(_pending_loot.get(drop.item_id, 0)) + int(drop.count)
	_deliver_loot()


func _deliver_loot() -> void:
	if not is_instance_valid(GameManagerGlobal.world):
		return
	for item_id in _pending_loot.keys():
		if GameManagerGlobal.world.spawn_pickup(
			item_id,
			int(_pending_loot[item_id]),
			global_position + Vector3(randf_range(-0.6, 0.6), 0.1, randf_range(-0.6, 0.6))
		):
			_pending_loot.erase(item_id)


func _respawn() -> void:
	global_position = _home
	health_comp.deserialize({"current_health": enemy_definition.max_health})
	_state = AIState.PATROL
	visible = true
	collision_layer = 2
	collision_mask = 25
	_set_color(enemy_definition.tint)


func get_state() -> AIState:
	return _state


func serialize() -> Dictionary:
	return {
		"position": StateValidation.array3(global_position),
		"health": health_comp.current_health,
		"dead": _state == AIState.DEAD,
		"respawn_timer": maxf(0, _respawn_timer),
		"pending_loot": _pending_loot.duplicate()
	}


func deserialize(data: Dictionary) -> void:
	global_position = StateValidation.vec3(data.get("position", StateValidation.array3(_home)))
	health_comp.deserialize({"current_health": data.get("health", enemy_definition.max_health)})
	_state = AIState.DEAD if data.get("dead", false) else AIState.PATROL
	_respawn_timer = clampf(float(data.get("respawn_timer", 0)), 0, RESPAWN_SECONDS)
	_pending_loot.clear()
	for item_id in data.get("pending_loot", {}):
		_pending_loot[item_id] = int(data.pending_loot[item_id])
	visible = _state != AIState.DEAD
	collision_layer = 2 if visible else 0
	collision_mask = 25 if visible else 0
