class_name EquipmentComponent
extends Node
## Equipment references owned inventory items; condition survives re-equipping.

signal equipment_changed(slot: String, item_id: String)

const SLOTS: Array[String] = [
	"main_hand", "head", "chest", "hands", "feet", "accessory_1", "accessory_2"
]
const UNARMED_DAMAGE := 10.0
const SET_BONUS := 6.0

var _equipped: Dictionary = {}
var _condition: Dictionary = {}


func equip(item_id: String, inventory: InventoryComponent) -> bool:
	var item := DataCatalogGlobal.item(item_id)
	if not item or not item.equipment_slot in SLOTS or not inventory.has_item(item_id):
		return false
	_equipped[item.equipment_slot] = item_id
	if not _condition.has(item_id):
		_condition[item_id] = item.durability
	equipment_changed.emit(item.equipment_slot, item_id)
	return true


func get_equipped(slot: String = "main_hand") -> String:
	return _equipped.get(slot, "")


func condition(item_id: String) -> int:
	var item := DataCatalogGlobal.item(item_id)
	return int(_condition.get(item_id, item.durability if item else 0))


func has_working_tool(item_id: String) -> bool:
	return get_equipped() == item_id and condition(item_id) > 0


func attack_damage() -> float:
	var weapon := DataCatalogGlobal.item(get_equipped())
	if weapon and (weapon.durability == 0 or condition(weapon.item_id) > 0):
		return maxf(UNARMED_DAMAGE, weapon.damage)
	return UNARMED_DAMAGE


func wear_weapon() -> void:
	var weapon := DataCatalogGlobal.item(get_equipped())
	if weapon and weapon.durability > 0:
		_condition[weapon.item_id] = maxi(0, condition(weapon.item_id) - 1)
		equipment_changed.emit("main_hand", weapon.item_id)


func armor() -> float:
	var total := 0.0
	var hide_pieces := 0
	for key in _equipped.values():
		var item := DataCatalogGlobal.item(key)
		if item:
			total += item.armor
			if key.begins_with("hide_"):
				hide_pieces += 1
	return total + (SET_BONUS if hide_pieces == 3 else 0.0)


func repair(inventory: InventoryComponent) -> bool:
	var weapon := DataCatalogGlobal.item(get_equipped())
	if not weapon or weapon.durability <= 0 or condition(weapon.item_id) >= weapon.durability:
		return false
	var material := "iron_ingot" if weapon.item_id == "iron_blade" else "stone"
	if not inventory.remove_item(material, 1):
		return false
	_condition[weapon.item_id] = weapon.durability
	equipment_changed.emit("main_hand", weapon.item_id)
	return true


func reconcile(inventory: InventoryComponent) -> void:
	for slot in _equipped.keys():
		if not inventory.has_item(_equipped[slot]):
			_equipped.erase(slot)
			equipment_changed.emit(slot, "")


func serialize() -> Dictionary:
	return {"equipped": _equipped.duplicate(), "condition": _condition.duplicate()}


func deserialize(data: Dictionary) -> void:
	_equipped.clear()
	_condition.clear()
	var equipped: Dictionary = data.get("equipped", data)
	for slot in equipped:
		var item := DataCatalogGlobal.item(str(equipped[slot]))
		if item and item.equipment_slot == slot:
			_equipped[slot] = item.item_id
	var durability: Dictionary = data.get("condition", {})
	for key in durability:
		var item := DataCatalogGlobal.item(key)
		if item:
			_condition[key] = clampi(int(durability[key]), 0, item.durability)
	for slot in _equipped:
		equipment_changed.emit(slot, _equipped[slot])
