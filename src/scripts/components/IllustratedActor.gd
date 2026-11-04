class_name IllustratedActor
extends Node3D
## Animation component using AnimationSetResource for data-driven sprite animation.
## Supports idle, walk, run, attack, gather, drink, craft, dodge, hurt, death animations.

@export var art_key: String = "survivor"
@export var height: float = 3.4
@export var animation_set = null

var body: Sprite3D
var controller: Node
var action_name := "idle"
var _moving := false
var _base_position := Vector3.ZERO
var _walk_time := 0.0
var _bob_time := 0.0
var _action_time := 0.0


func _ready() -> void:
	IllustratedArt.shadow(self)

	# Get or create animation set
	if not animation_set:
		animation_set = IllustratedArt.get_animation_set(art_key)

	body = IllustratedArt.sprite(self, art_key, height, Vector3.ZERO, animation_set)
	_base_position = body.position

	# Get the animation controller attached to the sprite (by name)
	controller = body.get_node_or_null("AnimationController")

	# Connect to controller's action_changed signal to keep action_name in sync
	if controller:
		controller.action_changed.connect(_on_animation_action_changed)
		controller.play("idle")


func animate_movement(direction: Vector3) -> void:
	_moving = direction.length_squared() > 0.05
	if absf(direction.x) > 0.05:
		body.flip_h = direction.x < 0


func play_action(action: String, duration: float = 0.8) -> void:
	if not controller:
		return

	# Map legacy action names to new animation names
	var anim_action: String = _map_action(action)

	# Set action state (like original)
	action_name = action
	_action_time = duration

	# Set frame directly for immediate visual feedback (like original)
	if animation_set and animation_set.has_animation(anim_action):
		var anim: Dictionary = animation_set.get_animation(anim_action)
		body.frame = anim.start_frame

	# Also start controller animation for smooth playback
	controller.play(anim_action)


func _map_action(legacy_action: String) -> String:
	match legacy_action:
		"attack": return "attack_light"
		"gather": return "gather"
		"drink": return "drink"
		"craft": return "craft"
		"cook": return "craft"
		"build": return "craft"
		"dodge": return "dodge"
		_ : return "idle"


func play_hurt() -> void:
	if controller and animation_set.has_animation("hurt"):
		controller.play("hurt")


func play_death() -> void:
	if controller and animation_set.has_animation("death"):
		controller.play("death")


func _on_animation_action_changed(old_action: String, new_action: String) -> void:
	# Map animation action names back to legacy action names for action_name
	# Priority: explicit legacy actions > movement animations
	var legacy_action: String = _reverse_map_action(new_action)
	if legacy_action != "idle" or new_action in ["idle", "walk", "run"]:
		action_name = legacy_action


func _reverse_map_action(anim_action: String) -> String:
	match anim_action:
		"idle", "walk", "run": return anim_action
		"attack_light": return "attack"
		"attack_heavy": return "attack"
		"gather": return "gather"
		"drink": return "drink"
		"craft": return "craft"
		"dodge": return "dodge"
		"hurt": return "hurt"
		"death": return "death"
		"windup": return "windup"
		"recover": return "recover"
		_: return "idle"


func _process(delta: float) -> void:
	_walk_time += delta
	_bob_time += delta
	_action_time = maxf(0, _action_time - delta)

	# Handle action timeout - only reset to idle/walk if no action is playing
	if _action_time <= 0 and controller and animation_set:
		var anim_controller := controller
		var current: String = anim_controller.get_current_action()
		if _moving:
			if current == "idle":
				anim_controller.play("walk")
		elif current == "walk":
			anim_controller.play("idle")
		# Note: action_name is NOT auto-reset here - it stays as the last action
		# until play_action is called again or hurt/death

	# Bobbing motion
	body.position = (
		_base_position
		+ (
			IllustratedArt.SCREEN_UP
			* (absf(sin(_walk_time * 9)) * 0.055 if _moving else sin(_bob_time * 2) * 0.015)
		)
	)