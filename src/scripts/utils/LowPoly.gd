class_name LowPoly
extends RefCounted
## Shared low-poly construction helpers. All art is generated from original shapes.


static func material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 1.0
	result.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	return result


static func box(parent: Node3D, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return add_mesh(parent, mesh, at, color)


static func cone(
	parent: Node3D, radius: float, height: float, at: Vector3, color: Color
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 6
	mesh.rings = 1
	return add_mesh(parent, mesh, at, color)


static func add_mesh(parent: Node3D, mesh: Mesh, at: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	# Godot 4.3's dummy renderer cannot release primitive mesh surface overrides.
	# Physics tests retain the same scene nodes and collisions, without GPU meshes.
	if DisplayServer.get_name() != "headless":
		instance.mesh = mesh
	instance.material_override = material(color)
	instance.position = at
	parent.add_child(instance)
	return instance


static func collision(parent: CollisionObject3D, size: Vector3, at: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var node := CollisionShape3D.new()
	node.shape = shape
	node.position = at
	parent.add_child(node)


static func label(parent: Node3D, text: String, at: Vector3, color: Color = Color.WHITE) -> Label3D:
	var node := Label3D.new()
	# Godot 4.3 frees Label3D's mesh before the dummy renderer releases its instance.
	# Retain label state for headless tests without binding that rendering-only base.
	if DisplayServer.get_name() == "headless":
		node.set_base(RID())
	node.text = text
	node.font_size = 42
	node.pixel_size = 0.008
	node.modulate = color
	node.position = at
	node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.no_depth_test = false
	parent.add_child(node)
	return node
