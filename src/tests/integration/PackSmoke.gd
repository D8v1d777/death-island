extends SceneTree
## External script for validating an exported ARM64 runtime and its packed content.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var manager: Node = root.get_node("GameManagerGlobal")
	var saves: Node = root.get_node("SaveManagerGlobal")
	saves.save_directory = "user://pack-test-saves/"
	manager.new_game()
	while manager.is_loading:
		await process_frame
	await process_frame
	await process_frame
	var player: Node = manager.get_player()
	if not player:
		printerr("FAIL: exported runtime did not create a player")
		quit(1)
		return
	var inventory: Node = player.get_node("InventoryComponent")
	inventory.add_item("wood", 2)
	inventory.add_item("stone", 3)
	var crafting: Node = root.get_node("CraftingSystemGlobal")
	var result: Dictionary = crafting.craft("stone_axe", inventory)
	if not result.success or not inventory.has_item("stone_axe") or manager.save(0, false) != OK:
		printerr("FAIL: exported crafting/save failed")
		quit(1)
		return
	if saves.load_game(0).is_empty():
		printerr("FAIL: exported save could not be read")
		quit(1)
		return
	saves.delete_save(0)
	manager.request_quit_to_main_menu()
	await process_frame
	await process_frame
	saves.delete_save(-2)
	print("PACK: exported runtime loads island, crafts and round-trips a save")
	quit(0)
