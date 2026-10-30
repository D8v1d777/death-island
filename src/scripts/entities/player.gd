class_name Player
extends CharacterBody3D
## Camera-relative movement and a shared action API for every input device.

const MOVE_SPEED := 5.5
const SPRINT_SPEED := 8.5
const DODGE_SPEED := 13.0
const DODGE_TIME := 0.32
const DODGE_COST := 24.0
const LIGHT_COST := 12.0
const HEAVY_COST := 25.0
const ATTACK_RANGE := 3.0
const INTERACTION_RANGE := 3.5
const GRAVITY := 20.0
const LOOK_SPEED := 2.0

var experience := 0
var illustration: IllustratedActor
var _look := Vector2(0, -0.5)
var _facing := Vector3.FORWARD
var _interaction_target: Node3D
var _attack_cooldown := 0.0
var _dodge_timer := 0.0
var _dodge_direction := Vector3.ZERO
var _motion_time := 0.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var visual: Node3D = $Visual
@onready var health_comp: HealthComponent = $HealthComponent
@onready var inventory_comp: InventoryComponent = $InventoryComponent
@onready var survival_comp: SurvivalComponent = $SurvivalComponent
@onready var equipment_comp: EquipmentComponent = $EquipmentComponent


func _ready() -> void:
	add_to_group("players")
	spring_arm.add_excluded_object(get_rid())
	health_comp.died.connect(_on_died)
	health_comp.damaged.connect(_on_damaged)
	inventory_comp.inventory_changed.connect(_reconcile_equipment)
	illustration = IllustratedActor.new()
	visual.add_child(illustration)
	_look = Vector2(0, IllustratedArt.CAMERA_PITCH)
	camera_pivot.rotation = Vector3(IllustratedArt.CAMERA_PITCH, 0, 0)


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.size = maxf(12, camera.size - 1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.size = minf(24, camera.size + 1.0)
	for action in [
		"attack_light",
		"attack_heavy",
		"dodge",
		"interact",
		"quick_food",
		"quick_water",
		"quick_heal",
		"quick_weapon"
	]:
		if event.is_action_pressed(action):
			perform_action(action)
			get_viewport().set_input_as_handled()
			break


func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(0, _attack_cooldown - delta)
	_dodge_timer = maxf(0, _dodge_timer - delta)
	var zoom := InputManagerGlobal.consume_camera_delta().y * 4.0
	zoom += Input.get_axis("look_up", "look_down") * delta * LOOK_SPEED
	camera.size = clampf(camera.size + zoom, 12, 24)
	var input := InputManagerGlobal.movement()
	var direction := Vector3(input.x, 0, input.y)
	var sprinting := (
		(Input.is_action_pressed("sprint") or InputManagerGlobal.touch_sprint)
		and direction.length() > 0.1
		and survival_comp.stamina > 1
	)
	survival_comp.set_sprinting(sprinting)
	var speed := SPRINT_SPEED if sprinting else MOVE_SPEED
	if _dodge_timer > 0:
		direction = _dodge_direction
		speed = DODGE_SPEED
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y = -0.5 if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()
	if direction.length() > 0.1:
		_facing = direction.normalized()
	illustration.animate_movement(direction)
	if global_position.y < -5:
		global_position = Vector3(0, 1, 35)
		health_comp.take_damage(15, null, true)
	_update_interaction_target()


func perform_action(action: String) -> void:
	if health_comp.is_dead():
		return
	match action:
		"interact":
			_update_interaction_target()
			if is_instance_valid(_interaction_target):
				_interaction_target.interact(self)
		"attack_light":
			attack(false)
		"attack_heavy":
			attack(true)
		"dodge":
			if _dodge_timer <= 0 and survival_comp.consume_stamina(DODGE_COST):
				_dodge_direction = _facing
				_dodge_timer = DODGE_TIME
				health_comp.grant_immunity(DODGE_TIME)
				illustration.play_action("dodge", DODGE_TIME)
		"quick_food":
			use_item("cooked_meat" if inventory_comp.has_item("cooked_meat") else "berries")
		"quick_water":
			use_item("water")
		"quick_heal":
			use_item("bandage")
		"quick_weapon":
			use_item("iron_blade" if inventory_comp.has_item("iron_blade") else "stone_axe")


func attack(heavy: bool) -> bool:
	if _attack_cooldown > 0 or _dodge_timer > 0:
		return false
	if not survival_comp.consume_stamina(HEAVY_COST if heavy else LIGHT_COST):
		GameManagerGlobal.message_posted.emit("Not enough stamina.")
		return false
	_attack_cooldown = 0.9 if heavy else 0.45
	illustration.play_action("attack", _attack_cooldown)
	var damage := equipment_comp.attack_damage() * (1.8 if heavy else 1.0)
	var closest: Enemy
	var distance := ATTACK_RANGE
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		var offset := enemy.global_position - global_position
		if (
			not enemy.health_comp.is_dead()
			and offset.length() < distance
			and _facing.dot(offset.normalized()) > -0.15
		):
			distance = offset.length()
			closest = enemy
	if closest and _clear_sight(closest):
		var result := CombatSystemGlobal.apply_damage(self, closest, damage)
		if result.damage > 0:
			GameManagerGlobal.message_posted.emit("Hit · %d damage" % int(result.damage))
			closest.knockback(_facing * (7.0 if heavy else 3.0))
			GameManagerGlobal.world.show_hit(
				closest.global_position + Vector3.UP * 2, int(result.damage)
			)
			AudioManagerGlobal.play_ui_sfx("hit")
			if result.killed:
				experience += closest.enemy_definition.xp_reward
	equipment_comp.wear_weapon()
	InputManagerGlobal.vibrate()
	return true


func _clear_sight(target: Node3D) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP, target.global_position + Vector3.UP, 16
	)
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()


