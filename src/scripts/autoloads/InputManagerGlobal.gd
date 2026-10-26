extends Node

## Input management: touch controls, virtual joystick, action mapping, vibration.

signal touch_controls_changed
signal vibration_requested(duration_ms: int, intensity: float)

@export_group("Touch Control Configuration")
@export var joystick_zone_rect: Rect2 = Rect2(0, 0, 0.4, 1.0)  # Left 40% of screen
@export var action_zone_rect: Rect2 = Rect2(0.6, 0, 0.4, 1.0)   # Right 40% of screen
@export var joystick_deadzone: float = 0.15
@export var joystick_max_radius: float = 120.0  # pixels
@export var button_size: float = 80.0  # pixels
@export var button_opacity: float = 0.7
@export var haptic_feedback_enabled: bool = true
@export var vibration_intensity: float = 0.5

@export_group("Camera Touch")
@export var camera_touch_sensitivity: float = 0.005
@export var invert_camera_x: bool = false
@export var invert_camera_y: bool = true

@export_group("Runtime State")
@export var joystick_active: bool = false
@export var joystick_center: Vector2 = Vector2.ZERO
@export var joystick_value: Vector2 = Vector2.ZERO
@export var active_touches: Dictionary = {}

# Button layout for action zone (relative to zone)
var _button_layout: Dictionary = {
	"attack_light": Vector2(0.5, 0.3),   # Right, upper
	"attack_heavy": Vector2(0.8, 0.5),   # Far right, middle
	"dodge": Vector2(0.5, 0.7),          # Right, lower
	"interact": Vector2(0.2, 0.5),       # Left of zone, middle
}

func _ready() -> void:
	# Ensure InputMap has our actions
	_ensure_input_map()

func _unhandled_input(event: InputEvent) -> void:
	# Handle touch events
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _ensure_input_map() -> void:
	var actions = [
		"move_forward", "move_backward", "move_left", "move_right",
		"camera_horizontal", "camera_vertical",
		"attack_light", "attack_heavy", "dodge", "interact",
		"inventory", "pause"
	]

	for action in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)

## Public API

func get_joystick_vector() -> Vector2:
	"""Returns normalized joystick vector (-1 to 1)"""
	return joystick_value.limit_length(1.0)

func is_action_pressed(action: String) -> bool:
	"""Check if action is currently pressed (including touch)"""
	return Input.is_action_pressed(action) or _is_touch_action_pressed(action)

func is_action_just_pressed(action: String) -> bool:
	"""Check if action was just pressed this frame"""
	return Input.is_action_just_pressed(action) or _is_touch_action_just_pressed(action)

func is_action_just_released(action: String) -> bool:
	"""Check if action was just released this frame"""
	return Input.is_action_just_released(action) or _is_touch_action_just_released(action)

func get_touch_sensitivity() -> float:
	return camera_touch_sensitivity

func set_touch_sensitivity(value: float) -> void:
	camera_touch_sensitivity = clamp(value, 0.001, 0.02)
	touch_controls_changed.emit()

func get_invert_camera_x() -> bool:
	return invert_camera_x

func set_invert_camera_x(value: bool) -> void:
	invert_camera_x = value
	touch_controls_changed.emit()

func get_invert_camera_y() -> bool:
	return invert_camera_y

func set_invert_camera_y(value: bool) -> void:
	invert_camera_y = value
	touch_controls_changed.emit()

func is_vibration_enabled() -> bool:
	return haptic_feedback_enabled

func set_vibration_enabled(enabled: bool) -> void:
	haptic_feedback_enabled = enabled

func vibrate(duration_ms: int = 50, intensity: float = -1.0) -> void:
	if not haptic_feedback_enabled:
		return
	if intensity < 0:
		intensity = vibration_intensity
	Input.vibrate_handheld(duration_ms, intensity)
	vibration_requested.emit(duration_ms, intensity)

## Touch Handling

func _handle_touch(event: InputEventScreenTouch) -> void:
	var pos = event.position
	var viewport_size = get_viewport().get_visible_rect().size
	var normalized = pos / viewport_size

	if event.pressed:
		_on_touch_start(event.index, pos, normalized)
	else:
		_on_touch_end(event.index, pos, normalized)

func _handle_drag(event: InputEventScreenDrag) -> void:
	var pos = event.position
	var viewport_size = get_viewport().get_visible_rect().size
	var normalized = pos / viewport_size

	_on_touch_drag(event.index, pos, normalized)

func _on_touch_start(index: int, position: Vector2, normalized: Vector2) -> void:
	# Check joystick zone
	if _point_in_zone(normalized, joystick_zone_rect):
		joystick_active = true
		joystick_center = position
		joystick_value = Vector2.ZERO
		active_touches[index] = {"type": "joystick", "start_pos": position}
		return

	# Check action zone buttons
	var button_action = _get_button_at_position(normalized)
	if button_action:
		active_touches[index] = {"type": "button", "action": button_action, "pressed": true}
		_simulate_action_press(button_action)
		_vibrate_for_action(button_action)
		return

	# Camera drag (right side, not on button)
	if _point_in_zone(normalized, action_zone_rect) and not button_action:
		active_touches[index] = {"type": "camera", "last_pos": position}

