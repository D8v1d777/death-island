class_name SurvivalComponent
extends Node

signal hunger_changed(value: float)
signal thirst_changed(value: float)
signal stamina_changed(value: float)
signal starvation_damage
signal dehydration_damage
signal exhausted

const REGEN_DELAY: float = 0.8

@export var max_hunger: float = 100.0
@export var max_thirst: float = 100.0
@export var max_stamina: float = 100.0

@export var hunger_rate: float = 1.0  # per minute
@export var thirst_rate: float = 1.5  # per minute
@export var stamina_regen_rate: float = 10.0  # per second
@export var stamina_drain_rate: float = 15.0  # per second when sprinting

@export var starvation_damage_rate: float = 2.0  # per second at 0 hunger
@export var dehydration_damage_rate: float = 3.0  # per second at 0 thirst

var hunger: float = 100.0
var thirst: float = 100.0
var stamina: float = 100.0

var _is_sprinting: bool = false
var _regen_delay: float = 0.0
var _damage_timer: float = 0.0


func _ready() -> void:
	hunger = min(hunger, max_hunger)
	thirst = min(thirst, max_thirst)
	stamina = min(stamina, max_stamina)


func _process(delta: float) -> void:
	_update_hunger_thirst(delta)
	_update_stamina(delta)


func _update_hunger_thirst(delta: float) -> void:
	var old_hunger = hunger
	var old_thirst = thirst

	hunger = max(0.0, hunger - hunger_rate * (delta / 60.0))
	thirst = max(0.0, thirst - thirst_rate * (delta / 60.0))

	if hunger != old_hunger:
		hunger_changed.emit(hunger)
	if thirst != old_thirst:
		thirst_changed.emit(thirst)

	_damage_timer += delta
	if _damage_timer >= 1.0:
		var elapsed := floorf(_damage_timer)
		_damage_timer -= elapsed
		var health := get_parent().get_node_or_null("HealthComponent") as HealthComponent
		var damage := 0.0
		if hunger <= 0.0:
			starvation_damage.emit()
			damage += starvation_damage_rate * elapsed
		if thirst <= 0.0:
			dehydration_damage.emit()
			damage += dehydration_damage_rate * elapsed
		if health and damage > 0:
			health.take_damage(damage, null, true)


func _update_stamina(delta: float) -> void:
	var old_stamina = stamina
	_regen_delay = maxf(0, _regen_delay - delta)

	if _is_sprinting:
		stamina = max(0.0, stamina - stamina_drain_rate * delta)
		if stamina <= 0.0:
			_is_sprinting = false
			exhausted.emit()
	elif _regen_delay <= 0:
		stamina = min(max_stamina, stamina + stamina_regen_rate * delta)

	if stamina != old_stamina:
		stamina_changed.emit(stamina)


func consume_stamina(amount: float) -> bool:
	if is_finite(amount) and amount > 0 and stamina >= amount:
		stamina -= amount
		_regen_delay = REGEN_DELAY
		stamina_changed.emit(stamina)
		return true
	return false


func restore_stamina(amount: float) -> void:
	if not is_finite(amount) or amount < 0:
		return
	stamina = min(max_stamina, stamina + amount)
	stamina_changed.emit(stamina)


func set_sprinting(sprinting: bool) -> void:
	_is_sprinting = sprinting


func is_sprinting() -> bool:
	return _is_sprinting


func eat(food_value: float) -> void:
	if not is_finite(food_value) or food_value < 0:
		return
	hunger = min(max_hunger, hunger + food_value)
	hunger_changed.emit(hunger)


func drink(water_value: float) -> void:
	if not is_finite(water_value) or water_value < 0:
		return
	thirst = min(max_thirst, thirst + water_value)
	thirst_changed.emit(thirst)


func get_hunger_percent() -> float:
	if max_hunger <= 0:
		return 0.0
	return hunger / max_hunger


func get_thirst_percent() -> float:
	if max_thirst <= 0:
		return 0.0
	return thirst / max_thirst


func get_stamina_percent() -> float:
	if max_stamina <= 0:
		return 0.0
	return stamina / max_stamina


func serialize() -> Dictionary:
	return {"hunger": hunger, "thirst": thirst, "stamina": stamina}


func deserialize(data: Dictionary) -> void:
	if data.has("hunger"):
		hunger = clamp(data["hunger"], 0.0, max_hunger)
	if data.has("thirst"):
		thirst = clamp(data["thirst"], 0.0, max_thirst)
	if data.has("stamina"):
		stamina = clamp(data["stamina"], 0.0, max_stamina)

	hunger_changed.emit(hunger)
	thirst_changed.emit(thirst)
	stamina_changed.emit(stamina)
