extends Node

## Save/Load system with versioned binary format, checksums, and corruption recovery.

signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool, data: Dictionary)
signal save_corrupted(slot: int, reason: String)
signal save_list_updated

const SAVE_MAGIC: int = 0x44495344  # "DISD" - Death Island Save Data
const SAVE_VERSION: int = 1
const MAX_SAVE_SLOTS: int = 10
const QUICKSAVE_SLOT: int = -1
const AUTOSAVE_SLOT: int = -2

@export_group("Configuration")
@export var save_directory: String = "user://saves/"
@export var auto_save_interval: float = 300.0  # 5 minutes
@export var max_backups_per_slot: int = 3

var _auto_save_timer: float = 0.0
var _is_saving: bool = false
var _is_loading: bool = false

func _ready() -> void:
	# Ensure save directory exists
	var dir = DirAccess.open(save_directory)
	if not dir:
		DirAccess.make_dir_recursive_absolute(save_directory)

	# Start auto-save timer
	_auto_save_timer = auto_save_interval

func _process(delta: float) -> void:
	if auto_save_interval > 0 and not _is_saving and not _is_loading:
		_auto_save_timer -= delta
		if _auto_save_timer <= 0:
			_auto_save_timer = auto_save_interval
			_trigger_auto_save()

func _trigger_auto_save() -> void:
	# Only auto-save during gameplay (not in menus)
	if GameManagerGlobal.is_paused or GameManagerGlobal.is_loading:
		return

	var player = _get_player()
	if not player:
		return

	save_game(AUTOSAVE_SLOT)

func save_game(slot: int, custom_data: Dictionary = {}) -> Error:
	if _is_saving:
		return ERR_BUSY

	_is_saving = true

	var save_data = _gather_save_data(custom_data)
	var result = _write_save_file(slot, save_data)

	_is_saving = false

	if result == OK:
		save_completed.emit(slot, true)
		_save_list_updated()
	else:
		save_completed.emit(slot, false)

	return result

func load_game(slot: int) -> Dictionary:
	if _is_loading:
		return {}

	_is_loading = true

	var data = _read_save_file(slot)

	_is_loading = false

	if data:
		load_completed.emit(slot, true, data)
		return data
	else:
		load_completed.emit(slot, false, {})
		return {}

func delete_save(slot: int) -> void:
	var path = _get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		_save_list_updated()

func list_saves() -> Array[Dictionary]:
	var saves = []
	var dir = DirAccess.open(save_directory)
	if not dir:
		return saves

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".save"):
			var slot = _slot_from_filename(file_name)
			if slot >= 0:
				var info = _get_save_info(slot)
				if info:
					saves.append(info)
		file_name = dir.get_next()
	dir.list_dir_end()

	# Sort by timestamp descending
	saves.sort_custom(Callable(self, "_compare_save_timestamp"))
	return saves

func _compare_save_timestamp(a: Dictionary, b: Dictionary) -> int:
	var ta = a.get("timestamp", 0)
	var tb = b.get("timestamp", 0)
	return -1 if ta > tb else (1 if ta < tb else 0)

func _get_save_info(slot: int) -> Dictionary:
	var path = _get_save_path(slot)
	if not FileAccess.file_exists(path):
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}

	# Read header only
	var magic = file.get_32()
	var version = file.get_16()
	var checksum = file.get_32()
	var timestamp = file.get_64()
	file.close()

	var slot_name = _get_slot_display_name(slot)
	return {
		"slot": slot,
		"name": slot_name,
		"version": version,
		"timestamp": timestamp,
		"valid": magic == SAVE_MAGIC,
		"path": path
	}

func _get_slot_display_name(slot: int) -> String:
	match slot:
		QUICKSAVE_SLOT: return "Quicksave"
		AUTOSAVE_SLOT: return "Autosave"
		_: return "Slot %d" % (slot + 1)

