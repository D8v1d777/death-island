class_name AnimatedSpriteController
extends Node
## Handles frame-by-frame animation playback for Sprite3D using AnimationSetResource.

signal action_changed(old_action: String, new_action: String)

@export var animation_set: Resource = null
@export var sprite: Sprite3D

var current_action: String = "idle"
var action_timer: float = 0.0
var current_frame: int = 0
var playing: bool = false
var action_complete_callback

func _ready() -> void:
	if not sprite:
		sprite = get_parent() as Sprite3D
	play("idle")


func _process(delta: float) -> void:
	if not playing or not animation_set:
		return

	var anim: Dictionary = animation_set.get_animation(current_action)
	var frame_duration: float = 1.0 / anim.fps
	action_timer += delta

	var frame_index: int = int(action_timer / frame_duration)
	var target_frame: int = anim.start_frame + frame_index

	if frame_index >= anim.frame_count:
		if anim.loop:
			action_timer = 0.0
			target_frame = anim.start_frame
		else:
			target_frame = anim.start_frame + anim.frame_count - 1
			playing = false
			if action_complete_callback:
				action_complete_callback.call()
				action_complete_callback = null
			# Auto-return to idle for non-looping actions
			if current_action != "idle" and current_action != "death":
				call_deferred("_return_to_idle")

	if sprite and target_frame != sprite.frame:
		sprite.frame = target_frame


func play(action: String, on_complete = null) -> bool:
	if not animation_set or not animation_set.has_animation(action):
		return false

	var old_action = current_action
	current_action = action
	action_timer = 0.0
	playing = true
	action_complete_callback = on_complete

	var anim: Dictionary = animation_set.get_animation(action)
	if sprite:
		sprite.frame = anim.start_frame

	# Emit signal if action actually changed
	if old_action != action:
		action_changed.emit(old_action, action)

	return true


func _return_to_idle() -> void:
	play("idle")


func stop() -> void:
	playing = false
	action_complete_callback = null


func is_playing() -> bool:
	return playing


func get_current_action() -> String:
	return current_action