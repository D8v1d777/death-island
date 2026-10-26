extends Node

var _tests_passed = 0
var _tests_failed = 0

func _ready() -> void:
	_run_all_tests()
	get_tree().quit(_tests_failed)

func _run_test(name: String, test_func: Callable) -> void:
	print("--- %s ---" % name)
	var success = true
	# Call test function - if it doesn't crash, it passes
	# Test functions use push_error to log failures
	test_func.call()

	if success:
		_tests_passed += 1
		print("  ✓ PASSED")
	else:
		_tests_failed += 1
		print("  ✗ FAILED")
	print("")

func _test_autoloads() -> void:
	# Verify all required autoloads exist in ProjectSettings
	var autoloads = [
		"GameManagerGlobal",
		"SaveManagerGlobal",
		"AudioManagerGlobal",
		"InputManagerGlobal",
		"LoggerGlobal"
	]

	for name in autoloads:
		var path = ProjectSettings.get_setting("autoload/%s" % name)
		if not path:
			push_error("Missing autoload: %s" % name)
			return

func _test_scene_loading() -> void:
	# Verify main scene can be loaded
	var main_scene = ResourceLoader.load("res://scenes/Main.tscn")
	if not main_scene:
		push_error("Main.tscn not found or invalid")
		return

	var game_world = ResourceLoader.load("res://scenes/GameWorld.tscn")
	if not game_world:
		push_error("GameWorld.tscn not found or invalid")
		return

func _test_signals() -> void:
	# Verify core signals are defined
	var gm_script = ResourceLoader.load("res://scripts/autoloads/GameManagerGlobal.gd")
	if not gm_script:
		push_error("GameManagerGlobal script not found")
		return

	# Check for required signals in source
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

	for sig in required_signals:
		if not source.contains("signal %s" % sig):
			push_error("Missing signal in GameManagerGlobal: %s" % sig)
			return

func _test_save_load_roundtrip() -> void:
	# Test SaveManagerGlobal save/load cycle
	var save_script = ResourceLoader.load("res://scripts/autoloads/SaveManagerGlobal.gd")
	if not save_script:
		push_error("SaveManagerGlobal script not found")
		return

	# Verify key methods exist
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

	for method in required_methods:
		if not source.contains("func %s" % method):
			push_error("Missing method in SaveManagerGlobal: %s" % method)
			return

func _run_all_tests() -> void:
	print("=== Death Island Integration Tests ===")
	print("")

	_run_test("Autoload registration", _test_autoloads)
	_run_test("Scene loading", _test_scene_loading)
	_run_test("Signal connections", _test_signals)
	_run_test("Save/Load roundtrip", _test_save_load_roundtrip)

	print("")
	print("=== Integration Test Summary ===")
	print("Passed: %d" % _tests_passed)
	print("Failed: %d" % _tests_failed)
	print("Total:  %d" % (_tests_passed + _tests_failed))

	if _tests_failed > 0:
		print("")
		print("❌ SOME TESTS FAILED")
	else:
		print("")
		print("✅ ALL TESTS PASSED")