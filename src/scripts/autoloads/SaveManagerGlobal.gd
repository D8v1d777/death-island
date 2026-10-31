extends Node
## Versioned, validated saves with verified temporary writes and backup recovery.

signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool, data: Dictionary)
signal save_corrupted(slot: int, reason: String)
signal save_list_updated

const SAVE_MAGIC := 0x44495344
const SAVE_VERSION := 2
const HEADER_SIZE := 18
const MAX_FILE_SIZE := 2 * 1024 * 1024
const MAX_SAVE_SLOTS := 10
const QUICKSAVE_SLOT := -1
const AUTOSAVE_SLOT := -2
const BACKUP_COUNT := 3

var save_directory := "user://save/"
var _busy := false


func valid_slot(slot: int) -> bool:
	return slot >= AUTOSAVE_SLOT and slot < MAX_SAVE_SLOTS


func save_game(slot: int, custom_data: Dictionary = {}) -> Error:
	if not valid_slot(slot):
		return _save_failure(slot, ERR_INVALID_PARAMETER)
	if _busy:
		return _save_failure(slot, ERR_BUSY)
	var data := (
		custom_data.duplicate(true) if not custom_data.is_empty() else GameManagerGlobal.snapshot()
	)
	if data.is_empty():
		return _save_failure(slot, ERR_UNAVAILABLE)
	data["version"] = SAVE_VERSION
	data["timestamp"] = int(Time.get_unix_time_from_system())
	if not StateValidation.state(data):
		return _save_failure(slot, ERR_INVALID_DATA)
	_busy = true
	var result := _write_save_file(slot, data)
	_busy = false
	save_completed.emit(slot, result == OK)
	save_list_updated.emit()
	return result


func _save_failure(slot: int, error: Error) -> Error:
	save_completed.emit(slot, false)
	return error


func load_game(slot: int) -> Dictionary:
	if not valid_slot(slot) or _busy:
		return {}
	var data := _read_path(_get_save_path(slot))
	if data.is_empty():
		for index in BACKUP_COUNT:
			data = _read_path(_backup_path(slot, index))
			if not data.is_empty():
				save_corrupted.emit(slot, "Recovered the previous valid backup")
				break
	load_completed.emit(slot, not data.is_empty(), data)
	return data


func delete_save(slot: int) -> void:
	if not valid_slot(slot):
		return
	for path in [
		_get_save_path(slot), _backup_path(slot, 0), _backup_path(slot, 1), _backup_path(slot, 2)
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	save_list_updated.emit()


func list_saves() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot in range(AUTOSAVE_SLOT, MAX_SAVE_SLOTS):
		var data := load_game(slot)
		if not data.is_empty():
			result.append(
				{"slot": slot, "timestamp": data.get("timestamp", 0), "name": slot_name(slot)}
			)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.timestamp > b.timestamp)
	return result


func slot_name(slot: int) -> String:
	if slot == QUICKSAVE_SLOT:
		return "Quicksave"
	if slot == AUTOSAVE_SLOT:
		return "Autosave"
	return "Slot %d" % (slot + 1)


func _get_save_path(slot: int) -> String:
	var filename := "slot_%d.save" % slot
	if slot == QUICKSAVE_SLOT:
		filename = "quicksave.save"
	elif slot == AUTOSAVE_SLOT:
		filename = "autosave.save"
	return save_directory.path_join(filename)


func _backup_path(slot: int, index: int) -> String:
	return _get_save_path(slot) + ".backup%d" % index


func _write_save_file(slot: int, data: Dictionary) -> Error:
	var directory_error := DirAccess.make_dir_recursive_absolute(save_directory)
	if directory_error != OK:
		return directory_error
	var bytes := JSON.stringify(data).to_utf8_buffer()
	if bytes.size() + HEADER_SIZE > MAX_FILE_SIZE:
		return ERR_OUT_OF_MEMORY
	var path := _get_save_path(slot)
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	file.store_32(SAVE_MAGIC)
	file.store_16(SAVE_VERSION)
	file.store_32(_calculate_checksum(bytes))
	file.store_64(int(data.timestamp))
	file.store_buffer(bytes)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK or _read_path(temporary).is_empty():
		DirAccess.remove_absolute(temporary)
		return ERR_FILE_CORRUPT
	var backup_error := _backup(slot)
	if backup_error != OK:
		return backup_error
	return DirAccess.rename_absolute(temporary, path)


func _backup(slot: int) -> Error:
	var path := _get_save_path(slot)
	if _read_path(path).is_empty():
		return OK
	for index in range(BACKUP_COUNT - 1, 0, -1):
		var old := _backup_path(slot, index - 1)
		if FileAccess.file_exists(old):
			var error := DirAccess.copy_absolute(old, _backup_path(slot, index))
			if error != OK:
				return error
	return DirAccess.copy_absolute(path, _backup_path(slot, 0))


func _read_path(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	if (
		file.get_length() <= HEADER_SIZE
		or file.get_length() > MAX_FILE_SIZE
		or file.get_32() != SAVE_MAGIC
	):
		return {}
	var version := file.get_16()
	if version < 1 or version > SAVE_VERSION:
		return {}
	var checksum := file.get_32()
	var timestamp := file.get_64()
	var bytes := file.get_buffer(file.get_length() - HEADER_SIZE)
	file.close()
	if checksum != _calculate_checksum(bytes):
		return {}
	return _decode(bytes, version, timestamp)


func _decode(bytes: PackedByteArray, version: int, timestamp: int) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(bytes.get_string_from_utf8()) != OK or not parser.data is Dictionary:
		return {}
	var data: Dictionary = parser.data
	if not StateValidation.number(data.get("version", version), version, version):
		return {}
	if version == 1:
		data = migrate_v1(data)
	data["timestamp"] = timestamp
	return data if StateValidation.state(data) else {}


func migrate_v1(old: Dictionary) -> Dictionary:
	var data := old.duplicate(true)
	data["version"] = SAVE_VERSION
	data["known_recipes"] = data.get("known_recipes", [])
	data["quests"] = data.get("quests", {})
	if data.get("world") is Dictionary:
		var time: Variant = data.world.get("time_of_day", 0.25)
		if StateValidation.number(time, 0, 1):
			data.world["elapsed"] = float(time) * 1440.0
	return data


func _calculate_checksum(data: PackedByteArray) -> int:
	var crc := 0xFFFFFFFF
	for byte in data:
		crc ^= byte
		for bit in 8:
			crc = (crc >> 1) ^ 0xEDB88320 if crc & 1 else crc >> 1
	return ~crc & 0xFFFFFFFF
