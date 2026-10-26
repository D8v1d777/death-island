extends SceneTree

func _initialize() -> void:
	var runner_scene = load("res://tests/integration/TestRunner.tscn") as PackedScene
	if runner_scene == null:
		push_error("Integration test scene could not be loaded")
		quit(1)
		return
	root.add_child(runner_scene.instantiate())
