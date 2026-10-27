extends Node

var _tests_passed = 0
var _tests_failed = 0
var _output_lines: Array[String] = []

func _ready() -> void:
	_output_lines.append("=== Simple Test ===")
	_assert(true, "Test 1 passes")
	_assert(1 + 1 == 2, "Test 2 passes")
	_assert("hello" == "hello", "Test 3 passes")

	_output_lines.append("")
	_output_lines.append("=== Test Summary ===")
	_output_lines.append("Passed: %d" % _tests_passed)
	_output_lines.append("Failed: %d" % _tests_failed)

	# Write to file in project directory
	var file = FileAccess.open("/root/death-island/test_results.txt", FileAccess.WRITE)
	if file:
		for line in _output_lines:
			file.store_line(line)
		file.close()
		print("Results written to file")
	else:
		print("Failed to open file for writing")

	if _tests_failed > 0:
		quit(1)
	else:
		quit(0)

func _assert(condition: bool, message: String) -> void:
	if condition:
		_tests_passed += 1
		_output_lines.append("  ✓ %s" % message)
	else:
		_tests_failed += 1
		_output_lines.append("  ✗ FAILED: %s" % message)