class_name NPC
extends CharacterBody3D
## Generic NPC entity. Uses NPCComponent for all behavior.

var illustration: IllustratedActor
var player_state: Dictionary = {}

@onready var npc_comp: NPCComponent = $NPCComponent
@onready var health_comp: HealthComponent = $HealthComponent


func _ready() -> void:
	add_to_group("interactables")
	health_comp.died.connect(_on_died)


func setup(npc_id: String) -> void:
	self.name = npc_id
	npc_comp.setup(npc_id, self)
	illustration = npc_comp._illustration

	# Register with party system
	PartySystemGlobal.register_npc_entity(npc_id, self)


func _exit_tree() -> void:
	PartySystemGlobal.unregister_npc_entity(str(name))


func _on_died() -> void:
	# Check if NPC has Survivor role (damage immunity)
	if RoleDefinition.has_damage_immunity(npc_comp._get_role_enum()):
		health_comp.deserialize({"current_health": 1})
		health_comp.grant_immunity(5.0)
		GameManagerGlobal.message_posted.emit("%s shrugs off the fatal blow!" % name)
		return

	# Normal death
	GameManagerGlobal.message_posted.emit("%s has fallen!" % name)
	PartySystemGlobal.unregister_npc_entity(name)
	queue_free()


func set_role(role: String) -> void:
	npc_comp.set_role(role)


func get_role() -> String:
	return npc_comp.role


func get_status_text() -> String:
	return npc_comp.get_status_text()


func serialize() -> Dictionary:
	var data := npc_comp.serialize()
	data["player_state"] = player_state.duplicate(true)
	return data


func deserialize(data: Dictionary) -> bool:
	player_state = data.get("player_state", {}).duplicate(true)
	return npc_comp.deserialize(data)


func can_interact() -> bool:
	return npc_comp.can_interact()


func get_interaction_text() -> String:
	return npc_comp.get_interaction_text()


func interact(player: Player) -> void:
	npc_comp.interact(player)
