extends Node
## Crafting commits ingredients and output in a single inventory transaction.

signal recipe_learned(recipe_id: String)
signal item_crafted(recipe_id: String, count: int)
signal craft_failed(reason: String)

var _known_recipes: Array[String] = []


func _ready() -> void:
	reset()


func reset() -> void:
	_known_recipes.clear()
	for recipe: RecipeDefinition in DataCatalogGlobal.recipes.values():
		if recipe.unlocked_at_start:
			_known_recipes.append(recipe.recipe_id)


func learn_recipe(recipe_id: String) -> bool:
	if not get_recipe(recipe_id) or is_recipe_known(recipe_id):
		return false
	_known_recipes.append(recipe_id)
	recipe_learned.emit(recipe_id)
	return true


func forget_recipe(recipe_id: String) -> void:
	_known_recipes.erase(recipe_id)


func is_recipe_known(recipe_id: String) -> bool:
	return recipe_id in _known_recipes


func get_known_recipes() -> Array[String]:
	return _known_recipes.duplicate()


func restore_known(recipes: Array) -> void:
	_known_recipes.clear()
	for key in recipes:
		if key is String:
			learn_recipe(key)


func get_recipe(recipe_id: String) -> RecipeDefinition:
	return DataCatalogGlobal.recipes.get(recipe_id) as RecipeDefinition


func preview(
	recipe_id: String, inventory: InventoryComponent, station: String = "", count: int = 1
) -> Dictionary:
	var recipe := get_recipe(recipe_id)
	if not recipe or not is_recipe_known(recipe_id) or not inventory:
		return {"success": false, "reason": "Recipe unavailable"}
	if count < 1 or count > 99:
		return {"success": false, "reason": "Invalid quantity"}
	if not recipe.required_station.is_empty() and recipe.required_station != station:
		return {"success": false, "reason": "Requires nearby " + recipe.required_station}
	return inventory.preview_exchange(
		recipe.costs(count), {recipe.result_item_id: recipe.result_count * count}
	)


func craft(
	recipe_id: String, inventory: InventoryComponent, station: String = "", count: int = 1
) -> Dictionary:
	var result := preview(recipe_id, inventory, station, count)
	if not result.success:
		craft_failed.emit(result.reason)
		return result
	var recipe := get_recipe(recipe_id)
	if not inventory.exchange(
		recipe.costs(count), {recipe.result_item_id: recipe.result_count * count}
	):
		return {"success": false, "reason": "Inventory changed"}
	item_crafted.emit(recipe_id, count)
	return {
		"success": true, "result_item": recipe.result_item_id, "count": recipe.result_count * count
	}
