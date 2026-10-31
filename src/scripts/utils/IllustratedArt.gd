class_name IllustratedArt
extends RefCounted
## Camera-facing illustrations anchored at their feet on the physics plane.

const CAMERA_PITCH := -PI / 4.0
const SCREEN_UP := Vector3(0, 0.70710678, -0.70710678)


static func sprite(
	parent: Node3D, key: String, height: float, at: Vector3 = Vector3.ZERO, frames: int = 1
) -> Sprite3D:
	var node := Sprite3D.new()
	node.name = "Illustration"
	var texture: Texture2D = DataCatalogGlobal.art.textures.get(
		key, DataCatalogGlobal.art.textures.get("rock")
	)
	if DisplayServer.get_name() != "headless":
		node.texture = texture
	node.hframes = frames
	node.pixel_size = height / float(texture.get_height()) if texture else 1.0
	node.rotation.x = CAMERA_PITCH
	node.position = at + SCREEN_UP * height * 0.43
	node.shaded = false
	node.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	node.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	node.add_to_group("illustrations")
	parent.add_child(node)
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
