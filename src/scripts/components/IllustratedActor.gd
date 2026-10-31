class_name IllustratedActor
extends Node3D
## Animation frames follow gameplay actions; sprites never change simulation state.

const ACTION_FRAMES := {
	"attack": 3, "gather": 4, "drink": 5, "craft": 6, "cook": 6, "build": 4, "dodge": 7
}

var art_key := "survivor"
var character_id := ""
var body: Sprite3D
var action_name := "idle"
var _action_time := 0.0
var _walk_time := 0.0
var _moving := false
var _base_position := Vector3.ZERO


func _ready() -> void:
	if not character_id.is_empty():
		set_character_id(character_id)
	IllustratedArt.shadow(self)
	body = IllustratedArt.sprite(self, art_key, 3.4, Vector3.ZERO, 8)
	_base_position = body.position


func set_character_id(value: String) -> void:
	character_id = CharacterRoster.normalize_id(value)
	art_key = CharacterRoster.art_key(character_id)
	if is_instance_valid(body):
		body.texture = DataCatalogGlobal.art.textures.get(
			art_key, DataCatalogGlobal.art.textures.survivor
		)
		body.frame = 0


func animate_movement(direction: Vector3) -> void:
	_moving = direction.length_squared() > 0.05
	if absf(direction.x) > 0.05:
		body.flip_h = direction.x < 0


func play_action(action: String, duration: float = 0.8) -> void:
	if not ACTION_FRAMES.has(action):
		return
	action_name = action
	_action_time = duration
	body.frame = ACTION_FRAMES[action]


func _process(delta: float) -> void:
	_walk_time += delta
	_action_time = maxf(0, _action_time - delta)
	if _action_time > 0:
		body.frame = ACTION_FRAMES[action_name]
	elif _moving:
		action_name = "walk"
		body.frame = 1 + int(_walk_time * 7) % 2
	else:
		action_name = "idle"
		body.frame = 0
	body.position = (
		_base_position
		+ (
			IllustratedArt.SCREEN_UP
			* (absf(sin(_walk_time * 9)) * 0.055 if _moving else sin(_walk_time * 2) * 0.015)
		)
	)
