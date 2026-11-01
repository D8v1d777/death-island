class_name InventoryComponent
extends Node
## Stack-aware, weight-bounded inventory with atomic exchanges.

signal inventory_changed
signal item_added(item_id: String, count: int)
signal item_removed(item_id: String, count: int)
signal capacity_reached

@export var max_slots: int = 24
@export var max_weight: float = 100.0

var _items: Dictionary = {}


func add_item(item_id: String, count: int = 1) -> bool:
	return exchange({}, {item_id: count})


func remove_item(item_id: String, count: int = 1) -> bool:
	return exchange({item_id: count}, {})


func preview_exchange(costs: Dictionary, rewards: Dictionary) -> Dictionary:
	var next := _items.duplicate()
	for key in costs:
		if not _valid_count(costs[key]) or not has_item(key, int(costs[key])):
			return {"success": false, "reason": "Missing materials"}
		next[key] -= int(costs[key])
		if next[key] == 0:
			next.erase(key)
	for key in rewards:
		if not DataCatalogGlobal.item(key) or not _valid_count(rewards[key]):
			return {"success": false, "reason": "Invalid item"}
		next[key] = int(next.get(key, 0)) + int(rewards[key])
	if not _fits(next):
		return {"success": false, "reason": "Inventory capacity reached"}
	return {"success": true, "items": next}


func exchange(costs: Dictionary, rewards: Dictionary) -> bool:
	var result := preview_exchange(costs, rewards)
	if not result.success:
		capacity_reached.emit()
		return false
	_items = result.items
	inventory_changed.emit()
	for key in costs:
		item_removed.emit(key, int(costs[key]))
	for key in rewards:
		item_added.emit(key, int(rewards[key]))
	return true


func has_item(item_id: String, count: int = 1) -> bool:
	return count > 0 and get_count(item_id) >= count


func transfer_to(destination: InventoryComponent, item_id: String, count: int) -> bool:
	if not is_instance_valid(destination) or destination == self:
		return false
	var source_result := preview_exchange({item_id: count}, {})
	var target_result := destination.preview_exchange({}, {item_id: count})
	if not source_result.success or not target_result.success:
		return false
	# Commit both sides before notifying observers (including autosave/UI callbacks).
	_items = source_result.items
	destination._items = target_result.items
	inventory_changed.emit()
	destination.inventory_changed.emit()
	item_removed.emit(item_id, count)
	destination.item_added.emit(item_id, count)
	return true


func get_count(item_id: String) -> int:
	return int(_items.get(item_id, 0))


func get_used_slots() -> int:
	return _slots_for(_items)


func get_current_weight() -> float:
	return _weight_for(_items)


func get_all_items() -> Dictionary:
	return _items.duplicate()


func clear() -> void:
	_items.clear()
	inventory_changed.emit()


func serialize() -> Dictionary:
	return get_all_items()


func deserialize(data: Dictionary) -> bool:
	var next: Dictionary = {}
	if data.size() > DataCatalogGlobal.items.size():
		return false
	for key in data:
		var value: Variant = data[key]
		if value is Dictionary:
			value = value.get("count", 0)
		if not DataCatalogGlobal.item(key) or not _valid_count(value):
			return false
		next[key] = int(value)
	if not _fits(next):
		return false
	_items = next
	inventory_changed.emit()
	return true


func _valid_count(value: Variant) -> bool:
	return (
		(value is int or value is float)
		and is_finite(float(value))
		and value > 0
		and value <= 9999
		and float(value) == floorf(float(value))
	)


func _fits(items: Dictionary) -> bool:
	return _slots_for(items) <= max_slots and _weight_for(items) <= max_weight


func _slots_for(items: Dictionary) -> int:
	var total := 0
	for key in items:
		var definition := DataCatalogGlobal.item(key)
		if not definition:
			return max_slots + 1
		total += ceili(float(items[key]) / definition.stack_size)
	return total


func _weight_for(items: Dictionary) -> float:
	var total := 0.0
	for key in items:
		var definition := DataCatalogGlobal.item(key)
		if not definition:
			return INF
		total += int(items[key]) * definition.weight
	return total
