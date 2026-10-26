extends Node
class_name HealthComponent

signal health_changed(current: float, max: float)
signal died
signal damaged(amount: float, source: Node)

@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var invulnerable_time: float = 0.5

var _last_damage_time: float = 0.0
var _has_taken_damage: bool = false
var _is_dead: bool = false

func _ready() -> void:
	current_health = min(current_health, max_health)

func take_damage(amount: float, source: Node = null) -> bool:
	if _is_dead:
		return false

	if amount <= 0:
		return false

	var now = Time.get_ticks_msec() / 1000.0
	if _has_taken_damage and now - _last_damage_time < invulnerable_time:
		return false

	_last_damage_time = now
	_has_taken_damage = true
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	damaged.emit(amount, source)

	if current_health <= 0.0:
		die()

	return true

func heal(amount: float) -> void:
	if _is_dead:
		return

	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func die() -> void:
	_is_dead = true
	process_mode = Node.PROCESS_MODE_DISABLED
	died.emit()

func is_dead() -> bool:
	return _is_dead

func get_health_percent() -> float:
	if max_health <= 0:
		return 0.0
	return current_health / max_health

func set_max_health(new_max: float) -> void:
	max_health = max(1.0, new_max)
	current_health = min(current_health, max_health)
	health_changed.emit(current_health, max_health)

func serialize() -> Dictionary:
	return {
		"max_health": max_health,
		"current_health": current_health
	}

func deserialize(data: Dictionary) -> void:
	if data.has("max_health"):
		max_health = data["max_health"]
	if data.has("current_health"):
		current_health = data["current_health"]
	_is_dead = current_health <= 0.0
	if _is_dead:
		process_mode = Node.PROCESS_MODE_DISABLED
	health_changed.emit(current_health, max_health)