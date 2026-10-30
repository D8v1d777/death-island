extends SceneTree
## Standalone compatibility entry point for the production unit suite.


func _initialize() -> void:
	call_deferred("_start")


func _start() -> void:
	root.add_child(load("res://tests/unit/TestRunner.gd").new())