func _gather_save_data(custom_data: Dictionary) -> Dictionary:
	var player = _get_player()
	var game_world = _get_game_world()

	var data = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"scene_path": GameManagerGlobal.current_scene_name,
		"player": {},
		"world": {},
		"inventory": {},
		"known_recipes": [],
		"quests": {},
		"npc_trust": {},
		"settings": _get_settings_snapshot()
	}

	# Player data
	if player:
		data["player"] = _serialize_player(player)

	# World data
	if game_world:
		data["world"] = _serialize_world(game_world)

	# Inventory
	if player:
		var inventory_comp = player.get_node_or_null("InventoryComponent")
		if inventory_comp:
			data["inventory"] = inventory_comp.serialize()

	# Known recipes
	data["known_recipes"] = CraftingSystemGlobal.get_known_recipes()

	# Quests
	# data["quests"] = QuestSystemGlobal.serialize()

	# NPC Trust
	# data["npc_trust"] = NPCTrustGlobal.serialize()

	# Merge custom data
	for key in custom_data:
		data[key] = custom_data[key]

	return data

func _serialize_player(player: Node) -> Dictionary:
	var health_comp = player.get_node_or_null("HealthComponent")
	var survival_comp = player.get_node_or_null("SurvivalComponent")
	var inventory_comp = player.get_node_or_null("InventoryComponent")
	var equipment_comp = player.get_node_or_null("EquipmentComponent")

	return {
		"position": [player.global_position.x, player.global_position.y, player.global_position.z],
		"rotation": [player.global_rotation.x, player.global_rotation.y, player.global_rotation.z],
		"health": health_comp.current_health if health_comp else 100.0,
		"max_health": health_comp.max_health if health_comp else 100.0,
		"stamina": survival_comp.stamina if survival_comp else 100.0,
		"hunger": survival_comp.hunger if survival_comp else 100.0,
		"thirst": survival_comp.thirst if survival_comp else 100.0,
		"inventory": inventory_comp.serialize() if inventory_comp else {},
		"equipment": equipment_comp.serialize() if equipment_comp else {}
	}

func _serialize_world(game_world: Node) -> Dictionary:
	# Serialize resource nodes, enemy spawns, placed objects, time of day
	return {
		"time_of_day": 0.5,  # TimeOfDayGlobal.get_time()
		"resource_nodes": ResourceSystemGlobal.serialize(),
		"enemy_spawns": [],    # SpawnSystemGlobal.serialize()
		"placed_objects": []   # BuildingSystemGlobal.serialize()
	}

func _get_settings_snapshot() -> Dictionary:
	return {
		"master_volume": AudioManagerGlobal.get_bus_volume("Master"),
		"music_volume": AudioManagerGlobal.get_bus_volume("Music"),
		"sfx_volume": AudioManagerGlobal.get_bus_volume("SFX"),
		"ui_volume": AudioManagerGlobal.get_bus_volume("UI"),
		"ambience_volume": AudioManagerGlobal.get_bus_volume("Ambience"),
		"touch_sensitivity": InputManagerGlobal.get_touch_sensitivity(),
		"invert_camera_x": InputManagerGlobal.get_invert_camera_x(),
		"invert_camera_y": InputManagerGlobal.get_invert_camera_y(),
		"vibration_enabled": InputManagerGlobal.is_vibration_enabled()
	}

func _write_save_file(slot: int, data: Dictionary) -> Error:
	var path = _get_save_path(slot)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return ERR_CANT_OPEN

	# Serialize to JSON
	var json_string = JSON.stringify(data, "\t")
	var json_bytes = json_string.to_utf8_buffer()

	# Calculate checksum (simple CRC32)
	var checksum = _calculate_checksum(json_bytes)

	# Write header
	file.store_32(SAVE_MAGIC)
	file.store_16(SAVE_VERSION)
	file.store_32(checksum)
	file.store_64(data["timestamp"])

	# Write body
	file.store_buffer(json_bytes)
	file.close()

	# Verify written file
	return OK if _verify_save_file(path) else ERR_FILE_CORRUPT

