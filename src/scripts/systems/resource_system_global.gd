extends Node
## Registry indexed by stable authored node names, never absolute scene paths.

signal resource_gathered(node: Node, item_id: String, count: int)

var _nodes: Dictionary = {}


func get_resource(id: String) -> ResourceNode:
	return _nodes.get(id) as ResourceNode


func nearby_resources(at: Vector3, radius: float) -> Array[ResourceNode]:
	var result: Array[ResourceNode] = []
	for node: ResourceNode in _nodes.values():
		if node.global_position.distance_to(at) <= radius:
			result.append(node)
	result.sort_custom(
		func(a: ResourceNode, b: ResourceNode):
			return (
				a.global_position.distance_squared_to(at)
				< b.global_position.distance_squared_to(at)
			)
	)
	return result


func register_resource_node(node: ResourceNode) -> void:
	_nodes[str(node.name)] = node


func unregister_resource_node(node: ResourceNode) -> void:
	_nodes.erase(str(node.name))


func serialize() -> Dictionary:
	var result: Dictionary = {}
	for key in _nodes:
		result[key] = _nodes[key].serialize()
	return result


func deserialize(data: Dictionary) -> void:
	for key in data:
		if _nodes.has(key):
			_nodes[key].deserialize(data[key])
