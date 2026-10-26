extends Node

signal resource_gathered(node: Node, item_id: String, count: int)
signal resource_depleted(node: Node)
signal resource_respawned(node: Node)

@export var respawn_time_min: float = 300.0
@export var respawn_time_max: float = 600.0

var _resource_nodes: Array[Node] = []
var _respawn_timers: Dictionary = {}

func register_resource_node(node: Node) -> void:
	if not _resource_nodes.has(node):
		_resource_nodes.append(node)

func unregister_resource_node(node: Node) -> void:
	_resource_nodes.erase(node)
	_respawn_timers.erase(node)

func gather_resource(node: Node, item_id: String, base_count: int = 1, tool_bonus: float = 1.0) -> int:
	var count = int(base_count * tool_bonus)
	count = max(1, count)

	resource_gathered.emit(node, item_id, count)

	var gather_count = _respawn_timers.get(node, {"gathers": 0})
	gather_count.gathers += 1

	if gather_count.gathers >= 3:
		deplete_resource(node)

	return count

func deplete_resource(node: Node) -> void:
	resource_depleted.emit(node)
	node.set_deferred("visible", false)
	node.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)

	var respawn_time = randf_range(respawn_time_min, respawn_time_max)
	_respawn_timers[node] = {"gathers": 0, "timer": respawn_time}

func _process(delta: float) -> void:
	for node in _respawn_timers:
		var data = _respawn_timers[node]
		if data.has("timer"):
			data.timer -= delta
			if data.timer <= 0:
				respawn_resource(node)

func respawn_resource(node: Node) -> void:
	if not is_instance_valid(node):
		_respawn_timers.erase(node)
		return

	node.set_deferred("visible", true)
	node.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
	_respawn_timers[node] = {"gathers": 0}
	resource_respawned.emit(node)

func get_resource_count() -> int:
	return _resource_nodes.size()

func get_active_resource_count() -> int:
	var count = 0
	for node in _resource_nodes:
		if is_instance_valid(node) and node.visible:
			count += 1
	return count

func serialize() -> Array[Dictionary]:
	var data = []
	for node in _resource_nodes:
		if is_instance_valid(node):
			data.append({
				"path": node.get_path(),
				"visible": node.visible,
				"gathers": _respawn_timers.get(node, {"gathers": 0}).gathers,
				"timer": _respawn_timers.get(node, {}).get("timer", 0.0)
			})
	return data

func deserialize(data: Array[Dictionary]) -> void:
	for entry in data:
		var node = get_node_or_null(entry.path)
		if node:
			node.visible = entry.visible
			var gathers = entry.get("gathers", 0)
			var timer = entry.get("timer", 0.0)
			if timer > 0:
				_respawn_timers[node] = {"gathers": gathers, "timer": timer}
			else:
				_respawn_timers[node] = {"gathers": gathers}