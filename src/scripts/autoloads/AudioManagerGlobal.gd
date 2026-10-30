extends Node
## Fixed-size SFX pool; original PCM cues are generated once at startup.

const PALETTE = preload("res://resources/AudioPalette.tres")
const POOL_SIZE := 8
const SAMPLE_RATE := 22050

var _pool: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _index := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_pool.append(player)
	for key in PALETTE.cues:
		var cue: Array = PALETTE.cues[key]
		_streams[key] = _tone(float(cue[0]), float(cue[1]), float(cue[2]))


func _tone(frequency: float, duration: float, volume: float) -> AudioStreamWAV:
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for index in samples:
		var phase := float(index) / SAMPLE_RATE
		var envelope := pow(1.0 - float(index) / samples, 2)
		var sample := int(sin(phase * frequency * TAU) * envelope * volume * 32767)
		data.encode_s16(index * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func play_ui_sfx(sound_name: String) -> void:
	if not _streams.has(sound_name):
		return
	var player := _pool[_index]
	_index = (_index + 1) % POOL_SIZE
	player.stop()
	player.bus = "UI" if sound_name in ["click", "success"] else "SFX"
	player.stream = _streams[sound_name]
	player.play()


func get_bus_volume(bus_name: String) -> float:
	var index := AudioServer.get_bus_index(bus_name)
	return AudioServer.get_bus_volume_db(index) if index >= 0 else 0.0


func set_bus_volume_linear(bus_name: String, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
		AudioServer.set_bus_mute(index, volume <= 0)
