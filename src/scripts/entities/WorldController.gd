extends Node

## World controller: manages environment, spawning, time of day, weather.

signal time_changed(time_of_day: float)  # 0.0 - 1.0
signal weather_changed(weather_type: String)

@export_group("Time of Day")
@export var day_duration_seconds: float = 1200.0  # 20 minutes = 1 day
@export var start_time: float = 0.25  # 6 AM
@export var time_scale: float = 1.0

@export_group("References")
@export var player_spawn: Node3D

var _current_time: float = 0.0
var _time_of_day: float = 0.0
var _is_initialized: bool = false

func _ready() -> void:
	_current_time = start_time
	_time_of_day = start_time
	_is_initialized = true

	# Ensure player exists
	_ensure_player()

	LoggerGlobal.info("WorldController initialized", "WORLD", {
		"day_duration": day_duration_seconds,
		"start_time": start_time
	})

func _process(delta: float) -> void:
	if not _is_initialized:
		return

	_current_time += delta * time_scale

	# Wrap around day
	if _current_time >= 1.0:
		_current_time = fmod(_current_time, 1.0)

	_time_of_day = _current_time
	time_changed.emit(_time_of_day)

func _ensure_player() -> void:
	# Player is instanced by GameManager after scene load
	# This is just a fallback
	if not player_spawn:
		player_spawn = get_node_or_null("PlayerSpawn")

	if not get_tree().get_nodes_in_group("player").size():
		LoggerGlobal.warn("No player found in scene", "WORLD")

func get_time_of_day() -> float:
	return _time_of_day

func get_time_string() -> String:
	var hours = int(_time_of_day * 24)
	var minutes = int(fmod(_time_of_day * 24 * 60, 60))
	return "%02d:%02d" % [hours, minutes]

func is_day() -> bool:
	return _time_of_day >= 0.25 and _time_of_day < 0.75  # 6AM - 6PM

func is_night() -> bool:
	return not is_day()

func set_time(time_of_day: float) -> void:
	_current_time = clamp(time_of_day, 0.0, 1.0)
	_time_of_day = _current_time
	time_changed.emit(_time_of_day)

func get_player_spawn_position() -> Vector3:
	if player_spawn:
		return player_spawn.global_position
	return Vector3(0, 1, 0)

## Weather (placeholder for future)

func set_weather(weather_type: String) -> void:
	weather_changed.emit(weather_type)
	LoggerGlobal.info("Weather changed: %s" % weather_type, "WORLD")

## Serialization (for save system)

func serialize() -> Dictionary:
	return {
		"time_of_day": _time_of_day,
		"weather": "clear"
	}

func deserialize(data: Dictionary) -> void:
	if data.has("time_of_day"):
		set_time(data["time_of_day"])
	if data.has("weather"):
		set_weather(data["weather"])