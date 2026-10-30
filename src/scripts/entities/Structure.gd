class_name Structure
extends StaticBody3D
## Placed stations and four-piece shelters are persisted as lightweight records.

var kind := "campfire"
var illustration: Sprite3D
var completed_visual := false


func _ready() -> void:
	add_to_group("structures")
	add_to_group("interactables")
	collision_layer = 16
	collision_mask = 0
	var height := 3.5 if kind in ["campfire", "forge", "workbench"] else 4.4
	var offset := Vector3.ZERO
	if kind == "roof":
		offset = IllustratedArt.SCREEN_UP * 2.1
	illustration = IllustratedArt.sprite(self, kind, height, offset)
	match kind:
		"workbench", "forge":
			LowPoly.collision(self, Vector3(2, 1, 1), Vector3(0, 0.5, 0))
		"wall":
			LowPoly.collision(self, Vector3(4, 2.5, 0.2), Vector3(0, 1.25, -2))
		"door":
			for side in [-1, 1]:
				LowPoly.collision(self, Vector3(1.2, 2.5, 0.2), Vector3(side * 1.4, 1.25, 2))


func can_interact() -> bool:
	return kind in ["campfire", "workbench", "forge", "foundation"]


func get_interaction_text() -> String:
	return "Rest at shelter" if kind == "foundation" else "Use " + kind.capitalize()


func interact(player: Player) -> void:
	if kind == "foundation":
		GameManagerGlobal.world.rest(player, self)
	else:
		GameManagerGlobal.open_menu("crafting")


func serialize() -> Dictionary:
	return {"kind": kind, "position": StateValidation.array3(global_position)}


func finish_shelter_visual() -> void:
	if completed_visual:
		return
	completed_visual = true
	illustration.hide()
	IllustratedArt.sprite(self, "shelter", 5.2)
