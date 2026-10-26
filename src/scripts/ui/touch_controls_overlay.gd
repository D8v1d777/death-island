extends Control

@export var always_visible: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_process(true)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not always_visible and not (OS.has_feature("mobile") or OS.has_feature("android")):
		return
	if get_tree().paused:
		return

	var viewport_size := get_viewport_rect().size
	var joystick_center := InputManagerGlobal.joystick_center
	if not InputManagerGlobal.joystick_active:
		joystick_center = Vector2(viewport_size.x * 0.2, viewport_size.y * 0.78)
	var joystick_radius: float = InputManagerGlobal.joystick_max_radius
	draw_circle(joystick_center, joystick_radius, Color(0.05, 0.07, 0.08, 0.28))
	draw_arc(joystick_center, joystick_radius, 0.0, TAU, 48, Color(0.85, 0.87, 0.82, 0.65), 2.0, true)
	var knob_center := joystick_center + InputManagerGlobal.joystick_value * joystick_radius
	draw_circle(knob_center, InputManagerGlobal.button_size * 0.32, Color(0.75, 0.78, 0.72, 0.5))
	draw_arc(knob_center, InputManagerGlobal.button_size * 0.32, 0.0, TAU, 32, Color(0.95, 0.95, 0.9, 0.8), 2.0, true)

	var labels := {
		"attack_light": "HIT",
		"attack_heavy": "HEAVY",
		"dodge": "DODGE",
		"interact": "USE"
	}
	for action in InputManagerGlobal.get_debug_button_layout():
		var center: Vector2 = InputManagerGlobal.get_debug_button_layout()[action]
		var pressed := InputManagerGlobal.is_action_pressed(action)
		var fill := Color(0.12, 0.15, 0.15, 0.7) if pressed else Color(0.05, 0.07, 0.08, 0.42)
		draw_circle(center, InputManagerGlobal.button_size * 0.5, fill)
		draw_arc(center, InputManagerGlobal.button_size * 0.5, 0.0, TAU, 40, Color(0.85, 0.87, 0.82, 0.75), 2.0, true)
		var label: String = str(labels.get(action, action.to_upper()))
		draw_string(ThemeDB.fallback_font, center + Vector2(-InputManagerGlobal.button_size * 0.5, 6.0), label, HORIZONTAL_ALIGNMENT_CENTER, InputManagerGlobal.button_size, 14, Color(1.0, 1.0, 0.95, 0.95))
