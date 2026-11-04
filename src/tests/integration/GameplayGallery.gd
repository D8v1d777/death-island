extends Node
## Six reproducible captures from the live game. Fixtures arrange encounters;
## actual input/system APIs perform the actions and verify their state changes.

var _player: Player
var _world: IslandWorld
var _evidence: Array[Dictionary] = []
var _folder := ""
var _failed := false
@onready var _capture_viewport: SubViewport = get_node("CaptureViewport")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveManagerGlobal.save_directory = "user://gallery-test-saves/"
	_folder = OS.get_environment("DEATH_ISLAND_GALLERY_DIR")
	if _folder.is_empty():
		_folder = "user://gallery"
	DirAccess.make_dir_recursive_absolute(_folder)

	call_deferred("_run")


func _run() -> void:
	print("GALLERY: Starting test...")
	seed(20261030)
	print("GALLERY: Calling new_game...")
	GameManagerGlobal.new_game()
	print("GALLERY: Waiting for loading...")
	while GameManagerGlobal.is_loading:
		await get_tree().process_frame
	print("GALLERY: Loading done, getting player...")
	_player = GameManagerGlobal.get_player()
	_world = GameManagerGlobal.world
	print("GALLERY: Player: %s, World: %s" % [_player, _world])
	_player.inventory_comp.add_item("stone_axe", 1)
	_player.inventory_comp.add_item("iron_blade", 1)
	print("GALLERY: Placing at wreckshore...")
	await _place(Vector3(1, 0.1, 45))
	print("GALLERY: Placed, moving right...")
	var initial := _player.global_position
	Input.action_press("move_right")
	await _frames(10)
	print("GALLERY: Capturing walk...")
	await _capture(
		"01-wreckshore-walk",
		"walk",
		{"moved_meters": _player.global_position.distance_to(initial)},
		_player.global_position.distance_to(initial) > 0.3
	)
	print("GALLERY: Walk capture done")
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

	await _place(Vector3(-19.5, 0.1, -39))
	_player.use_item("stone_axe")
	before = _player.inventory_comp.get_count("iron_ore")
	_player.perform_action("interact")
	await _capture(
		"05-cave-mining",
		"gather",
		{"ore_before": before, "ore_after": _player.inventory_comp.get_count("iron_ore")},
		_player.inventory_comp.get_count("iron_ore") > before
	)

	await _place(Vector3(-5, 0.1, 39))
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
	manifest.store_string(
		JSON.stringify(
			{
				"engine": Engine.get_version_info().string,
				"version": "0.3.0-dev",
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


func _capture(filename: String, action: String, evidence: Dictionary, valid: bool) -> void:
	print("GALLERY _capture: Starting for %s" % filename)
	# Wait for the action to start, with timeout
	var max_wait := 10
	var found := false
	for index in max_wait:
		await get_tree().process_frame
		if _player.illustration.action_name == action:
			found = true
			break
	if not found:
		# Give it one more frame
		await get_tree().process_frame
	print("GALLERY _capture: Frames awaited, checking validity...")
	if not valid or _player.illustration.action_name != action:
		printerr("FAIL: gallery action was not performed: " + filename)
		printerr("  valid=%s, action_name=%s, expected=%s" % [valid, _player.illustration.action_name, action])
		_failed = true
		return
	print("GALLERY _capture: Valid, getting root viewport image...")
	# Use the root viewport which has the player's camera rendering
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	print("GALLERY _capture: Got image, saving...")
	var error := image.save_webp(_folder.path_join(filename + ".webp"), true, 0.92)
	if error != OK:
		printerr("FAIL: gallery image could not be saved: " + filename)
		_failed = true
		return
	evidence["file"] = filename + ".webp"
	evidence["action"] = action
	evidence["sprite_frame"] = _player.illustration.body.frame
	evidence["player_position"] = StateValidation.array3(_player.global_position)
	_evidence.append(evidence)
	print("GALLERY _capture: Done for %s" % filename)
