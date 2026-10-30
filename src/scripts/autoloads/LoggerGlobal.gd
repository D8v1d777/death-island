extends Node
## Bounded session log; no device identifiers or network logging.

const MAX_LINES := 200
var _lines: Array[String] = []


func info(message: String, context: String = "", data: Dictionary = {}) -> void:
	_record("INFO", message, context, data)


func warn(message: String, context: String = "", data: Dictionary = {}) -> void:
	_record("WARN", message, context, data)


func error(message: String, context: String = "", data: Dictionary = {}) -> void:
	_record("ERROR", message, context, data)


func _record(level: String, message: String, context: String, data: Dictionary) -> void:
	var line := JSON.stringify(
		{
			"level": level,
			"message": message,
			"context": context,
			"data": data,
			"time": Time.get_ticks_msec()
		}
	)
	if _lines.size() == MAX_LINES:
		_lines.pop_front()
	_lines.append(line)
	print(line)
