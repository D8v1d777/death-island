class_name ResourceNode
extends StaticBody3D
## Gatherable node. Depletion commits only after inventory insertion succeeds.

signal gathered(item_id: String, count: int)
signal depleted

@export var item_id := "wood"
@export var base_count := 2
@export var required_tool := ""
@export var max_gathers := 4
@export var respawn_seconds := 180.0
@export var tint := Color("685844")
@export var form := "wood"

var _gathers := 0
var _is_depleted := false
var _respawn_timer := 0.0
var _gather_cooldown := 0.0


func _ready() -> void:
	collision_layer = 8
	collision_mask = 0
	add_to_group("interactables")
	ResourceSystemGlobal.register_resource_node(self)
	var art := item_id
	var height := 1.7
	if form == "tree":
		art = "tree"
		height = 7.0
		LowPoly.collision(self, Vector3(0.7, 3, 0.7), Vector3(0, 1.5, 0))
	else:
		var size := Vector3(1.4, 0.6, 1.0)
		if form == "ore":
			size.y = 1.4
		LowPoly.collision(self, size, Vector3(0, size.y / 2, 0))
	if item_id == "stone":
		art = "rock"
	elif item_id == "iron_ore":
		art = "ore"
	elif item_id == "fiber":
		art = "fern"
	IllustratedArt.sprite(self, art, height)


func _exit_tree() -> void:
	ResourceSystemGlobal.unregister_resource_node(self)


func _process(delta: float) -> void:
	_gather_cooldown = maxf(0, _gather_cooldown - delta)
	if _is_depleted:
		_respawn_timer -= delta
		if _respawn_timer <= 0:
			_gathers = 0
			_is_depleted = false
			_sync_visibility()


func can_interact() -> bool:
	return not _is_depleted


func get_interaction_text() -> String:
	return (
		"Gather "
		+ DataCatalogGlobal.item_name(item_id)
		+ (" · equip Stone Axe" if not required_tool.is_empty() else "")
	)


func interact(player: Player) -> bool:
	if _is_depleted or _gather_cooldown > 0:
		return false
	if not required_tool.is_empty() and not player.equipment_comp.has_working_tool(required_tool):
		GameManagerGlobal.message_posted.emit("Equip a working Stone Axe first.")
		return false
	var bonus := (
		2 if item_id == "wood" and player.equipment_comp.has_working_tool("stone_axe") else 1
	)
	var count := base_count * bonus
	if not player.inventory_comp.add_item(item_id, count):
		GameManagerGlobal.message_posted.emit("Inventory full. Use or drop supplies.")
		return false
	_gather_cooldown = 0.35
	player.face_point(global_position)
	player.illustration.play_action("gather")
	_gathers += 1
	if bonus > 1 or not required_tool.is_empty():
		player.equipment_comp.wear_weapon()
	if _gathers >= max_gathers:
		_is_depleted = true
		_respawn_timer = respawn_seconds
		_sync_visibility()
		depleted.emit()
	gathered.emit(item_id, count)
	ResourceSystemGlobal.resource_gathered.emit(self, item_id, count)
	GameManagerGlobal.message_posted.emit("+%d %s" % [count, DataCatalogGlobal.item_name(item_id)])
	AudioManagerGlobal.play_ui_sfx("gather")
	InputManagerGlobal.vibrate(20, 0.2)
	return true


func _sync_visibility() -> void:
	visible = not _is_depleted
	collision_layer = 0 if _is_depleted else 8


func serialize() -> Dictionary:
	return {"gathers": _gathers, "is_depleted": _is_depleted, "respawn_timer": _respawn_timer}


func deserialize(data: Dictionary) -> void:
	_gathers = clampi(int(data.get("gathers", 0)), 0, max_gathers)
	_is_depleted = data.get("is_depleted", false)
	_respawn_timer = clampf(float(data.get("respawn_timer", 0)), 0, respawn_seconds)
	_sync_visibility()
