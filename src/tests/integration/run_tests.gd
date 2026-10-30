extends SceneTree


func _initialize() -> void:
	call_deferred("_start")


func _start() -> void:
	root.add_child(load("res://tests/integration/GameplayTestRunner.gd").new())