func _read_save_file(slot: int) -> Dictionary:
	var path = _get_save_path(slot)

	if not _verify_save_file(path):
		save_corrupted.emit(slot, "Checksum mismatch or invalid format")
		return _attempt_recovery(slot)

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}

	# Skip header (already verified)
	file.seek(4 + 2 + 4 + 8)  # magic + version + checksum + timestamp

	var json_bytes = file.get_buffer(file.get_length() - file.get_position())
	file.close()

	var json_string = json_bytes.get_string_from_utf8()
	var parse_result = JSON.parse_string(json_string)

	if parse_result.error != OK:
		save_corrupted.emit(slot, "JSON parse error: " + parse_result.error_message)
		return _attempt_recovery(slot)

	return parse_result

func _verify_save_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return false

	if file.get_length() < 18:  # Minimum header size
		file.close()
		return false

	var magic = file.get_32()
	if magic != SAVE_MAGIC:
		file.close()
		return false

	var version = file.get_16()
	if version > SAVE_VERSION:
		file.close()
		return false  # Future version, can't read

	var stored_checksum = file.get_32()
	var timestamp = file.get_64()

	var json_bytes = file.get_buffer(file.get_length() - file.get_position())
	file.close()

	var calculated_checksum = _calculate_checksum(json_bytes)
	return stored_checksum == calculated_checksum

func _calculate_checksum(data: PackedByteArray) -> int:
	# Simple CRC32 implementation
	var crc: int = 0xFFFFFFFF
	for byte in data:
		crc ^= byte
		for i in range(8):
			if crc & 1:
				crc = (crc >> 1) ^ 0xEDB88320
			else:
				crc >>= 1
	return ~crc & 0xFFFFFFFF

func _attempt_recovery(slot: int) -> Dictionary:
	# Try to load backup
	for i in range(max_backups_per_slot):
		var backup_path = _get_backup_path(slot, i)
		if FileAccess.file_exists(backup_path) and _verify_save_file(backup_path):
			var file = FileAccess.open(backup_path, FileAccess.READ)
			if file:
				file.seek(18)
				var json_bytes = file.get_buffer(file.get_length() - file.get_position())
				file.close()
				var json_string = json_bytes.get_string_from_utf8()
				var parse_result = JSON.parse_string(json_string)
				if parse_result.error == OK:
					push_warning("Recovered save slot %d from backup %d" % [slot, i])
					return parse_result

	return {}

func _create_backup(slot: int) -> void:
	var path = _get_save_path(slot)
	if not FileAccess.file_exists(path):
		return

	# Rotate backups
	for i in range(max_backups_per_slot - 1, 0, -1):
		var src = _get_backup_path(slot, i - 1)
		var dst = _get_backup_path(slot, i)
		if FileAccess.file_exists(src):
			DirAccess.remove_absolute(dst)
			DirAccess.copy_absolute(src, dst)

	# Create new backup
	var backup_path = _get_backup_path(slot, 0)
	DirAccess.copy_absolute(path, backup_path)

func _get_save_path(slot: int) -> String:
	var slot_name = _get_slot_filename(slot)
	return save_directory.path_join(slot_name)

func _get_backup_path(slot: int, index: int) -> String:
	var slot_name = _get_slot_filename(slot)
	return save_directory.path_join("%s.backup%d" % [slot_name, index])

func _get_slot_filename(slot: int) -> String:
	match slot:
		QUICKSAVE_SLOT: return "quicksave.save"
		AUTOSAVE_SLOT: return "autosave.save"
		_: return "slot_%d.save" % slot

func _slot_from_filename(filename: String) -> int:
	if filename == "quicksave.save":
		return QUICKSAVE_SLOT
	if filename == "autosave.save":
		return AUTOSAVE_SLOT
	if filename.begins_with("slot_") and filename.ends_with(".save"):
		var num_str = filename.substr(5, filename.length() - 10)
		return num_str.to_int()
	return -1

func _get_player() -> Node:
	var game_world = _get_game_world()
	if game_world:
		return game_world.get_node_or_null("Player")
	return null

func _get_game_world() -> Node:
	var current = GameManagerGlobal.get_current_scene()
	if current:
		return current.get_node_or_null("GameWorld")
	return null

func _save_list_updated() -> void:
	save_list_updated.emit()