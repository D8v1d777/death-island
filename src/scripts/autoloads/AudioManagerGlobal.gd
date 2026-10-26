extends Node

## Audio management: bus control, SFX pooling, music crossfade.

signal bus_volume_changed(bus_name: String, volume_db: float)

@export_group("Configuration")
@export var max_sfx_instances: int = 32
@export var music_crossfade_time: float = 1.5

@export_group("Bus Names (Must match Project Settings)")
const BUS_MASTER: String = "Master"
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"
const BUS_UI: String = "UI"
const BUS_AMBIENCE: String = "Ambience"
const BUS_VOICE: String = "Voice"

var _music_player: AudioStreamPlayer = null
var _next_music_player: AudioStreamPlayer = null
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0

func _ready() -> void:
	# Create music players
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC
	add_child(_music_player)

	_next_music_player = AudioStreamPlayer.new()
	_next_music_player.bus = BUS_MUSIC
	add_child(_next_music_player)

	# Pre-create SFX pool
	for i in range(max_sfx_instances):
		var player = AudioStreamPlayer.new()
		player.bus = BUS_SFX
		player.finished.connect(_on_sfx_finished.bind(player))
		add_child(player)
		_sfx_pool.append(player)

func _on_sfx_finished(player: AudioStreamPlayer) -> void:
	# Return to pool (handled by index wrapping)
	pass

## Bus Control

func get_bus_volume(bus_name: String) -> float:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		return AudioServer.get_bus_volume_db(idx)
	return 0.0

func set_bus_volume(bus_name: String, volume_db: float) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, volume_db)
		bus_volume_changed.emit(bus_name, volume_db)

func get_bus_volume_linear(bus_name: String) -> float:
	var db = get_bus_volume(bus_name)
	return db_to_linear(db)

func set_bus_volume_linear(bus_name: String, volume: float) -> void:
	set_bus_volume(bus_name, linear_to_db(volume))

func mute_bus(bus_name: String, mute: bool) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_mute(idx, mute)

func is_bus_muted(bus_name: String) -> bool:
	# Note: AudioServer doesn't expose a getter for bus mute state in Godot 4.3
	# This would need to be tracked manually if needed
	return false

## Music

func play_music(stream: AudioStream, fade_in: float = 1.0) -> void:
	if not stream:
		return

	if _music_player.playing:
		crossfade_to(stream, fade_in)
	else:
		_music_player.stream = stream
		_music_player.play()
		if fade_in > 0:
			_music_player.volume_db = -80.0
			_tween_volume(_music_player, 0.0, fade_in)

func crossfade_to(new_stream: AudioStream, crossfade_time: float = -1.0) -> void:
	if crossfade_time < 0:
		crossfade_time = music_crossfade_time

	if not new_stream:
		stop_music(crossfade_time)
		return

	_next_music_player.stream = new_stream
	_next_music_player.play()
	_next_music_player.volume_db = -80.0

	# Fade out current, fade in next
	_tween_volume(_music_player, -80.0, crossfade_time)
	_tween_volume(_next_music_player, 0.0, crossfade_time)

	# Swap references after crossfade
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_callback(_swap_music_players).set_delay(crossfade_time)

func _swap_music_players() -> void:
	var temp = _music_player
	_music_player = _next_music_player
	_next_music_player = temp
	_next_music_player.stop()

func stop_music(fade_out: float = 1.0) -> void:
	if fade_out > 0 and _music_player.playing:
		_tween_volume(_music_player, -80.0, fade_out)
		var tween = create_tween()
		tween.tween_callback(_music_player.stop.bind()).set_delay(fade_out)
	else:
		_music_player.stop()

	_next_music_player.stop()

func pause_music() -> void:
	_music_player.pause = true
	_next_music_player.pause = true

func resume_music() -> void:
	_music_player.pause = false
	_next_music_player.pause = false

## SFX (Pooled)

func play_sfx(stream: AudioStream, position: Vector3 = Vector3.ZERO, volume_db: float = 0.0, pitch_scale: float = 1.0) -> AudioStreamPlayer:
	if not stream:
		return null

	var player = _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % max_sfx_instances

	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale

	# For 3D positioned sounds, we'd need AudioStreamPlayer3D
	# This is a simplified 2D version
	player.play()

	return player

func play_sfx_3d(stream: AudioStream, position: Vector3, volume_db: float = 0.0, pitch_scale: float = 1.0, max_distance: float = 20.0) -> AudioStreamPlayer3D:
	# For 3D sounds, create temporary player (could pool these too)
	if not stream:
		return null

	var player = AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.max_distance = max_distance
	player.global_position = position
	add_child(player)
	player.play()

	# Auto-cleanup
	player.finished.connect(player.queue_free.bind())

	return player

## UI Sounds

func play_ui_sfx(sound_name: String) -> void:
	# Map sound names to streams (could be a resource dictionary)
	var streams = {
		"click": "res://assets/audio/ui/click.ogg",
		"hover": "res://assets/audio/ui/hover.ogg",
		"error": "res://assets/audio/ui/error.ogg",
		"success": "res://assets/audio/ui/success.ogg",
		"open": "res://assets/audio/ui/open.ogg",
		"close": "res://assets/audio/ui/close.ogg",
	}

	if streams.has(sound_name):
		var path = streams[sound_name]
		var stream = load(path)
		if stream:
			var player = _sfx_pool[_sfx_pool_index]
			_sfx_pool_index = (_sfx_pool_index + 1) % max_sfx_instances
			player.stream = stream
			player.bus = BUS_UI
			player.play()
		else:
			push_warning("UI sound not found: ", path)

## Utility

func db_to_linear(db: float) -> float:
	return pow(10.0, db / 20.0)

func linear_to_db(linear: float) -> float:
	if linear <= 0:
		return -80.0
	return 20.0 * (log(linear) / log(10.0))

func _tween_volume(player: AudioStreamPlayer, target_db: float, duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(player, "volume_db", target_db, duration)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

## Settings Persistence

func apply_settings(settings: Dictionary) -> void:
	if settings.has("master_volume"):
		set_bus_volume(BUS_MASTER, settings["master_volume"])
	if settings.has("music_volume"):
		set_bus_volume(BUS_MUSIC, settings["music_volume"])
	if settings.has("sfx_volume"):
		set_bus_volume(BUS_SFX, settings["sfx_volume"])
	if settings.has("ui_volume"):
		set_bus_volume(BUS_UI, settings["ui_volume"])
	if settings.has("ambience_volume"):
		set_bus_volume(BUS_AMBIENCE, settings["ambience_volume"])