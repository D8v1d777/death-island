extends Control
## Visual geometry comes from the same layout used for touch hit-testing.

const LABELS := {
	"interact": "GATHER\nTALK",
	"attack_light": "ATTACK",
	"attack_heavy": "HEAVY",
	"dodge": "DODGE",
	"sprint": "SPRINT"
}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	var center := Vector2(170, viewport_size.y - 170)
	if InputManagerGlobal.left_handed:
		center.x = viewport_size.x - center.x
	if InputManagerGlobal.joystick_active:
		center = InputManagerGlobal.joystick_center
	var radius := InputManagerGlobal.JOYSTICK_RADIUS * InputManagerGlobal.control_scale
	var opacity := InputManagerGlobal.button_opacity
	draw_circle(center, radius, Color(0.20, 0.24, 0.18, opacity * 0.22))
	draw_arc(center, radius, 0, TAU, 48, Color(0.87, 0.80, 0.58, opacity * 0.7), 2, true)
	draw_circle(
		center + InputManagerGlobal.joystick_value * radius,
		30,
		Color(0.87, 0.80, 0.58, opacity * 0.65)
	)
	var font := ThemeDB.fallback_font
	var layout := InputManagerGlobal.get_button_layout()
	for action in layout:
		var point: Vector2 = layout[action]
		var button_radius := InputManagerGlobal.BUTTON_SIZE * InputManagerGlobal.control_scale * 0.5
		draw_circle(point, button_radius, Color(0.20, 0.24, 0.18, opacity * 0.7))
		draw_arc(point, button_radius, 0, TAU, 32, Color(0.79, 0.7, 0.48, opacity), 2, true)
		var lines: PackedStringArray = LABELS[action].split("\n")
		for index in lines.size():
			var text_size := font.get_string_size(lines[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
			draw_string(
				font,
				point + Vector2(-text_size.x / 2, 5 + index * 16 - (lines.size() - 1) * 8),
				lines[index],
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				14,
				Color("f1ead8")
			)
