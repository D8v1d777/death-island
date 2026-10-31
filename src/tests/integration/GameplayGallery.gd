extends Node
## Six reproducible captures from the live game. Fixtures arrange encounters;
## actual input/system APIs perform the actions and verify their state changes.

var _player: Player
var _world: IslandWorld
var _evidence: Array[Dictionary] = []
var _folder := ""
var _failed := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() == "headless":
		printerr("FAIL: gallery requires live OpenGL rendering")
		get_tree().quit(1)
		return
	SaveManagerGlobal.save_directory = "user://gallery-test-saves/"
	_folder = OS.get_environment("DEATH_ISLAND_GALLERY_DIR")
	if _folder.is_empty():
		_folder = "user://gallery"
	DirAccess.make_dir_recursive_absolute(_folder)
	call_deferred("_run")


func _run() -> void:
	seed(20261030)
	GameManagerGlobal.new_game("dave")
	while GameManagerGlobal.is_loading:
		await get_tree().process_frame
	_player = GameManagerGlobal.get_player()
	_world = GameManagerGlobal.world
	_player.inventory_comp.add_item("stone_axe", 1)
	_player.inventory_comp.add_item("iron_blade", 1)
	await _place(Vector3(1, 0.1, 45))
	var initial := _player.global_position
	Input.action_press("move_right")
	await _frames(10)
	await _capture(
		"01-wreckshore-walk",
		"walk",
		{"moved_meters": _player.global_position.distance_to(initial)},
		_player.global_position.distance_to(initial) > 0.3
	)
	Input.action_release("move_right")

	await _place(Vector3(-18, 0.1, 8.8))
	_player.use_item("stone_axe")
	var before := _player.inventory_comp.get_count("wood")
	_player.perform_action("interact")
	await _capture(
		"02-jungle-gather",
		"gather",
		{"wood_before": before, "wood_after": _player.inventory_comp.get_count("wood")},
		_player.inventory_comp.get_count("wood") > before
	)

	await _place(Vector3(25.5, 0.1, 22))
	var enemy := _world.get_node("boar_shore") as Enemy
	enemy.global_position = _player.global_position + Vector3.RIGHT * 2
	_player.use_item("iron_blade")
	_player._facing = Vector3.RIGHT
	await _frames(2)
	var enemy_health := enemy.health_comp.current_health
	_player.perform_action("attack_light")
	await _capture(
		"03-boar-combat",
		"attack",
		{
			"enemy_health_before": enemy_health,
			"enemy_health_after": enemy.health_comp.current_health
		},
		enemy.health_comp.current_health < enemy_health
	)

	await _place(Vector3(2, 0.1, 35))
	Input.action_press("move_left")
	await _frames(4)
	Input.action_release("move_left")
	_player.inventory_comp.add_item("campfire_kit", 1)
	_player.use_item("campfire_kit")
	Input.action_press("move_left")
	await _frames(4)
	Input.action_release("move_left")
	_player.inventory_comp.add_item("raw_meat", 1)
	GameManagerGlobal.craft("cooked_meat")
	await _capture(
		"04-campfire-cooking",
		"cook",
		{"cooked_meat": _player.inventory_comp.get_count("cooked_meat")},
		_player.inventory_comp.has_item("cooked_meat")
	)

	await _place(Vector3(2, 0.1, 35))
	_player.inventory_comp.add_item("wood", 6)
	_player.inventory_comp.add_item("stone", 6)
	GameManagerGlobal.open_menu("inventory")
	await _frames(2)
	for button in GameManagerGlobal.ui._content.find_children("*", "Button", true, false):
		if button.text == "Craft from this inventory":
			button.pressed.emit()
	await _frames(2)
	before = _player.inventory_comp.get_count("stone_axe")
	GameManagerGlobal.craft("stone_axe")
	GameManagerGlobal.ui._scroll.scroll_vertical = 0
	await _capture(
		"05-inventory-crafting",
		"craft",
		{"axes_before": before, "axes_after": _player.inventory_comp.get_count("stone_axe")},
		_player.inventory_comp.get_count("stone_axe") == before + 1,
		"crafting"
	)
	GameManagerGlobal.resume_game()

	await _place(Vector3(-9, 0.1, 39))
	Input.action_press("move_right")
	await _frames(4)
	Input.action_release("move_right")
	var built := 0
	for part in ["foundation", "wall", "roof", "door"]:
		_player.inventory_comp.add_item(part + "_kit", 1)
		if _player.use_item(part + "_kit"):
			built += 1
	await _capture("06-shelter-building", "build", {"shelter_parts_built": built}, built == 4)

	var manifest := FileAccess.open(_folder.path_join("gallery.json"), FileAccess.WRITE)
	if not manifest:
		printerr("FAIL: gallery manifest could not be saved")
		get_tree().quit(1)
		return
	manifest.store_string(
		JSON.stringify(
			{
				"engine": Engine.get_version_info().string,
				"version": "0.3.0-dev",
				"source_revision": OS.get_environment("DEATH_ISLAND_SOURCE_REVISION"),
				"seed": 20261030,
				"character_id": _player.character_id,
				"method": "Live Godot OpenGL; encounter/inventory fixtures; real gameplay actions.",
				"captures": _evidence
			},
			"\t"
		)
	)
	manifest.close()
	SaveManagerGlobal.delete_save(SaveManagerGlobal.AUTOSAVE_SLOT)
	print("GALLERY: %d actual gameplay images; failures: %s" % [_evidence.size(), _failed])
	get_tree().quit(1 if _failed or _evidence.size() != 6 else 0)


func _frames(count: int) -> void:
	for index in count:
		await get_tree().physics_frame


func _place(at: Vector3) -> void:
	_player.global_position = at
	_player.velocity = Vector3.ZERO
	await _frames(12)
	_world._update_region()


func _capture(
	filename: String, action: String, evidence: Dictionary, valid: bool, menu: String = ""
) -> void:
	for index in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if (
		not valid
		or _player.illustration.action_name != action
		or GameManagerGlobal.is_loading
		or GameManagerGlobal.ui._menu != menu
		or not _player.illustration.body.texture
		or _player.health_comp.is_dead()
	):
		printerr("FAIL: gallery action was not performed: " + filename)
		_failed = true
		return
	var image := get_viewport().get_texture().get_image()
	var error := image.save_webp(_folder.path_join(filename + ".webp"), true, 0.92)
	if error != OK:
		printerr("FAIL: gallery image could not be saved: " + filename)
		_failed = true
		return
	evidence["file"] = filename + ".webp"
	evidence["sha256"] = FileAccess.get_sha256(_folder.path_join(filename + ".webp"))
	evidence["action"] = action
	evidence["scenario"] = filename
	evidence["validated"] = true
	evidence["menu"] = menu
	evidence["character_id"] = _player.character_id
	evidence["texture"] = _player.illustration.body.texture.resource_path
	evidence["dimensions"] = [image.get_width(), image.get_height()]
	evidence["sprite_frame"] = _player.illustration.body.frame
	evidence["player_position"] = StateValidation.array3(_player.global_position)
	_evidence.append(evidence)
