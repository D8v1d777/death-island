extends Node
class_name EquipmentComponent

signal equipment_changed(slot: String, item_id: String)

enum EquipSlot {
	MAIN_HAND,
	OFF_HAND,
	HEAD,
	CHEST,
	LEGS,
	FEET,
	ACCESSORY_1,
	ACCESSORY_2
}

var _equipped: Dictionary = {}

func _ready() -> void:
	for slot in EquipSlot:
		_equipped[slot] = ""

func equip(slot: EquipSlot, item_id: String) -> bool:
	if _equipped.has(slot):
		_equipped[slot] = item_id
		equipment_changed.emit(_enum_to_string(slot), item_id)
		return true
	return false

func unequip(slot: EquipSlot) -> String:
	var old_item = _equipped.get(slot, "")
	if old_item != "":
		_equipped[slot] = ""
		equipment_changed.emit(_enum_to_string(slot), "")
	return old_item

func get_equipped(slot: EquipSlot) -> String:
	return _equipped.get(slot, "")

func has_equipped(slot: EquipSlot) -> bool:
	return _equipped.get(slot, "") != ""

func get_all_equipped() -> Dictionary:
	return _equipped.duplicate()

func _enum_to_string(slot: EquipSlot) -> String:
	match slot:
		EquipSlot.MAIN_HAND: return "main_hand"
		EquipSlot.OFF_HAND: return "off_hand"
		EquipSlot.HEAD: return "head"
		EquipSlot.CHEST: return "chest"
		EquipSlot.LEGS: return "legs"
		EquipSlot.FEET: return "feet"
		EquipSlot.ACCESSORY_1: return "accessory_1"
		EquipSlot.ACCESSORY_2: return "accessory_2"
		_: return ""

func serialize() -> Dictionary:
	var data = {}
	for slot in _equipped:
		if _equipped[slot] != "":
			data[_enum_to_string(slot)] = _equipped[slot]
	return data

func deserialize(data: Dictionary) -> void:
	for slot_name in data:
		var slot = _string_to_enum(slot_name)
		if slot != -1:
			_equipped[slot] = data[slot_name]
	for slot in _equipped:
		equipment_changed.emit(_enum_to_string(slot), _equipped[slot])

func _string_to_enum(name: String) -> int:
	match name:
		"main_hand": return EquipSlot.MAIN_HAND
		"off_hand": return EquipSlot.OFF_HAND
		"head": return EquipSlot.HEAD
		"chest": return EquipSlot.CHEST
		"legs": return EquipSlot.LEGS
		"feet": return EquipSlot.FEET
		"accessory_1": return EquipSlot.ACCESSORY_1
		"accessory_2": return EquipSlot.ACCESSORY_2
		_: return -1