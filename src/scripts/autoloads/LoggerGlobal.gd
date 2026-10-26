extends Node

## Structured logging with levels, categories, and optional file output.

enum LogLevel {
	DEBUG = 0,
	INFO = 1,
	WARN = 2,
	ERROR = 3,
	FATAL = 4
}

enum LogCategory {
	GENERAL,
	GAMEPLAY,
	COMBAT,
	CRAFTING,
	INVENTORY,
	SAVE_LOAD,
	AI,
	UI,
	AUDIO,
	INPUT,
	PERFORMANCE,
	NETWORK
}

@export_group("Configuration")
@export var min_log_level: int = LogLevel.DEBUG
@export var log_to_file: bool = true
@export var log_file_path: String = "user://logs/death_island.log"
@export var max_log_file_size: int = 10 * 1024 * 1024  # 10 MB
@export var max_log_files: int = 5
@export var include_timestamp: bool = true
@export var include_category: bool = true
@export var include_stack_trace: bool = false

@export_group("Runtime")
@export var session_start_time: int = 0

var _log_file: FileAccess = null
var _current_log_size: int = 0
var _log_buffer: Array[String] = []
const BUFFER_FLUSH_INTERVAL: float = 5.0
var _buffer_timer: float = 0.0

func _ready() -> void:
	session_start_time = Time.get_unix_time_from_system()

	if log_to_file:
		_open_log_file()

	# Log session start
	info("Logger initialized", "session_start", {
		"godot_version": Engine.get_version_info()["string"],
		"project_version": ProjectSettings.get_setting("application/config/version"),
		"os": OS.get_name(),
		"device_model": OS.get_model_name()
	})

func _process(delta: float) -> void:
	_buffer_timer += delta
	if _buffer_timer >= BUFFER_FLUSH_INTERVAL:
		_flush_buffer()
		_buffer_timer = 0.0

func _exit_tree() -> void:
	_flush_buffer()
	_close_log_file()

## Public Logging API

func debug(message: String, context: String = "", data: Dictionary = {}) -> void:
	_log(LogLevel.DEBUG, message, context, data)

func info(message: String, context: String = "", data: Dictionary = {}) -> void:
	_log(LogLevel.INFO, message, context, data)

func warn(message: String, context: String = "", data: Dictionary = {}) -> void:
	_log(LogLevel.WARN, message, context, data)

func error(message: String, context: String = "", data: Dictionary = {}) -> void:
	_log(LogLevel.ERROR, message, context, data)

func fatal(message: String, context: String = "", data: Dictionary = {}) -> void:
	_log(LogLevel.FATAL, message, context, data)
	# In a real game, might trigger crash reporter here

## Category-specific shortcuts

func gameplay(message: String, data: Dictionary = {}) -> void:
	_log(LogLevel.INFO, message, "GAMEPLAY", data)

func combat(message: String, data: Dictionary = {}) -> void:
	_log(LogLevel.INFO, message, "COMBAT", data)

func crafting(message: String, data: Dictionary = {}) -> void:
	_log(LogLevel.INFO, message, "CRAFTING", data)

func inventory(message: String, data: Dictionary = {}) -> void:
	_log(LogLevel.INFO, message, "INVENTORY", data)

func save_load(message: String, data: Dictionary = {}) -> void:
	_log(LogLevel.INFO, message, "SAVE_LOAD", data)

func ai(message: String, data: Dictionary = {}) -> void:
	_log(LogLevel.INFO, message, "AI", data)

func ui(message: String, data: Dictionary = {}) -> void:
	_log(LogLevel.DEBUG, message, "UI", data)

func audio(message: String, data: Dictionary = {}) -> void:
	_log(LogLevel.DEBUG, message, "AUDIO", data)

func input(message: String, data: Dictionary = {}) -> void:
	_log(LogLevel.DEBUG, message, "INPUT", data)

func performance(message: String, data: Dictionary = {}) -> void:
	_log(LogLevel.INFO, message, "PERFORMANCE", data)

## Internal Logging

