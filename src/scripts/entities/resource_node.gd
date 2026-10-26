extends StaticBody3D
class_name ResourceNode

signal gathered(item_id: String, count: int)
signal depleted

enum ResourceType {
	TREE,
	ROCK,
	BUSH,
	ORE
}

@export var resource_type: ResourceType = ResourceType.TREE
@export var item_id: String = "wood"
@export var base_count: int = 1
@export var tool_bonus: float = 1.0
@export var required_tool: String = ""  # e.g., "stone_axe" for trees
@export var max_gathers: int = 3
@export var respawn_time_min: float = 300.0
@export var respawn_time_max: float = 600.0

var _gathers: int = 0
var _is_depleted: bool = false
var _respawn_timer: float = 0.0

func _ready() -> void:
	set_collision_layer_value(4, true)  # ResourceNode layer

	# Auto-detect resource type from node name
	_detect_resource_type()

	# Register with resource system
	ResourceSystemGlobal.register_resource_node(self)

	# Set up visual based on type
	_setup_visual()

func _detect_resource_type() -> void:
	var name = get_name().to_lower()
	if name.begins_with("tree"):
		resource_type = ResourceType.TREE
	elif name.begins_with("rock"):
		resource_type = ResourceType.ROCK
	elif name.begins_with("bush"):
		resource_type = ResourceType.BUSH
	elif name.begins_with("ore"):
		resource_type = ResourceType.ORE

func _exit_tree() -> void:
	ResourceSystemGlobal.unregister_resource_node(self)

func _process(delta: float) -> void:
	if _is_depleted:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_respawn()

func _setup_visual() -> void:
	# Add a simple mesh based on resource type
	var mesh_instance = MeshInstance3D.new()
	var material = StandardMaterial3D.new()

	match resource_type:
		ResourceType.TREE:
			mesh_instance.mesh = CylinderMesh.new()
			(mesh_instance.mesh as CylinderMesh).height = 3.0
			(mesh_instance.mesh as CylinderMesh).bottom_radius = 0.5
			(mesh_instance.mesh as CylinderMesh).top_radius = 0.1
			material.albedo_color = Color(0.4, 0.25, 0.1)
			item_id = "wood"
			base_count = 2
			required_tool = "stone_axe"

		ResourceType.ROCK:
			mesh_instance.mesh = BoxMesh.new()
			(mesh_instance.mesh as BoxMesh).size = Vector3(1.5, 1.0, 1.5)
			material.albedo_color = Color(0.5, 0.5, 0.5)
			item_id = "stone"
			base_count = 2
			required_tool = ""

		ResourceType.BUSH:
			mesh_instance.mesh = SphereMesh.new()
			(mesh_instance.mesh as SphereMesh).radius = 0.8
			material.albedo_color = Color(0.2, 0.6, 0.2)
			item_id = "wood"
			base_count = 1
			required_tool = ""

		ResourceType.ORE:
			mesh_instance.mesh = BoxMesh.new()
			(mesh_instance.mesh as BoxMesh).size = Vector3(1.0, 1.0, 1.0)
			material.albedo_color = Color(0.6, 0.4, 0.2)
			item_id = "stone"
			base_count = 3
			required_tool = "stone_axe"

	mesh_instance.material_override = material
	add_child(mesh_instance)
	mesh_instance.position = Vector3(0, mesh_instance.get_aabb().size.y / 2.0, 0)

	# Add collision shape
	var collision = CollisionShape3D.new()
	collision.shape = mesh_instance.mesh.create_trimesh_shape()
	collision.position = Vector3(0, mesh_instance.get_aabb().size.y / 2.0, 0)
	add_child(collision)

func can_interact() -> bool:
	return not _is_depleted

func get_interaction_text() -> String:
	var tool_text = ""
	if required_tool != "":
		tool_text = " (requires %s)" % required_tool
	return "Gather %s%s" % [item_id, tool_text]

func interact(player: Node) -> void:
	if _is_depleted:
		return

	var inventory = player.get_node_or_null("InventoryComponent")
	var equipment = player.get_node_or_null("EquipmentComponent")

	# Check tool requirement
	if required_tool != "":

		var has_tool = false
		if inventory and inventory.has_item(required_tool):
			has_tool = true
		if equipment and equipment.has_equipped(EquipmentComponent.EquipSlot.MAIN_HAND):
			if equipment.get_equipped(EquipmentComponent.EquipSlot.MAIN_HAND) == required_tool:
				has_tool = true

		if not has_tool:
			# Show message
			var hud = player.get_node_or_null("HUD")
			if hud:
				hud.interaction_label.text = "Requires %s" % required_tool
			return

	var bonus = 1.0
	if required_tool != "" and inventory and (inventory.has_item(required_tool) or (equipment and equipment.get_equipped(EquipmentComponent.EquipSlot.MAIN_HAND) == required_tool)):
		bonus = tool_bonus

	var item_weight = _get_item_weight(item_id)
	var expected_count = max(1, int(base_count * bonus))
	if inventory and not inventory.can_add_item(item_id, expected_count, item_weight):
		var hud = player.get_node_or_null("HUD")
		if hud:
			hud.interaction_label.text = "Inventory full"
		return

	var count = ResourceSystemGlobal.gather_resource(self, item_id, base_count, bonus)
	if inventory and not inventory.add_item(item_id, count, item_weight):
		push_error("Resource gather was rejected after capacity preflight")
		return

	_gathers += 1
	if _gathers >= max_gathers:
		_deplete()
	gathered.emit(item_id, count)

	# Visual feedback
	_play_gather_effect()

func _get_item_weight(p_item_id: String) -> float:
	var definition = ResourceLoader.load("res://resources/definitions/items/%s.tres" % p_item_id)
	return definition.weight if definition else 0.1

func _play_gather_effect() -> void:
	# Simple visual feedback - scale down and up
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(0.8, 0.8, 0.8), 0.1)
	tween.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.1)

func _deplete() -> void:
	_is_depleted = true
	visible = false
	collision_layer = 0
	set_physics_process(false)
	_respawn_timer = randf_range(respawn_time_min, respawn_time_max)
	depleted.emit()

func _respawn() -> void:
	_is_depleted = false
	_gathers = 0
	visible = true
	collision_layer = 8  # ResourceNode is physics layer 4
	set_physics_process(true)
	ResourceSystemGlobal.respawn_resource(self)

func serialize() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y, global_position.z],
		"resource_type": resource_type,
		"gathers": _gathers,
		"is_depleted": _is_depleted,
		"respawn_timer": _respawn_timer
	}

func deserialize(data: Dictionary) -> void:
	if data.has("position"):
		global_position = Vector3(data["position"])
	if data.has("resource_type"):
		resource_type = data["resource_type"]
	if data.has("gathers"):
		_gathers = data["gathers"]
	if data.has("is_depleted"):
		_is_depleted = data["is_depleted"]
	if data.has("respawn_timer"):
		_respawn_timer = data["respawn_timer"]

	if _is_depleted:
		_deplete()
	else:
		_respawn()