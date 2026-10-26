extends Node
class_name SurvivalComponent

signal hunger_changed(value: float)
signal thirst_changed(value: float)
signal stamina_changed(value: float)
signal starvation_damage
signal dehydration_damage
signal exhausted

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

	# Apply damage at 0
	if hunger <= 0.0:
		starvation_damage.emit()
	if thirst <= 0.0:
		dehydration_damage.emit()

func _update_stamina(delta: float) -> void:
	var old_stamina = stamina

	if _is_sprinting:
		stamina = max(0.0, stamina - stamina_drain_rate * delta)
		if stamina <= 0.0:
			_is_sprinting = false
			exhausted.emit()
	else:
		stamina = min(max_stamina, stamina + stamina_regen_rate * delta)

	if stamina != old_stamina:
		stamina_changed.emit(stamina)

func consume_stamina(amount: float) -> bool:
	if stamina >= amount:
		stamina -= amount
		stamina_changed.emit(stamina)
		return true
	return false

func restore_stamina(amount: float) -> void:
	stamina = min(max_stamina, stamina + amount)
	stamina_changed.emit(stamina)

func set_sprinting(sprinting: bool) -> void:
	_is_sprinting = sprinting

func is_sprinting() -> bool:
	return _is_sprinting

func eat(food_value: float) -> void:
	hunger = min(max_hunger, hunger + food_value)
	hunger_changed.emit(hunger)

func drink(water_value: float) -> void:
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
	return {
		"hunger": hunger,
		"thirst": thirst,
		"stamina": stamina
	}

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