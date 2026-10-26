extends Resource
class_name RecipeDefinition

@export var recipe_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var category: String = "Crafting"
@export var ingredients: Array[Dictionary] = []  # [{"item_id": "wood", "count": 2}, ...]
@export var result_item_id: String = ""
@export var result_count: int = 1
@export var crafting_time: float = 1.0
@export var required_station: String = ""  # Empty = no station required
@export var experience_reward: int = 0

func _validate_property(property: Dictionary) -> void:
	var name = property.name
	match name:
		"recipe_id":
			property.usage = PROPERTY_USAGE_DEFAULT if recipe_id != "" else PROPERTY_USAGE_NO_EDITOR
		"ingredients":
			for ing in ingredients:
				if not ing.has("item_id") or not ing.has("count") or ing.count <= 0:
					property.usage = PROPERTY_USAGE_NO_EDITOR
					return
			property.usage = PROPERTY_USAGE_DEFAULT
		"result_count":
			property.usage = PROPERTY_USAGE_DEFAULT if result_count > 0 else PROPERTY_USAGE_NO_EDITOR
		"crafting_time":
			property.usage = PROPERTY_USAGE_DEFAULT if crafting_time > 0.0 else PROPERTY_USAGE_NO_EDITOR
		_:
			property.usage = PROPERTY_USAGE_DEFAULT

func can_craft(inventory: Dictionary) -> bool:
	for ing in ingredients:
		var available = inventory.get(ing.item_id, 0)
		if available < ing.count:
			return false
	return true

func consume_ingredients(inventory: Dictionary) -> void:
	for ing in ingredients:
		inventory[ing.item_id] = inventory.get(ing.item_id, 0) - ing.count
		if inventory[ing.item_id] <= 0:
			inventory.erase(ing.item_id)