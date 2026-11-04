class_name AnimationSetResource
extends Resource
## Data-driven animation frame mapping for spritesheet-based characters.
## Each action maps to a frame range (start, count, loop, fps).

@export var animations: Dictionary = {}
@export var default_fps: float = 8.0

## Get animation config for an action. Returns {start_frame, frame_count, loop, fps}
func get_animation(action: String) -> Dictionary:
	if animations.has(action):
		return animations[action]
	# Fallback to idle
	return animations.get("idle", {"start_frame": 0, "frame_count": 1, "loop": true, "fps": default_fps})

## Check if an action exists in this animation set
func has_animation(action: String) -> bool:
	return animations.has(action)


## Factory method for common character animation sets
func create_survivor_set():
	var res = new()
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
	return res

## Factory for 4-directional enemy (boar/wolf style)
func create_quadruped_set():
	var res = new()
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
	return res

## Factory for spider/ambush enemies
func create_spider_set():
	var res = new()
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
	return res

## Factory for guardian/large enemies
func create_guardian_set():
	var res = new()
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
	return res

## Factory for companion (Mara)
func create_companion_set():
	var res = new()
	res.default_fps = 8.0
	res.animations = {
		"idle": {"start_frame": 0, "frame_count": 4, "loop": true, "fps": 6.0},
		"walk": {"start_frame": 4, "frame_count": 6, "loop": true, "fps": 10.0},
		"run": {"start_frame": 10, "frame_count": 6, "loop": true, "fps": 12.0},
		"attack": {"start_frame": 16, "frame_count": 4, "loop": false, "fps": 16.0},
		"gather": {"start_frame": 20, "frame_count": 5, "loop": false, "fps": 8.0},
		"drink": {"start_frame": 25, "frame_count": 4, "loop": false, "fps": 6.0},
		"craft": {"start_frame": 29, "frame_count": 6, "loop": false, "fps": 6.0},
		"dodge": {"start_frame": 35, "frame_count": 4, "loop": false, "fps": 20.0},
		"hurt": {"start_frame": 39, "frame_count": 3, "loop": false, "fps": 12.0},
		"death": {"start_frame": 42, "frame_count": 6, "loop": false, "fps": 6.0},
	}
	return res