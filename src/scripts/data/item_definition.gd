extends Resource
class_name ItemDefinition

enum ItemType {
	RESOURCE,
	TOOL,
	WEAPON,
	ARMOR,
	CONSUMABLE,
	QUEST,
	MISC
}

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

@export var item_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon_path: String = ""
@export var stack_size: int = 99
@export var weight: float = 0.1
@export var item_type: ItemType = ItemType.RESOURCE
@export var rarity: Rarity = Rarity.COMMON
@export var sell_price: int = 0

func _validate_property(property: String) -> bool:
	match property:
		"item_id":
			return item_id != ""
		"stack_size":
			return stack_size > 0
		"weight":
			return weight >= 0.0
		_:
			return true

func can_stack_with(other: ItemDefinition) -> bool:
	return other != null and item_id == other.item_id

func get_max_stack() -> int:
	return stack_size