func _on_touch_drag(index: int, position: Vector2, normalized: Vector2) -> void:
	if not active_touches.has(index):
		return

	var touch = active_touches[index]

	match touch.type:
		"joystick":
			var delta = position - touch.start_pos
			var distance = delta.length()
			if distance > joystick_max_radius:
				delta = delta.normalized() * joystick_max_radius
			joystick_value = delta / joystick_max_radius

			# Apply deadzone
			if joystick_value.length() < joystick_deadzone:
				joystick_value = Vector2.ZERO

			# Map to input actions
			_set_joystick_actions(joystick_value)

		"camera":
			var delta = position - touch.last_pos
			touch.last_pos = position

			var sensitivity = camera_touch_sensitivity
			var x = delta.x * sensitivity * (1.0 if invert_camera_x else -1.0)
			var y = delta.y * sensitivity * (1.0 if invert_camera_y else -1.0)

			Input.action_press("camera_horizontal", abs(x) > 0.001)
			Input.action_press("camera_vertical", abs(y) > 0.001)
			# Note: Godot doesn't support analog action strength directly
			# Camera system should read from Input.get_axis or similar

		"button":
			# Check if drag moved off button
			var button_action = _get_button_at_position(normalized)
			if button_action != touch.action:
				# Released off button
				_simulate_action_release(touch.action)
				touch.pressed = false

func _on_touch_end(index: int, position: Vector2, normalized: Vector2) -> void:
	if not active_touches.has(index):
		return

	var touch = active_touches[index]

	match touch.type:
		"joystick":
			joystick_active = false
			joystick_value = Vector2.ZERO
			_clear_joystick_actions()

		"button":
			if touch.pressed:
				_simulate_action_release(touch.action)

		"camera":
			Input.action_release("camera_horizontal")
			Input.action_release("camera_vertical")

	active_touches.erase(index)

func _point_in_zone(point: Vector2, zone: Rect2) -> bool:
	return point.x >= zone.position.x and point.x <= zone.position.x + zone.size.x \
		and point.y >= zone.position.y and point.y <= zone.position.y + zone.size.y

func _get_button_at_position(normalized: Vector2) -> String:
	var viewport_size = get_viewport().get_visible_rect().size
	var zone_pos = action_zone_rect.position * viewport_size
	var zone_size = action_zone_rect.size * viewport_size

	for action in _button_layout:
		var rel_pos = _button_layout[action]
		var btn_center = zone_pos + rel_pos * zone_size
		var btn_rect = Rect2(btn_center - Vector2(button_size, button_size) * 0.5, Vector2(button_size, button_size))

		if btn_rect.has_point(get_viewport().get_mouse_position()):
			return action
	return ""

func _set_joystick_actions(value: Vector2) -> void:
	# Map joystick to movement actions
	Input.action_press("move_right", value.x > joystick_deadzone)
	Input.action_press("move_left", value.x < -joystick_deadzone)
	Input.action_press("move_forward", value.y < -joystick_deadzone)  # Y is inverted in screen space
	Input.action_press("move_backward", value.y > joystick_deadzone)

func _clear_joystick_actions() -> void:
	Input.action_release("move_right")
	Input.action_release("move_left")
	Input.action_release("move_forward")
	Input.action_release("move_backward")

func _simulate_action_press(action: String) -> void:
	Input.action_press(action)

func _simulate_action_release(action: String) -> void:
	Input.action_release(action)

func _is_touch_action_pressed(action: String) -> bool:
	for touch in active_touches.values():
		if touch.type == "button" and touch.action == action and touch.pressed:
			return true
	return false

func _is_touch_action_just_pressed(action: String) -> bool:
	# Touch actions are instant, so just_pressed == pressed for touch
	return _is_touch_action_pressed(action)

func _is_touch_action_just_released(action: String) -> bool:
	# Would need frame tracking for true just_released
	return false

func _vibrate_for_action(action: String) -> void:
	match action:
		"attack_light": vibrate(30, 0.3)
		"attack_heavy": vibrate(60, 0.6)
		"dodge": vibrate(40, 0.4)
		"interact": vibrate(20, 0.2)
		_: pass

## Debug Visualization (for development)

func get_debug_joystick_info() -> Dictionary:
	return {
		"active": joystick_active,
		"center": joystick_center,
		"value": joystick_value,
		"zone": joystick_zone_rect
	}

func get_debug_button_layout() -> Dictionary:
	var viewport_size = get_viewport().get_visible_rect().size
	var zone_pos = action_zone_rect.position * viewport_size
	var zone_size = action_zone_rect.size * viewport_size

	var layout = {}
	for action in _button_layout:
		var rel = _button_layout[action]
		layout[action] = zone_pos + rel * zone_size
	return layout