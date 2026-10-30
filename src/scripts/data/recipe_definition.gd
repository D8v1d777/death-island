class_name RecipeDefinition
extends Resource
## Recipe ingredients are aggregated before validating a batch.

@export var recipe_id: String = ""
@export var display_name: String = ""
@export var category: String = "Crafting"
@export var ingredients: Array[Dictionary] = []
@export var result_item_id: String = ""
@export var result_count: int = 1
@export var required_station: String = ""
@export var unlocked_at_start: bool = true


func costs(count: int = 1) -> Dictionary:
	var result: Dictionary = {}
	for ingredient in ingredients:
		var key: String = ingredient.item_id
		result[key] = result.get(key, 0) + int(ingredient.count) * count
	return result


func can_craft(inventory: Dictionary, count: int = 1) -> bool:
	if count <= 0 or count > 99:
		return false
	var required := costs(count)
	for key in required:
		if int(inventory.get(key, 0)) < required[key]:
			return false
	return true