func _update_interaction_target() -> void:
	_interaction_target = null
	var distance := INTERACTION_RANGE
	for target: Node3D in get_tree().get_nodes_in_group("interactables"):
		if not target.can_interact():
			continue
		var next := global_position.distance_to(target.global_position)
		if next < distance:
			distance = next
			_interaction_target = target


func get_interaction_target() -> Node3D:
	return _interaction_target if is_instance_valid(_interaction_target) else null


func face_point(at: Vector3) -> void:
	var direction := at - global_position
	direction.y = 0
	if direction.length_squared() > 0.01:
		_facing = direction.normalized()
		illustration.body.flip_h = direction.x < 0


func use_item(item_id: String) -> bool:
	var item := DataCatalogGlobal.item(item_id)
	if not item or not inventory_comp.has_item(item_id):
		GameManagerGlobal.message_posted.emit("You don't have that item.")
		return false
	if not item.equipment_slot.is_empty():
		return equipment_comp.equip(item_id, inventory_comp)
	if not item.structure.is_empty():
		return GameManagerGlobal.world.place_structure(item_id, self)
	if item.item_type != ItemDefinition.ItemType.CONSUMABLE:
		GameManagerGlobal.message_posted.emit(item.description)
		return false
	if inventory_comp.remove_item(item_id):
		illustration.play_action("drink")
		survival_comp.eat(item.hunger)
		survival_comp.drink(item.thirst)
		health_comp.heal(item.healing)
		GameManagerGlobal.message_posted.emit("Used " + item.display_name)
		AudioManagerGlobal.play_ui_sfx("success")
		return true
	return false


func _reconcile_equipment() -> void:
	equipment_comp.reconcile(inventory_comp)


func _on_died() -> void:
	GameManagerGlobal.open_menu("death")


func _on_damaged(_amount: float, _source: Node) -> void:
	InputManagerGlobal.vibrate(80, 0.7)
	AudioManagerGlobal.play_ui_sfx("hurt")


func serialize() -> Dictionary:
	return {
		"position": StateValidation.array3(global_position),
		"rotation": [_look.x, _look.y, 0],
		"health": health_comp.current_health,
		"stamina": survival_comp.stamina,
		"hunger": survival_comp.hunger,
		"thirst": survival_comp.thirst,
		"inventory": inventory_comp.serialize(),
		"equipment": equipment_comp.serialize(),
		"experience": experience
	}


func deserialize(data: Dictionary) -> void:
	global_position = StateValidation.vec3(data.position)
	_look = Vector2(0, IllustratedArt.CAMERA_PITCH)
	health_comp.deserialize({"current_health": data.health})
	survival_comp.deserialize(data)
	inventory_comp.deserialize(data.inventory)
	equipment_comp.deserialize(data.get("equipment", {}))
	equipment_comp.reconcile(inventory_comp)
	experience = clampi(int(data.get("experience", 0)), 0, 1000000)
	velocity = Vector3.ZERO
