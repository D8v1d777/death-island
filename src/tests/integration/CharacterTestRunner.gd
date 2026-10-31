extends Node
## Actual title selection, loaded textures, save restoration and live render evidence.

var _passed := 0
var _failed := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveManagerGlobal.save_directory = "user://character-test-saves/"
	call_deferred("_run")


func _check(value: bool, description: String) -> void:
	if value:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL: " + description)


func _run() -> void:
	GameManagerGlobal._ensure_ui()
	for id in ["dave", "marie"]:
		GameManagerGlobal.menu_requested.emit("main")
		await _frames(2)
		var choice := GameManagerGlobal.ui._content.get_node("CharacterChoice") as OptionButton
		var index := 0 if id == "dave" else 1
		choice.select(index)
		choice.item_selected.emit(index)
		for button in GameManagerGlobal.ui._content.find_children("*", "Button", true, false):
			if button.text == "New voyage":
				button.pressed.emit()
		while GameManagerGlobal.is_loading:
			await get_tree().process_frame
		await _frames(4)
		var player := GameManagerGlobal.get_player()
		_check(player.character_id == id, "title selection starts " + id)
		_check(player.illustration.art_key == id, "art identity " + id)
		_check(
			player.illustration.body.texture == DataCatalogGlobal.art.textures[id],
			"bound dedicated texture " + id
		)
		_check(player.illustration.body.hframes == 8, "eight atlas cells " + id)
		var atlas := player.illustration.body.texture.get_image()
		_check(
			atlas.get_pixel(0, 0).a == 0 and atlas.get_pixel(2047, 447).a == 0,
			"transparent strip corners " + id
		)
		_check(
			Vector2i(player.illustration.body.texture.get_size()) == Vector2i(2048, 448),
			"atlas dimensions " + id
		)
		for action in IllustratedActor.ACTION_FRAMES:
			player.illustration.play_action(action)
			_check(
				player.illustration.body.frame == IllustratedActor.ACTION_FRAMES[action],
				id + " maps supported pose " + action
			)
		player.illustration.play_action("attack")
		await _capture(id)
		_check(SaveManagerGlobal.save_game(0) == OK, "save selected " + id)
		GameManagerGlobal.load_game(0)
		while GameManagerGlobal.is_loading:
			await get_tree().process_frame
		player = GameManagerGlobal.get_player()
		_check(player.character_id == id, "restore selected " + id)
		_check(player.illustration.art_key == id, "restore displayed " + id)
		var legacy := player.serialize()
		legacy.erase("character_id")
		player.deserialize(legacy)
		_check(player.character_id == "dave", "legacy save uses default, not prior selection")
		player.set_character_id("invalid-id")
		_check(player.character_id == "dave", "unknown identity fallback")
		GameManagerGlobal.request_quit_to_main_menu()
		await _frames(2)
	_test_texture_fallback()
	await _test_text_and_aspects()
	SaveManagerGlobal.delete_save(0)
	SaveManagerGlobal.delete_save(SaveManagerGlobal.AUTOSAVE_SLOT)
	print("CHARACTERS: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(1 if _failed else 0)


func _test_texture_fallback() -> void:
	var textures := DataCatalogGlobal.art.textures
	var marie: Texture2D = textures.marie
	textures.erase("marie")
	_check(IllustratedActor.character_texture("marie") == textures.dave, "missing strip fallback")
	textures.marie = textures.rock
	_check(IllustratedActor.character_texture("marie") == textures.dave, "invalid size fallback")
	textures.marie = marie


func _test_text_and_aspects() -> void:
	var window := get_window()
	var original_size := window.size
	var original_scale: float = GameManagerGlobal.settings.text_scale
	GameManagerGlobal.new_game("marie")
	while GameManagerGlobal.is_loading:
		await get_tree().process_frame
	GameManagerGlobal.settings.text_scale = 1.3
	GameManagerGlobal.apply_settings()
	GameManagerGlobal.open_menu("crafting")
	for size in [Vector2i(1280, 720), Vector2i(1600, 720), Vector2i(1024, 768)]:
		window.size = size
		await _frames(3)
		var ui := GameManagerGlobal.ui as HUD
		var header := ui._content.get_child(0).get_child(0) as Label
		_check(header.get_theme_font_size("font_size") == 42, "text scaling updates header")
		var area := ui._modal.get_global_rect()
		_check(get_viewport().get_visible_rect().encloses(area), "modal fits aspect " + str(size))
		var back := ui._content.get_child(0).get_child(1) as Button
		_check(back.size.x >= 117, "scaled button leaves room for its label")
		await _capture("ui-%dx%d" % [size.x, size.y])
	window.size = original_size
	GameManagerGlobal.settings.text_scale = original_scale
	GameManagerGlobal.apply_settings()
	GameManagerGlobal.request_quit_to_main_menu()
	await _frames(2)


func _frames(count: int) -> void:
	for index in count:
		await get_tree().process_frame


func _capture(id: String) -> void:
	await RenderingServer.frame_post_draw
	var folder := OS.get_environment("DEATH_ISLAND_CAPTURE_DIR")
	if folder.is_empty():
		folder = "user://character-captures"
	DirAccess.make_dir_recursive_absolute(folder)
	_check(
		(
			get_viewport().get_texture().get_image().save_png(
				folder.path_join("character-" + id + ".png")
			)
			== OK
		),
		"saved actual gameplay character snapshot " + id
	)
