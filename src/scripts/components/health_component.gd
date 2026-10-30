class_name HealthComponent
extends Node
## Damage and dodge immunity use game time, so pausing cannot expire them.

signal health_changed(current: float, maximum: float)
signal died
signal damaged(amount: float, source: Node)

@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var invulnerable_time: float = 0.3

var _immunity := 0.0
var _is_dead := false


func _physics_process(delta: float) -> void:
	_immunity = maxf(0.0, _immunity - delta)


func take_damage(amount: float, source: Node = null, bypass_immunity: bool = false) -> bool:
	if _is_dead or not is_finite(amount) or amount <= 0:
		return false
	if _immunity > 0 and not bypass_immunity:
		return false
	var applied := minf(current_health, amount)
	current_health -= applied
	if not bypass_immunity:
		_immunity = invulnerable_time
	health_changed.emit(current_health, max_health)
	damaged.emit(applied, source)
	if current_health <= 0:
		die()
	return true


func grant_immunity(duration: float) -> void:
	_immunity = maxf(_immunity, duration)


func heal(amount: float) -> void:
	if _is_dead or not is_finite(amount) or amount <= 0:
		return
	current_health = minf(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)


func die() -> void:
	if _is_dead:
		return
	current_health = 0
	_is_dead = true
	died.emit()


func is_dead() -> bool:
	return _is_dead


func serialize() -> Dictionary:
	return {"max_health": max_health, "current_health": current_health}


func deserialize(data: Dictionary) -> void:
	max_health = clampf(float(data.get("max_health", max_health)), 1, 1000)
	current_health = clampf(float(data.get("current_health", max_health)), 0, max_health)
	_immunity = 0
	_is_dead = current_health <= 0
	health_changed.emit(current_health, max_health)
