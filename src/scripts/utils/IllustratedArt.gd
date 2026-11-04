class_name IllustratedArt
extends RefCounted
## Camera-facing illustrations anchored at their feet on the physics plane.
## SPRITE_META: Embedded spritesheet metadata for frame detection.

const CAMERA_PITCH := -PI / 4.0
const SCREEN_UP := Vector3(0, 0.70710678, -0.70710678)

## Spritesheet metadata: {key: {hframes, vframes, frame_width, frame_height, animations}}
static var SPRITE_META: Dictionary = {}

static func _register_meta(key: String, meta: Dictionary) -> void:
	SPRITE_META[key] = meta


static func sprite(
	parent: Node3D,
	key: String,
	height: float,
	at: Vector3 = Vector3.ZERO,
	animation_set = null
) -> Sprite3D:
	var node := Sprite3D.new()
	node.name = "Illustration"
	var texture: Texture2D = DataCatalogGlobal.art.textures.get(
		key, DataCatalogGlobal.art.textures.rock
	)
	if DisplayServer.get_name() != "headless":
		node.texture = texture

	# Use animation set to determine hframes if provided, else fallback to meta or default
	var hframes := 1
	if animation_set:
		# Find max frame used in animation set
		var max_frame := 0
		for anim in animation_set.animations.values():
			var anim_dict: Dictionary = anim
			var end_frame: int = anim_dict.start_frame + anim_dict.frame_count
			if end_frame > max_frame:
				max_frame = end_frame
		hframes = max_frame
	elif SPRITE_META.has(key):
		hframes = SPRITE_META[key].hframes
	else:
		# Legacy: infer from texture aspect ratio
		var w := texture.get_width()
		var h := texture.get_height()
		if w > h * 1.5:
			hframes = int(w / h)

	node.hframes = hframes
	node.vframes = SPRITE_META[key].vframes if SPRITE_META.has(key) else 1
	node.pixel_size = height / float(texture.get_height())
	# Fix: rotate by +PI/4 so sprite faces camera (camera is at -PI/4 pitch)
	# Camera forward: (0, -0.707, -0.707); sprite needs normal: (0, 0.707, 0.707)
	# Default sprite faces +Z (0,0,1); rotate +45° around X to face camera
	node.rotation.x = PI / 4.0
	node.position = at + SCREEN_UP * height * 0.43
	node.shaded = false
	node.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	node.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	node.add_to_group("illustrations")
	parent.add_child(node)

	# Attach animation controller if animation set provided
	if animation_set:
		var controller = preload("res://scripts/utils/AnimatedSpriteController.gd").new()
		controller.name = "AnimationController"
		controller.animation_set = animation_set
		controller.sprite = node
		node.add_child(controller)

	return node


static func shadow(parent: Node3D, width: float = 1.6) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var node := Sprite3D.new()
	node.texture = DataCatalogGlobal.art.textures.shadow
	node.pixel_size = width / 128.0
	node.rotation.x = -PI / 2.0
	node.position.y = 0.035
	node.shaded = false
	parent.add_child(node)


## Register a spritesheet with metadata (called during asset import or initialization)
static func register_spritesheet(key: String, hframes: int, vframes: int = 1, animation_set = null) -> void:
	var meta: Dictionary = {
		"hframes": hframes,
		"vframes": vframes,
		"animation_set": animation_set
	}
	SPRITE_META[key] = meta


## Get animation set for a key (from meta or create default)
static func get_animation_set(key: String):
	if SPRITE_META.has(key) and SPRITE_META[key].animation_set:
		return SPRITE_META[key].animation_set

	# Fallback factory based on key name - inline to avoid cross-file function calls
	var AnimClass = preload("res://scripts/data/AnimationSetResource.gd")
	var res = AnimClass.new()
	match key:
		"survivor", "mara":
			res.default_fps = 8.0
			res.animations = {
				"idle": {"start_frame": 0, "frame_count": 4, "loop": true, "fps": 6.0},
				"walk": {"start_frame": 4, "frame_count": 6, "loop": true, "fps": 10.0},
				"run": {"start_frame": 10, "frame_count": 6, "loop": true, "fps": 12.0},
				"attack_light": {"start_frame": 16, "frame_count": 4, "loop": false, "fps": 16.0},
				"attack_heavy": {"start_frame": 20, "frame_count": 6, "loop": false, "fps": 12.0},
				"gather": {"start_frame": 26, "frame_count": 5, "loop": false, "fps": 8.0},
				"drink": {"start_frame": 31, "frame_count": 4, "loop": false, "fps": 6.0},
				"craft": {"start_frame": 35, "frame_count": 6, "loop": false, "fps": 6.0},
				"dodge": {"start_frame": 41, "frame_count": 4, "loop": false, "fps": 20.0},
				"hurt": {"start_frame": 45, "frame_count": 3, "loop": false, "fps": 12.0},
				"death": {"start_frame": 48, "frame_count": 6, "loop": false, "fps": 6.0},
			}
		"wild_boar", "wolf":
			res.default_fps = 8.0
			res.animations = {
				"idle": {"start_frame": 0, "frame_count": 4, "loop": true, "fps": 4.0},
				"walk": {"start_frame": 4, "frame_count": 6, "loop": true, "fps": 10.0},
				"run": {"start_frame": 10, "frame_count": 6, "loop": true, "fps": 12.0},
				"windup": {"start_frame": 16, "frame_count": 3, "loop": false, "fps": 8.0},
				"attack": {"start_frame": 19, "frame_count": 4, "loop": false, "fps": 16.0},
				"recover": {"start_frame": 23, "frame_count": 3, "loop": false, "fps": 6.0},
				"hurt": {"start_frame": 26, "frame_count": 3, "loop": false, "fps": 12.0},
				"death": {"start_frame": 29, "frame_count": 6, "loop": false, "fps": 6.0},
			}
		"spider":
			res.default_fps = 8.0
			res.animations = {
				"idle": {"start_frame": 0, "frame_count": 4, "loop": true, "fps": 3.0},
				"walk": {"start_frame": 4, "frame_count": 8, "loop": true, "fps": 10.0},
				"windup": {"start_frame": 12, "frame_count": 4, "loop": false, "fps": 6.0},
				"attack": {"start_frame": 16, "frame_count": 5, "loop": false, "fps": 14.0},
				"recover": {"start_frame": 21, "frame_count": 3, "loop": false, "fps": 5.0},
				"hurt": {"start_frame": 24, "frame_count": 3, "loop": false, "fps": 12.0},
				"death": {"start_frame": 27, "frame_count": 6, "loop": false, "fps": 5.0},
			}
		"guardian":
			res.default_fps = 6.0
			res.animations = {
				"idle": {"start_frame": 0, "frame_count": 6, "loop": true, "fps": 3.0},
				"walk": {"start_frame": 6, "frame_count": 8, "loop": true, "fps": 8.0},
				"windup": {"start_frame": 14, "frame_count": 6, "loop": false, "fps": 5.0},
				"attack": {"start_frame": 20, "frame_count": 8, "loop": false, "fps": 10.0},
				"recover": {"start_frame": 28, "frame_count": 4, "loop": false, "fps": 4.0},
				"hurt": {"start_frame": 32, "frame_count": 4, "loop": false, "fps": 10.0},
				"death": {"start_frame": 36, "frame_count": 8, "loop": false, "fps": 4.0},
			}
		_:
			# Empty fallback - just return base resource
			pass
	return res