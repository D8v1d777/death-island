extends Node
## Centralized base storage for NPC role operations.
## Transactional inventory with capacity limits, used by Farmer, Gatherer, etc.

signal storage_changed
signal transaction_failed(reason: String)

const MAX_STACKS := 30
const MAX_WEIGHT := 200.0

var inventory: InventoryComponent
var _transaction_active := false
var _reserved_items: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	inventory = InventoryComponent.new()
	inventory.max_slots = MAX_STACKS
	inventory.max_weight = MAX_WEIGHT
	add_child(inventory)
	inventory.inventory_changed.connect(_on_inventory_changed)
	_connect_lifecycle.call_deferred()


func _connect_lifecycle() -> void:
	GameManagerGlobal.game_ready.connect(_on_game_ready)


func _on_game_ready() -> void:
	# Initialize with some starter items if empty
	if inventory.get_used_slots() == 0:
		_add_starter_items()


func _add_starter_items() -> void:
	inventory.add_item("potato_seed", 5)
	inventory.add_item("corn_seed", 3)
	inventory.add_item("tomato_seed", 3)
	inventory.add_item("herb_seed", 5)
	inventory.add_item("water", 20)
	inventory.add_item("hoe", 1)
	inventory.add_item("watering_can", 1)


func _on_inventory_changed() -> void:
	if not _transaction_active:
		storage_changed.emit()


func has_item(item_id: String, count: int = 1) -> bool:
	return inventory.has_item(item_id, count)


func get_count(item_id: String) -> int:
	return inventory.get_count(item_id)


func get_all_items() -> Dictionary:
	return inventory.get_all_items()


func get_current_weight() -> float:
	return inventory.get_current_weight()


func get_used_slots() -> int:
	return inventory.get_used_slots()


# Transactional operations for NPC roles
func begin_transaction() -> bool:
	if _transaction_active:
		transaction_failed.emit("Transaction already active")
		return false
	_transaction_active = true
	_reserved_items.clear()
	return true


func reserve(item_id: String, count: int) -> bool:
	if not _transaction_active:
		transaction_failed.emit("No active transaction")
		return false
	var available := inventory.get_count(item_id)
	var already_reserved: int = _reserved_items.get(item_id, 0)
	if available - already_reserved < count:
		transaction_failed.emit("Insufficient " + item_id + " in base storage")
		return false
	_reserved_items[item_id] = already_reserved + count
	return true


func commit() -> bool:
	if not _transaction_active:
		transaction_failed.emit("No active transaction")
		return false
	for item_id in _reserved_items:
		var count: int = _reserved_items[item_id]
		if not inventory.remove_item(item_id, count):
			# Rollback
			rollback()
			transaction_failed.emit("Failed to remove " + item_id)
			return false
	_transaction_active = false
	_reserved_items.clear()
	storage_changed.emit()
	return true


func rollback() -> void:
	_transaction_active = false
	_reserved_items.clear()


func add_item(item_id: String, count: int = 1) -> bool:
	if _transaction_active:
		transaction_failed.emit("Cannot add during transaction")
		return false
	var result := inventory.add_item(item_id, count)
	if result:
		storage_changed.emit()
	return result


func remove_item(item_id: String, count: int = 1) -> bool:
	if _transaction_active:
		transaction_failed.emit("Cannot remove during transaction")
		return false
	var result := inventory.remove_item(item_id, count)
	if result:
		storage_changed.emit()
	return result


func transfer_to_player(item_id: String, count: int, player_inventory: InventoryComponent) -> int:
	var available := inventory.get_count(item_id)
	var to_transfer := mini(available, count)
	if to_transfer <= 0:
		return 0
	var transferred := 0
	for i in range(to_transfer):
		if inventory.remove_item(item_id, 1):
			if player_inventory.add_item(item_id, 1):
				transferred += 1
			else:
				# Put back
				inventory.add_item(item_id, 1)
				break
	if transferred > 0:
		storage_changed.emit()
	return transferred


func transfer_from_player(item_id: String, count: int, player_inventory: InventoryComponent) -> int:
	var available := player_inventory.get_count(item_id)
	var to_transfer := mini(available, count)
	if to_transfer <= 0:
		return 0
	var transferred := 0
	for i in range(to_transfer):
		if player_inventory.remove_item(item_id, 1):
			if inventory.add_item(item_id, 1):
				transferred += 1
			else:
				player_inventory.add_item(item_id, 1)
				break
	if transferred > 0:
		storage_changed.emit()
	return transferred


func serialize() -> Dictionary:
	return {"inventory": inventory.serialize()}


func deserialize(data: Dictionary) -> void:
	if data.has("inventory"):
		inventory.deserialize(data.inventory)
