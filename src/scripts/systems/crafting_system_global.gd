extends Node

signal recipe_learned(recipe_id: String)
signal recipe_forgotten(recipe_id: String)
signal item_crafted(recipe_id: String, count: int)
signal craft_failed(reason: String)

@export var recipe_definitions_path: String = "res://resources/definitions/recipes/"

var _known_recipes: Array[String] = []
var _recipe_cache: Dictionary = {}

func _ready() -> void:
	_load_recipes()

func _load_recipes() -> void:
	var dir = DirAccess.open(recipe_definitions_path)
	if not dir:
		push_warning("Recipe directory not found: ", recipe_definitions_path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var recipe = ResourceLoader.load(recipe_definitions_path.path_join(file_name))
			if recipe and recipe is Resource and recipe.has_method("can_craft"):
				_recipe_cache[recipe.recipe_id] = recipe
		file_name = dir.get_next()
	dir.list_dir_end()

func learn_recipe(recipe_id: String) -> bool:
	if _known_recipes.has(recipe_id):
		return false

	if not _recipe_cache.has(recipe_id):
		push_warning("Unknown recipe: ", recipe_id)
		return false

	_known_recipes.append(recipe_id)
	recipe_learned.emit(recipe_id)
	return true

func forget_recipe(recipe_id: String) -> bool:
	if _known_recipes.has(recipe_id):
		_known_recipes.erase(recipe_id)
		recipe_forgotten.emit(recipe_id)
		return true
	return false

func is_recipe_known(recipe_id: String) -> bool:
	return _known_recipes.has(recipe_id)

func get_known_recipes() -> Array[String]:
	return _known_recipes.duplicate()

func get_recipe(recipe_id: String):
	return _recipe_cache.get(recipe_id)

func can_craft(recipe_id: String, inventory: Dictionary) -> bool:
	var recipe = _recipe_cache.get(recipe_id)
	if not recipe:
		return false

	if not _known_recipes.has(recipe_id):
		return false

	return recipe.can_craft(inventory)

func craft(recipe_id: String, inventory: Dictionary, count: int = 1) -> Dictionary:
	var recipe = _recipe_cache.get(recipe_id)
	if not recipe:
		craft_failed.emit("Recipe not found: " + recipe_id)
		return {"success": false, "reason": "Recipe not found"}

	if not _known_recipes.has(recipe_id):
		craft_failed.emit("Recipe not learned: " + recipe_id)
		return {"success": false, "reason": "Recipe not learned"}

	if not recipe.can_craft(inventory):
		craft_failed.emit("Insufficient ingredients")
		return {"success": false, "reason": "Insufficient ingredients"}

	var result = {"success": true, "result_item": recipe.result_item_id, "count": recipe.result_count * count}

	# Consume ingredients
	for i in range(count):
		recipe.consume_ingredients(inventory)

	item_crafted.emit(recipe_id, count)
	return result

func get_available_recipes(inventory: Dictionary) -> Array:
	var available = []
	for recipe_id in _known_recipes:
		var recipe = _recipe_cache.get(recipe_id)
		if recipe and recipe.can_craft(inventory):
			available.append(recipe)
	return available

func get_all_recipes() -> Array:
	var all = []
	for recipe_id in _recipe_cache:
		all.append(_recipe_cache[recipe_id])
	return all