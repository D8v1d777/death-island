class_name Companion
extends CharacterBody3D
## Mara follows at a safe distance, assists combat, and collects nearby supplies.

const FOLLOW_SPEED := 6.0
const ASSIST_DAMAGE := 8.0

var _assist_timer := 0.0
var _home := Vector3.ZERO
var _illustration: IllustratedActor


func _ready() -> void:
	add_to_group("interactables")
	_home = global_position
	collision_layer = 4
	collision_mask = 16
	_illustration = IllustratedActor.new()
	_illustration.art_key = "mara"
	add_child(_illustration)
	LowPoly.collision(self, Vector3(0.6, 1.8, 0.5), Vector3(0, 0.9, 0))
	LowPoly.label(self, "MARA", IllustratedArt.SCREEN_UP * 3.5, Color("f0d098"))


func _physics_process(delta: float) -> void:
	var player := GameManagerGlobal.get_player()
	if not player or not QuestSystemGlobal.recruited:
		return
	var offset := player.global_position - global_position
	var direction := offset.normalized() if offset.length() > 3.0 else Vector3.ZERO
	_illustration.animate_movement(direction)
	velocity = Vector3(
		direction.x * FOLLOW_SPEED,
		-1 if is_on_floor() else velocity.y - 20 * delta,
		direction.z * FOLLOW_SPEED
	)
	move_and_slide()
	if offset.length() > 25:
		global_position = player.global_position + Vector3(2, 1, 2)
	_assist_timer -= delta
	if _assist_timer > 0:
		return
	_assist_timer = 2.0
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if (
			not enemy.health_comp.is_dead()
			and global_position.distance_to(enemy.global_position) < 4
		):
			CombatSystemGlobal.apply_damage(self, enemy, ASSIST_DAMAGE, 0, 0)
			_illustration.play_action("attack")
			return
	for pickup: ItemPickup in get_tree().get_nodes_in_group("pickups"):
		if global_position.distance_to(pickup.global_position) < 5:
			pickup.interact(player)
			return


func can_interact() -> bool:
	return true


func get_interaction_text() -> String:
	return "Talk to Mara"


func interact(_player: Player) -> void:
	GameManagerGlobal.open_menu("dialogue")
