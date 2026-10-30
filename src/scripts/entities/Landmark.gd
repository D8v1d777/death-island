class_name Landmark
extends Node3D
## Authored landmark interaction routes to the gameplay coordinator.

var kind := "beacon"
var title := "Distress Beacon"


func _ready() -> void:
	add_to_group("interactables")
	var height := 4.0 if kind == "beacon" else 2.4
	IllustratedArt.sprite(self, "beacon" if kind == "beacon" else "sign", height)
	LowPoly.label(self, title, IllustratedArt.SCREEN_UP * (height + 0.1), Color("e6c786"))


func can_interact() -> bool:
	return true


func get_interaction_text() -> String:
	return "Use " + title


func interact(_player: Player) -> void:
	GameManagerGlobal.open_menu("beacon" if kind == "beacon" else "map")
