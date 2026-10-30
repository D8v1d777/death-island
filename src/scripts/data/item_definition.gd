class_name ItemDefinition
extends Resource
## Immutable item content, shared by inventory, crafting and equipment.

enum ItemType { RESOURCE, TOOL, WEAPON, ARMOR, CONSUMABLE, QUEST, MISC }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export var item_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var stack_size: int = 99
@export var weight: float = 0.1
@export var item_type: ItemType = ItemType.RESOURCE
@export var rarity: Rarity = Rarity.COMMON
@export var damage: float = 0.0
@export var armor: float = 0.0
@export var durability: int = 0
@export var equipment_slot: String = ""
@export var hunger: float = 0.0
@export var thirst: float = 0.0
@export var healing: float = 0.0
@export var structure: String = ""


func can_stack_with(other: ItemDefinition) -> bool:
	return other != null and item_id == other.item_id


func get_max_stack() -> int:
	return stack_size
