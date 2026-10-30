extends Node
## Central read-only lookup of authored content.

const ITEM_PACK = preload("res://resources/definitions/items/Items.tres")
const RECIPE_PACK = preload("res://resources/definitions/recipes/Recipes.tres")
const ENEMY_PACK = preload("res://resources/definitions/enemies/Enemies.tres")

var items: Dictionary = {}
var recipes: Dictionary = {}
var enemies: Dictionary = {}
var art: ArtDefinition


func _ready() -> void:
	art = load("res://resources/definitions/Art.tres") as ArtDefinition
	for entry in ITEM_PACK.entries:
		items[entry.item_id] = entry
	for entry in RECIPE_PACK.entries:
		recipes[entry.recipe_id] = entry
	for entry in ENEMY_PACK.entries:
		enemies[entry.enemy_id] = entry


func item(item_id: String) -> ItemDefinition:
	return items.get(item_id) as ItemDefinition


func item_name(item_id: String) -> String:
	var definition := item(item_id)
	return definition.display_name if definition else item_id
