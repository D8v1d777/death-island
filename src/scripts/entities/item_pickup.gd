class_name ItemPickup
extends Area3D
## Persistent bounded loot; failed collection leaves the pickup in the world.

@export var item_id := "wood"
@export var count := 1
var _collected := false


func _ready() -> void:
	collision_layer = 64
	collision_mask = 1
	add_to_group("interactables")
	add_to_group("pickups")
	IllustratedArt.sprite(self, "scrap", 0.65)
	LowPoly.collision(self, Vector3(1.5, 1.5, 1.5), Vector3(0, 0.5, 0))
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		interact(body)


func can_interact() -> bool:
	return not _collected


func get_interaction_text() -> String:
	return "Collect %d %s" % [count, DataCatalogGlobal.item_name(item_id)]


func interact(player: Player) -> bool:
	if _collected or not player.inventory_comp.add_item(item_id, count):
		return false
	_collected = true
	remove_from_group("pickups")
	remove_from_group("interactables")
	GameManagerGlobal.message_posted.emit("+%d %s" % [count, DataCatalogGlobal.item_name(item_id)])
	queue_free()
	return true


func serialize() -> Dictionary:
	return {"position": StateValidation.array3(global_position), "item_id": item_id, "count": count}
