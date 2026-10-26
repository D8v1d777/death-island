extends Node
class_name InventoryComponent

signal inventory_changed
signal item_added(item_id: String, count: int)
signal item_removed(item_id: String, count: int)
signal capacity_reached

@export var max_slots: int = 20
@export var max_weight: float = 100.0

var _items: Dictionary = {}  # item_id -> count
var _item_weights: Dictionary = {}  # item_id -> weight per unit

func _ready() -> void:
	# Initialize from saved data if needed
	pass

func can_add_item(item_id: String, count: int = 1, weight_per_unit: float = 0.1) -> bool:
	if item_id.is_empty() or count <= 0 or weight_per_unit < 0.0:
		return false
	var current_count = int(_items.get(item_id, 0))
	var new_slot = 0 if current_count > 0 else 1
	if get_used_slots() + new_slot > max_slots:
		return false
	return get_current_weight() + float(count) * weight_per_unit <= max_weight + 0.0001

func add_item(item_id: String, count: int = 1, weight_per_unit: float = 0.1) -> bool:
	if not can_add_item(item_id, count, weight_per_unit):
		if item_id.is_empty() or count <= 0 or weight_per_unit < 0.0 or get_used_slots() >= max_slots:
			capacity_reached.emit()
		return false

	var current_count = int(_items.get(item_id, 0))

	_items[item_id] = current_count + count
	_item_weights[item_id] = weight_per_unit
	inventory_changed.emit()
	item_added.emit(item_id, count)
	return true

func remove_item(item_id: String, count: int = 1) -> bool:
	if item_id.is_empty() or count <= 0:
		return false
	var current_count = int(_items.get(item_id, 0))
	if current_count < count:
		return false

	_items[item_id] = current_count - count
	if _items[item_id] <= 0:
		_items.erase(item_id)
		_item_weights.erase(item_id)

	inventory_changed.emit()
	item_removed.emit(item_id, count)
	return true

func has_item(item_id: String, count: int = 1) -> bool:
	return _items.get(item_id, 0) >= count

func get_count(item_id: String) -> int:
	return _items.get(item_id, 0)

func get_used_slots() -> int:
	return _items.size()

func get_current_weight() -> float:
	var total = 0.0
	for item_id in _items:
		total += _items[item_id] * _item_weights.get(item_id, 0.1)
	return total

func get_remaining_weight() -> float:
	return max_weight - get_current_weight()

func get_remaining_slots() -> int:
	return max_slots - get_used_slots()

func is_full() -> bool:
	return get_used_slots() >= max_slots or get_current_weight() >= max_weight

func get_all_items() -> Dictionary:
	return _items.duplicate()

func clear() -> void:
	_items.clear()
	_item_weights.clear()
	inventory_changed.emit()

func serialize() -> Dictionary:
	var data = {}
	for item_id in _items:
		data[item_id] = {
			"count": _items[item_id],
			"weight": _item_weights.get(item_id, 0.1)
		}
	return data

func deserialize(data: Dictionary) -> void:
	_items.clear()
	_item_weights.clear()
	for item_id in data:
		var item_data = data[item_id]
		var count := int(item_data.get("count", 0)) if item_data is Dictionary else int(item_data)
		var weight := float(item_data.get("weight", 0.1)) if item_data is Dictionary else 0.1
		if str(item_id).is_empty() or count <= 0 or weight < 0.0:
			push_warning("Ignoring invalid saved inventory entry: %s" % str(item_id))
			continue
		if _items.size() >= max_slots or get_current_weight() + count * weight > max_weight + 0.0001:
			push_warning("Ignoring saved inventory entry that exceeds capacity: %s" % str(item_id))
			continue
		_items[item_id] = count
		_item_weights[item_id] = weight
	inventory_changed.emit()