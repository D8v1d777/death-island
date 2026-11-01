extends SceneTree
## External harness: executes the extracted export, using only its packed resources.

var _passed := 0
var _failed := 0
var _manager: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_manager = root.get_node("GameManagerGlobal")
	var saves: Node = root.get_node("SaveManagerGlobal")
	saves.save_directory = "user://pack-test-saves/"
	_check(OS.has_feature("template"), "running exported template, not editor")
	_check(
		not FileAccess.file_exists("res://tests/integration/PackSmoke.gd"),
		"tests excluded from pack"
	)
	if DisplayServer.get_name() == "headless":
		printerr("FAIL: exported verification requires actual rendering")
		quit(1)
		return
	_manager._ensure_ui()
	for identity in ["dave", "marie"]:
		_manager.menu_requested.emit("main")
		await _frames(3)
		var choice: OptionButton = _manager.ui._content.get_node("CharacterChoice")
		_check(choice.item_count == 2, "two packed title choices")
		_check(choice.get_item_metadata(choice.selected) == "dave", "packed Dave default")
		var index := 0 if identity == "dave" else 1
		choice.select(index)
		choice.item_selected.emit(index)
		await _capture("title-" + identity)
		_check(_press("New voyage"), "packed New voyage button")
		while _manager.is_loading:
			await process_frame
		await _frames(8)
		var player: Node = _manager.get_player()
		_check(player != null, "packed gameplay loads")
		_check(player.character_id == identity, "packed selected identity " + identity)
		_check(player.illustration.art_key == identity, "packed illustrated identity " + identity)
		_check(player.illustration.body.texture != null, "packed character texture")
		_check(_manager.ui._status.text.begins_with(identity.to_upper()), "packed HUD identity")
		await _capture("gameplay-" + identity)
		var start: Vector3 = player.global_position
		Input.action_press("move_right")
		await _frames(12)
		Input.action_release("move_right")
		_check(player.global_position.distance_to(start) > 0.3, "packed movement")
		var inventory: Node = player.get_node("InventoryComponent")
		inventory.add_item("wood", 2)
		inventory.add_item("stone", 3)
		var crafting: Node = root.get_node("CraftingSystemGlobal")
		_check(crafting.craft("stone_axe", inventory).success, "packed crafting")
		_check(inventory.has_item("stone_axe"), "packed crafted item")
		_manager.open_menu("pause")
		await _frames(3)
		var other := "Marie" if identity == "dave" else "Dave"
		_check(_press("Switch to " + other), "packed switch button")
		await _frames(8)
		_check(_manager.get_player().character_id == other.to_lower(), "packed switch identity")
		await _capture("switched-" + other.to_lower())
		_check(_manager.save(0, false) == OK, "packed switched save")
		_check(_manager.load_game(0), "packed load request")
		while _manager.is_loading:
			await process_frame
		_check(_manager.get_player().character_id == other.to_lower(), "packed loaded identity")
		_check(_manager.switch_character(identity), "packed switch back after reload")
		_check(
			_manager.get_player().inventory_comp.has_item("stone_axe"),
			"packed inactive inventory persisted"
		)
		_manager.request_quit_to_main_menu()
		await _frames(3)
	print("PACK: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed else 0)


func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL: " + description)


func _press(title: String) -> bool:
	for button in _manager.ui._content.find_children("*", "Button", true, false):
		if button.text == title:
			button.pressed.emit()
			return true
	return false


func _frames(count: int) -> void:
	for index in count:
		await process_frame


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image != null and image.get_size() == Vector2i(1280, 720), "packed rendered viewport")
	var directory := OS.get_environment("DEATH_ISLAND_CAPTURE_DIR")
	DirAccess.make_dir_recursive_absolute(directory)
	_check(
		image.save_png(directory.path_join("export-" + label + ".png")) == OK,
		"packed screenshot " + label
	)
