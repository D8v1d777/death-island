extends RigidBody3D
class_name ItemPickup

signal picked_up(item_id: String, count: int)

@export var item_id: String = ""
@export var count: int = 1
@export var lifetime: float = 300.0  # 5 minutes

var _timer: float = 0.0
var _bob_offset: float = 0.0

func _ready() -> void:
	set_collision_layer_value(6, true)  # Pickup layer
	_timer = lifetime

	# Add visual
	_setup_visual()

	# Random initial rotation
	rotation.y = randf() * TAU

func _setup_visual() -> void:
	var mesh_instance = MeshInstance3D.new()
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 1.0, 0.2)
	material.emission_enabled = true
	material.emission_color = Color(1.0, 1.0, 0.2)
	material.emission_energy = 0.5

	mesh_instance.mesh = CubeMesh.new()
	(mesh_instance.mesh as CubeMesh).size = Vector3(0.3, 0.3, 0.3)
	mesh_instance.material_override = material
	add_child(mesh_instance)

	var collision = CollisionShape3D.new()
	collision.shape = BoxShape3D.new()
	(collision.shape as BoxShape3D).size = Vector3(0.3, 0.3, 0.3)
	add_child(collision)

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		queue_free()
		return

	# Bobbing animation
	_bob_offset += delta * 2.0
	global_position.y += sin(_bob_offset) * 0.005

	# Rotate
	rotate_y(delta * 0.5)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	# Keep upright
	var transform = state.transform
	transform.basis = transform.basis.orthonormalized()
	state.transform = transform

func set_item(p_item_id: String, p_count: int) -> void:
	item_id = p_item_id
	count = p_count

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_pickup(body)

func _pickup(player: Node3D) -> void:
	var inventory = player.get_node_or_null("InventoryComponent")
	if inventory:
		if inventory.add_item(item_id, count):
			picked_up.emit(item_id, count)
			queue_free()
			return

	# If inventory full, don't pick up
	LoggerGlobal.warn("Inventory full, cannot pick up %s" % item_id, "PICKUP")

func serialize() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y, global_position.z],
		"item_id": item_id,
		"count": count,
		"timer": _timer
	}

func deserialize(data: Dictionary) -> void:
	if data.has("position"):
		global_position = Vector3(data["position"])
	if data.has("item_id"):
		item_id = data["item_id"]
	if data.has("count"):
		count = data["count"]
	if data.has("timer"):
		_timer = data["timer"]