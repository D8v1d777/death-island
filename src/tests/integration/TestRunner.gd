extends Node

var _tests_passed: int = 0
var _tests_failed: int = 0

func _ready() -> void:
	_run_all_tests()
	get_tree().quit(1 if _tests_failed > 0 else 0)

func _run_test(test_name: String, test_func: Callable) -> void:
	print("--- %s ---" % test_name)
	var result = test_func.call()
	if result is bool and result:
		_tests_passed += 1
		print("  PASS")
	else:
		_tests_failed += 1
		push_error("Test failed: %s" % test_name)
		print("  FAIL")
	print("")

func _test_autoloads() -> bool:
	var autoloads = [
		"GameManagerGlobal",
		"SaveManagerGlobal",
		"AudioManagerGlobal",
		"InputManagerGlobal",
		"LoggerGlobal",
		"CraftingSystemGlobal",
		"CombatSystemGlobal",
		"ResourceSystemGlobal",
		"SurvivalSystemGlobal"
	]
	for autoload_name in autoloads:
		var path = ProjectSettings.get_setting("autoload/%s" % autoload_name, "")
		if path == null or str(path).is_empty():
			push_error("Missing autoload: %s" % autoload_name)
			return false
	return true

func _test_scene_loading() -> bool:
	var scene_paths = [
		"res://scenes/Main.tscn",
		"res://scenes/GameWorld.tscn",
		"res://scenes/Player.tscn",
		"res://scenes/Enemy.tscn",
		"res://scenes/ResourceNode.tscn",
		"res://scenes/ItemPickup.tscn",
		"res://scenes/HUD.tscn"
	]
	for scene_path in scene_paths:
		var scene_resource = ResourceLoader.load(scene_path)
		if not scene_resource is PackedScene:
			push_error("Scene failed to load as PackedScene: %s" % scene_path)
			return false
	return true

func _test_signals() -> bool:
	var script = ResourceLoader.load("res://scripts/autoloads/GameManagerGlobal.gd")
	if script == null:
		push_error("GameManagerGlobal script failed to load")
		return false
	var source = FileAccess.get_file_as_string("res://scripts/autoloads/GameManagerGlobal.gd")
	var required_signals = [
		"game_paused",
		"game_resumed",
		"scene_changing",
		"scene_changed",
		"new_game_started",
		"game_loaded",
		"game_saved",
		"quit_to_main_menu"
	]
	for signal_name in required_signals:
		if not source.contains("signal %s" % signal_name):
			push_error("Missing signal in GameManagerGlobal: %s" % signal_name)
			return false
	return true

func _test_save_load_api_presence() -> bool:
	var save_script = ResourceLoader.load("res://scripts/autoloads/SaveManagerGlobal.gd")
	if save_script == null:
		push_error("SaveManagerGlobal script failed to load")
		return false
	var source = FileAccess.get_file_as_string("res://scripts/autoloads/SaveManagerGlobal.gd")
	var required_methods = [
		"save_game",
		"load_game",
		"delete_save",
		"list_saves",
		"_write_save_file",
		"_read_save_file",
		"_verify_save_file",
		"_calculate_checksum"
	]
	for method_name in required_methods:
		if not source.contains("func %s" % method_name):
			push_error("Missing method in SaveManagerGlobal: %s" % method_name)
			return false
	return true

func _test_inventory_invariants() -> bool:
	var inventory_script = ResourceLoader.load("res://scripts/components/inventory_component.gd")
	if inventory_script == null:
		push_error("InventoryComponent script failed to load")
		return false
	var inventory = inventory_script.new()
	inventory.max_slots = 2
	inventory.max_weight = 1.0
	root.add_child(inventory)
	var added_wood = inventory.add_item("wood", 2, 0.2)
	var weight_ok = abs(inventory.get_current_weight() - 0.4) < 0.0001
	var negative_add_rejected = not inventory.add_item("wood", -1, 0.2)
	var negative_remove_rejected = not inventory.remove_item("wood", -1)
	var overweight_rejected = not inventory.add_item("stone", 10, 0.2)
	var added_stone = inventory.add_item("stone", 1, 0.2)
	var extra_slot_rejected = not inventory.add_item("meat", 1, 0.1)
	inventory.free()
	return added_wood and weight_ok and negative_add_rejected and negative_remove_rejected and overweight_rejected and added_stone and extra_slot_rejected

func _test_crafting_batch_invariants() -> bool:
	var recipe = CraftingSystemGlobal.get_recipe("stone_axe")
	if recipe == null:
		push_error("stone_axe recipe resource did not load")
		return false
	if not CraftingSystemGlobal.is_recipe_known("stone_axe"):
		CraftingSystemGlobal.learn_recipe("stone_axe")
	var inventory := {"wood": 3, "stone": 2}
	var result = CraftingSystemGlobal.craft("stone_axe", inventory)
	if not result.get("success", false):
		push_error("Valid stone axe craft was rejected")
		return false
	if inventory.has("wood") or inventory.has("stone"):
		push_error("Craft did not consume the exact ingredients")
		return false
	if result.get("result_item", "") != "stone_axe" or int(result.get("count", 0)) != 1:
		push_error("Craft returned the wrong output")
		return false

	var insufficient_batch := {"wood": 3, "stone": 2}
	var before := insufficient_batch.duplicate()
	var rejected = CraftingSystemGlobal.craft("stone_axe", insufficient_batch, 2)
	return not rejected.get("success", true) and insufficient_batch == before

func _test_save_load_roundtrip() -> bool:
	var original_directory: String = SaveManagerGlobal.save_directory
	var test_directory := "user://test_saves/"
	var absolute_directory := ProjectSettings.globalize_path(test_directory)
	DirAccess.make_dir_recursive_absolute(absolute_directory)
	if not DirAccess.dir_exists_absolute(absolute_directory):
		push_error("Could not create isolated save test directory")
		return false

	SaveManagerGlobal.save_directory = test_directory
	var payload := {
		"version": SaveManagerGlobal.SAVE_VERSION,
		"timestamp": 1234567890,
		"player": {"health": 75, "position": [1, 2, 3]},
		"inventory": {"wood": 3, "stone": 2}
	}
	var write_error: Error = SaveManagerGlobal._write_save_file(9, payload)
	var loaded: Dictionary = {}
	if write_error == OK:
		loaded = SaveManagerGlobal._read_save_file(9)

	SaveManagerGlobal.save_directory = original_directory
	var save_path := ProjectSettings.globalize_path(test_directory.path_join("slot_9.save"))
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	DirAccess.remove_absolute(absolute_directory)

	if write_error != OK:
		push_error("Save roundtrip write failed with error %s" % write_error)
		return false
	if loaded != payload:
		push_error("Save roundtrip payload mismatch: %s" % loaded)
		return false
	return true

func _run_all_tests() -> void:
	print("=== Death Island Integration Smoke Tests ===")
	print("")
	_run_test("Autoload registration", _test_autoloads)
	_run_test("Scene loading", _test_scene_loading)
	_run_test("GameManager signal declarations", _test_signals)
	_run_test("Inventory invariants", _test_inventory_invariants)
	_run_test("Crafting batch invariants", _test_crafting_batch_invariants)
	_run_test("Save/load API presence (static)", _test_save_load_api_presence)
	_run_test("Save/load roundtrip (runtime)", _test_save_load_roundtrip)
	print("=== Test Summary ===")
	print("Passed: %d" % _tests_passed)
	print("Failed: %d" % _tests_failed)
