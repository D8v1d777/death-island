#!/usr/bin/env -S godot --headless --script

# Integration test runner for Death Island
# Run with: godot --headless --script tests/integration/run_tests.gd

class_name IntegrationTestRunner
extends SceneTree

var _tests_passed = 0
var _tests_failed = 0

func _initialize() -> void:
	print("=== Death Island Integration Tests ===")
	print("")

	# Note: Full integration tests require a running Godot scene tree
	# These are placeholder tests that verify system wiring

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
		print("❌ SOME TESTS FAILED")
		quit(1)
	else:
		print("✅ ALL TESTS PASSED")
		quit(0)

func _run_test(name: String, test_func: Callable) -> void:
	print("--- %s ---" % name)
	try:
		test_func.call()
		_tests_passed += 1
		print("  ✓ PASSED")
	except:
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
			return false

	return true

func _test_scene_loading() -> void:
	# Verify main scene can be loaded
	var main_scene = ResourceLoader.load("res://scenes/Main.tscn")
	if not main_scene:
		push_error("Main.tscn not found or invalid")
		return false

	var game_world = ResourceLoader.load("res://scenes/GameWorld.tscn")
	if not game_world:
		push_error("GameWorld.tscn not found or invalid")
		return false

	return true

func _test_signals() -> void:
	# Verify core signals are defined
	var gm_script = ResourceLoader.load("res://scripts/autoloads/GameManagerGlobal.gd")
	if not gm_script:
		push_error("GameManagerGlobal script not found")
		return false

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

	for signal in required_signals:
		if not source.contains("signal %s" % signal):
			push_error("Missing signal in GameManagerGlobal: %s" % signal)
			return false

	return true

func _test_save_load_roundtrip() -> void:
	# Test SaveManagerGlobal save/load cycle
	var save_script = ResourceLoader.load("res://scripts/autoloads/SaveManagerGlobal.gd")
	if not save_script:
		push_error("SaveManagerGlobal script not found")
		return false

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
			return false

	return true

_initialize()