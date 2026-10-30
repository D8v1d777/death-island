extends Node
## Finger ownership prevents joystick, camera and action touches from colliding.

signal action_requested(action: String)
signal touch_controls_changed

const JOYSTICK_RADIUS := 120.0
const DEADZONE := 0.15
const BUTTON_SIZE := 84.0
const ACTIONS: Array[String] = ["interact", "attack_light", "attack_heavy", "dodge", "sprint"]

var joystick_value := Vector2.ZERO
var joystick_center := Vector2.ZERO
var joystick_active := false
var camera_touch_sensitivity := 0.005
var invert_camera_x := false
var invert_camera_y := false
var haptic_feedback_enabled := true
var button_opacity := 0.7
var control_scale := 1.0
var left_handed := false
var touch_sprint := false
var _joystick_finger := -1
var _camera_finger := -1
var _camera_delta := Vector2.ZERO
var _button_fingers: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not event.pressed:
		if event.index == _joystick_finger:
			_joystick_finger = -1
			joystick_active = false
			joystick_value = Vector2.ZERO
		if event.index == _camera_finger:
			_camera_finger = -1
		if _button_fingers.get(event.index, "") == "sprint":
			touch_sprint = false
		_button_fingers.erase(event.index)
	elif event is InputEventScreenDrag and not get_tree().paused:
		if event.index == _joystick_finger:
			joystick_value = (
				((event.position - joystick_center) / (JOYSTICK_RADIUS * control_scale))
				. limit_length()
			)
			if joystick_value.length() < DEADZONE:
				joystick_value = Vector2.ZERO
			get_viewport().set_input_as_handled()
		elif event.index == _camera_finger:
			_camera_delta += event.relative * camera_touch_sensitivity
			get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused or not event is InputEventScreenTouch or not event.pressed:
		return
	var size := get_viewport().get_visible_rect().size
	var layout := get_button_layout()
	for action in layout:
		if event.position.distance_to(layout[action]) <= BUTTON_SIZE * control_scale * 0.6:
			_button_fingers[event.index] = action
			if action == "sprint":
				touch_sprint = true
			else:
				action_requested.emit(action)
			get_viewport().set_input_as_handled()
			return
	var left_zone: bool = event.position.x < size.x * 0.4
	var move_zone: bool = not left_zone if left_handed else left_zone
	if move_zone and event.position.y > size.y * 0.4 and _joystick_finger == -1:
		_joystick_finger = event.index
		joystick_center = event.position
		joystick_value = Vector2.ZERO
		joystick_active = true
	elif not move_zone and _camera_finger == -1:
		_camera_finger = event.index
	get_viewport().set_input_as_handled()


func movement() -> Vector2:
	var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	return (keyboard + joystick_value).limit_length()


func consume_camera_delta() -> Vector2:
	var result := _camera_delta
	_camera_delta = Vector2.ZERO
	result.x *= -1 if invert_camera_x else 1
	result.y *= -1 if invert_camera_y else 1
	return result


func reset() -> void:
	_joystick_finger = -1
	_camera_finger = -1
	_button_fingers.clear()
	joystick_active = false
	joystick_value = Vector2.ZERO
	_camera_delta = Vector2.ZERO
	touch_sprint = false


func get_button_layout() -> Dictionary:
	var size := get_viewport().get_visible_rect().size
	var origin := Vector2(size.x - 205, size.y - 170)
	var offsets := [
		Vector2(-105, 0), Vector2(5, -65), Vector2(110, 0), Vector2(5, 55), Vector2(-105, -105)
	]
	var layout: Dictionary = {}
	for index in ACTIONS.size():
		var position: Vector2 = origin + offsets[index] * control_scale
		if left_handed:
			position.x = size.x - position.x
		layout[ACTIONS[index]] = position
	return layout


func vibrate(duration_ms: int = 40, intensity: float = 0.4) -> void:
	if haptic_feedback_enabled and OS.has_feature("android"):
		Input.vibrate_handheld(duration_ms, intensity)


func get_touch_sensitivity() -> float:
	return camera_touch_sensitivity


func set_touch_sensitivity(value: float) -> void:
	camera_touch_sensitivity = clampf(value, 0.001, 0.02)
	touch_controls_changed.emit()


func get_invert_camera_x() -> bool:
	return invert_camera_x


func get_invert_camera_y() -> bool:
	return invert_camera_y


func is_vibration_enabled() -> bool:
	return haptic_feedback_enabled
