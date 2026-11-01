extends Node
## Compilation recovery: real resources, autoload/world lifecycle and save decoding.

var _passed := 0
var _failed := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveManagerGlobal.save_directory = "user://recovery-test-saves/"
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL: recovery: " + description)


func _run() -> void:
	_test_definitions()
	await _start_world()
	_test_world_bindings()
	await _test_npc_interaction()
	_test_save_decoding()
	var previous_world: WeakRef = weakref(GameManagerGlobal.world)
	await _start_world()
	_check(previous_world.get_ref() == null, "world replacement releases old signal source")
	_test_world_bindings()
	print("RECOVERY: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(1 if _failed else 0)


func _test_definitions() -> void:
	var definition := NPCDefinition.new()
	_check(not definition.is_field_valid("npc_id"), "empty NPC ID rejected")
	definition.npc_id = "marie_npc"
	_check(definition.is_field_valid("npc_id"), "NPC validator is callable outside editor")
	_check(not definition.get_property_list().is_empty(), "Resource inspector callback intact")
	for role in RoleDefinition.ROLE_CONFIGS:
		var actions: Array[String] = RoleDefinition.get_priority_actions(role)
		_check(not actions.is_empty(), "typed role actions: " + str(role))
	var crop_ids: Array[String] = CropDefinition.get_all_crop_ids()
	_check(crop_ids.size() == 4, "typed crop ID list")
	for crop_id in crop_ids:
		var crop := CropDefinition.create_from_id(crop_id)
		_check(crop != null and crop.crop_id == crop_id, "crop resource: " + crop_id)
	_check(BaseStorageGlobal.get_all_items() is Dictionary, "storage matches inventory contract")


func _start_world() -> void:
	GameManagerGlobal.new_game()
	while GameManagerGlobal.is_loading:
		await get_tree().process_frame
	await get_tree().process_frame


func _test_world_bindings() -> void:
	var world := GameManagerGlobal.world as IslandWorld
	_check(world != null, "authored world loads")
	_check(world.get_node_or_null("Mara") is Companion, "legacy companion remains active")
	for npc_id in ["marie_npc", "old_fisher"]:
		var npc := world.get_node_or_null(npc_id) as NPC
		_check(npc != null and npc.is_node_ready(), "generic NPC scene ready: " + npc_id)
		_check(npc.npc_comp.inventory_comp != null, "component ready before setup: " + npc_id)
		_check(npc.illustration.get_parent() == npc, "runtime illustration owner: " + npc_id)
		_check(PartySystemGlobal.get_npc_entity(npc_id) == npc, "registered NPC: " + npc_id)
		_check(npc.is_in_group("interactables"), "NPC body is interactable: " + npc_id)
		_check(not npc.npc_comp.is_in_group("interactables"), "component excluded from 3D scan")
	RelationshipSystemGlobal._connect_day_signal()
	_check(world.day_changed.get_connections().size() == 2, "one day callback per system")
	_check(FarmingSystemGlobal.get_all_plots().size() == 8, "world replacement has eight plots")
	RelationshipSystemGlobal.add_bond("marie_npc", 100, RelationshipSystemGlobal.BondSource.TRAVEL)
	var before := RelationshipSystemGlobal.get_bond_points("marie_npc")
	_check(
		not RelationshipSystemGlobal.add_bond(
			"marie_npc", 1, RelationshipSystemGlobal.BondSource.TRAVEL
		),
		"configured lowercase daily cap enforced"
	)
	world._process(IslandWorld.DAY_SECONDS)
	_check(
		RelationshipSystemGlobal.add_bond(
			"marie_npc", 1, RelationshipSystemGlobal.BondSource.TRAVEL
		),
		"day signal resets bond cap"
	)
	_check(RelationshipSystemGlobal.get_bond_points("marie_npc") == before + 1, "single bond gain")
	_check(
		is_equal_approx(FarmingSystemGlobal._world_minutes(), world.elapsed),
		"farming uses live elapsed time across midnight"
	)
	_check(FarmingSystemGlobal.get_plot_state_text("farm_plot_0") == "Empty", "plot text resolves")


func _test_npc_interaction() -> void:
	var npc := GameManagerGlobal.world.get_node("marie_npc") as NPC
	npc.interact(GameManagerGlobal.get_player())
	await get_tree().process_frame
	await get_tree().process_frame
	var hud := GameManagerGlobal.ui as HUD
	_check(hud._menu == "npc_dialogue", "NPC signal opens dialogue")
	_check(hud._current_npc_id == "marie_npc", "NPC identity set before deferred render")
	_check(hud._content.get_child_count() > 2, "NPC dialogue renders")
	var legacy_dialogue := QuestSystemGlobal.DIALOGUE
	var legacy_speaker: String = legacy_dialogue.speaker
	hud._open_talk_dialogue()
	_check(
		QuestSystemGlobal.DIALOGUE == legacy_dialogue and legacy_dialogue.speaker == legacy_speaker,
		"generic talk preserves legacy dialogue"
	)
	GameManagerGlobal.resume_game()


func _test_save_decoding() -> void:
	var snapshot := GameManagerGlobal.snapshot()
	for version in [1, 2, 3]:
		var data := snapshot.duplicate(true)
		data["version"] = version
		var json := JSON.stringify(data)
		var round_tripped: Dictionary = JSON.parse_string(json)
		var decoded := SaveManagerGlobal._decode(json.to_utf8_buffer(), version, 123)
		_check(not decoded.is_empty(), "decode save version " + str(version))
		_check(decoded.get("version") == SaveManagerGlobal.SAVE_VERSION, "current decoded version")
		_check(decoded.get("player") == round_tripped.player, "migration preserves player")
		_check(
			decoded.world.companion == round_tripped.world.companion,
			"migration preserves companion"
		)
	_check(SaveManagerGlobal.save_game(0) == OK, "v3 temporary write verifies")
	_check(not SaveManagerGlobal.load_game(0).is_empty(), "v3 disk round-trip")
	var malformed := snapshot.duplicate(true)
	malformed.world["relationships"] = []
	_check(
		SaveManagerGlobal._decode(JSON.stringify(malformed).to_utf8_buffer(), 2, 123).is_empty(),
		"wrong legacy relationship container rejected without runtime error"
	)
