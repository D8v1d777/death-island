extends Node
## Run under Xvfb with OpenGL; this exercises the real renderer, not the dummy one.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveManagerGlobal.save_directory = "user://render-test-saves/"
	call_deferred("_run")


func _run() -> void:
	GameManagerGlobal._ensure_ui()
	GameManagerGlobal.menu_requested.emit("main")
	await _capture("title")
	GameManagerGlobal.new_game()
	while GameManagerGlobal.is_loading:
		await get_tree().process_frame
	for frame in 8:
		await get_tree().process_frame
	await _capture("island")
	var player := GameManagerGlobal.get_player()
	player.inventory_comp.add_item("wood", 5)
	player.inventory_comp.add_item("stone", 5)
	GameManagerGlobal.open_menu("crafting")
	await _capture("crafting")
	GameManagerGlobal.open_menu("dialogue")
	await _capture("dialogue")
	print("RENDER: title, island, crafting and dialogue captured")
	get_tree().quit(0)


func _capture(label: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var folder := OS.get_environment("DEATH_ISLAND_CAPTURE_DIR")
	if folder.is_empty():
		folder = "user://screenshots"
	DirAccess.make_dir_recursive_absolute(folder)
	var result := get_viewport().get_texture().get_image().save_png(
		folder.path_join(label + ".png")
	)
	if result != OK:
		printerr("Screenshot write failed: " + label)
		get_tree().quit(1)
