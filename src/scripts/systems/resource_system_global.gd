extends Node
## Registry indexed by stable authored node names, never absolute scene paths.

signal resource_gathered(node: Node, item_id: String, count: int)

var _nodes: Dictionary = {}


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
