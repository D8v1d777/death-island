class_name Annie
extends CharacterBody3D
## Annie - NPC survivor with blonde hair, follows player and assists.

const FOLLOW_SPEED := 5.5
const ASSIST_DAMAGE := 6.0

var _assist_timer := 0.0
var _home := Vector3.ZERO
var _illustration: IllustratedActor


func _ready() -> void:
	add_to_group("interactables")
	_home = global_position
	collision_layer = 4
	collision_mask = 16
	_illustration = IllustratedActor.new()
	_illustration.art_key = "annie"
	_illustration.height = 3.2
	add_child(_illustration)
	LowPoly.collision(self, Vector3(0.5, 1.7, 0.4), Vector3(0, 0.85, 0))
	LowPoly.label(self, "ANNIE", IllustratedArt.SCREEN_UP * 3.2, Color("f0d098"))


func _physics_process(delta: float) -> void:
	var player := GameManagerGlobal.get_player()
	if not player or not QuestSystemGlobal.recruited:
		return
	var offset := player.global_position - global_position
	var direction := offset.normalized() if offset.length() > 2.5 else Vector3.ZERO
	_illustration.animate_movement(direction)
	velocity = Vector3(
		direction.x * FOLLOW_SPEED,
		-1 if is_on_floor() else velocity.y - 20 * delta,
		direction.z * FOLLOW_SPEED
	)
	move_and_slide()
	if offset.length() > 20:
		global_position = player.global_position + Vector3(1.5, 1, 1.5)
	_assist_timer -= delta
	if _assist_timer > 0:
		return
	_assist_timer = 2.5
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if (
			not enemy.health_comp.is_dead()
			and global_position.distance_to(enemy.global_position) < 3.5
		):
			CombatSystemGlobal.apply_damage(self, enemy, ASSIST_DAMAGE, 0, 0)
			_illustration.play_action("attack")
			return
	for pickup: ItemPickup in get_tree().get_nodes_in_group("pickups"):
		if global_position.distance_to(pickup.global_position) < 4:
			pickup.interact(player)
			return


func can_interact() -> bool:
	return true


func get_interaction_text() -> String:
	return "Talk to Annie"


func interact(_player: Player) -> void:
	GameManagerGlobal.open_menu("dialogue")