func _log(level: int, message: String, context: String, data: Dictionary) -> void:
	if level < min_log_level:
		return

	var timestamp = ""
	if include_timestamp:
		var now = Time.get_datetime_dict_from_system()
		timestamp = "[%02d:%02d:%02d.%03d] " % [
			now.hour, now.minute, now.second,
			Time.get_ticks_msec() % 1000
		]

	var level_str = _level_to_string(level)
	var category_str = ""
	if include_category and context != "":
		category_str = "[%s] " % context

	var data_str = ""
	if data.size() > 0:
		data_str = " %s" % JSON.stringify(data)

	var formatted = "%s%s%s%s%s" % [timestamp, level_str, category_str, message, data_str]

	# Print to console
	match level:
		LogLevel.DEBUG: print(formatted)
		LogLevel.INFO: print(formatted)
		LogLevel.WARN: push_warning(formatted)
		LogLevel.ERROR: push_error(formatted)
		LogLevel.FATAL: push_error("[FATAL] " + formatted)

	# Buffer for file
	if log_to_file:
		_log_buffer.append(formatted)

	# Include stack trace for errors
	if include_stack_trace and level >= LogLevel.ERROR:
		var stack = _get_stack_trace()
		if stack:
			var stack_str = "  Stack: %s" % stack
			print(stack_str)
			if log_to_file:
				_log_buffer.append(stack_str)

func _level_to_string(level: int) -> String:
	match level:
		LogLevel.DEBUG: return "[DEBUG] "
		LogLevel.INFO: return "[INFO]  "
		LogLevel.WARN: return "[WARN]  "
		LogLevel.ERROR: return "[ERROR] "
		LogLevel.FATAL: return "[FATAL] "
		_: return "[UNK]   "

func _get_stack_trace() -> String:
	# Godot 4 doesn't have easy stack trace access from GDScript
	# This is a placeholder
	return ""

## File Management

func _open_log_file() -> void:
	var dir = log_file_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)

	# Rotate logs if needed
	_rotate_logs()

	_log_file = FileAccess.open(log_file_path, FileAccess.WRITE_READ)
	if _log_file:
		_log_file.seek_end()
		_current_log_size = _log_file.get_position()
		_write_to_file("=== Session Start: %s ===" % Time.get_datetime_string_from_system())
	else:
		push_error("Failed to open log file: %s" % log_file_path)

func _close_log_file() -> void:
	if _log_file:
		_write_to_file("=== Session End ===")
		_log_file.close()
		_log_file = null

func _rotate_logs() -> void:
	var base_path = log_file_path.get_base_dir().path_join(log_file_path.get_file().get_basename())
	var ext = log_file_path.get_extension()

	# Remove oldest if at max
	var oldest = "%s.%d.%s" % [base_path, max_log_files - 1, ext]
	if FileAccess.file_exists(oldest):
		DirAccess.remove_absolute(oldest)

	# Rotate existing
	for i in range(max_log_files - 2, -1, -1):
		var src = "%s.%d.%s" % [base_path, i, ext] if i > 0 else log_file_path
		var dst = "%s.%d.%s" % [base_path, i + 1, ext]
		if FileAccess.file_exists(src):
			DirAccess.copy_absolute(src, dst)
			if i > 0:
				DirAccess.remove_absolute(src)

func _write_to_file(line: String) -> void:
	if not _log_file:
		return

	var line_bytes = (line + "\n").to_utf8_buffer()
	_log_file.store_buffer(line_bytes)
	_current_log_size += line_bytes.size()

	# Check size limit
	if _current_log_size > max_log_file_size:
		_close_log_file()
		_rotate_logs()
		_open_log_file()

func _flush_buffer() -> void:
	if _log_buffer.is_empty():
		return

	for line in _log_buffer:
		_write_to_file(line)

	_log_buffer.clear()

## Utility

func get_log_file_path() -> String:
	return log_file_path

func get_recent_logs(count: int = 100) -> Array[String]:
	var lines = []
	if FileAccess.file_exists(log_file_path):
		var file = FileAccess.open(log_file_path, FileAccess.READ)
		if file:
			var all_text = file.get_as_text()
			file.close()
			lines = all_text.split("\n")

	if lines.size() > count:
		var start = lines.size() - count
		return lines.slice(start, lines.size())
	return lines

func clear_logs() -> void:
	_close_log_file()
	if FileAccess.file_exists(log_file_path):
		DirAccess.remove_absolute(log_file_path)
	_open_log_file()