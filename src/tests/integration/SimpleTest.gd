extends Node

var _tests_passed = 0
var _tests_failed = 0

func _ready() -> void:
	print("=== Simple Test ===")
	_assert(true, "Test 1 passes")
	_assert(1 + 1 == 2, "Test 2 passes")
	_assert("hello" == "hello", "Test 3 passes")

	print("")
	print("=== Test Summary ===")
	print("Passed: %d" % _tests_passed)
	print("Failed: %d" % _tests_failed)

	if _tests_failed > 0:
		quit(1)
	else:
		quit(0)

func _assert(condition: bool, message: String) -> void:
	if condition:
		_tests_passed += 1
		print("  ✓ %s" % message)
	else:
		_tests_failed += 1
		print("  ✗ FAILED: %s" % message)