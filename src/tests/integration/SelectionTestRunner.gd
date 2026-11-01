extends Node
## Real selection/switch ownership, save/load and invalid-state regressions.

var _passed := 0
var _failed := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveManagerGlobal.save_directory = "user://selection-test-saves/"
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL: selection: " + description)


func _run() -> void:
	GameManagerGlobal._ensure_ui()
	GameManagerGlobal.menu_requested.emit("main")
	await get_tree().process_frame
	await get_tree().process_frame
	var choice := GameManagerGlobal.ui._content.get_node("CharacterChoice") as OptionButton
	_check(choice.item_count == 2, "both survivors selectable")
	_check(choice.get_item_metadata(choice.selected) == "dave", "Dave default on title")
	GameManagerGlobal.new_game()
	while GameManagerGlobal.is_loading:
		await get_tree().process_frame
	var player := GameManagerGlobal.get_player()
	var world := GameManagerGlobal.world as IslandWorld
	_check(player.character_id == "dave", "new-game default")
	_check(world.get_node_or_null("dave_npc") == null, "no duplicate active Dave")
	player.inventory_comp.add_item("wood", 7)
	player.inventory_comp.add_item("stone_axe", 1)
	player.use_item("stone_axe")
	player.health_comp.deserialize({"current_health": 63})
	player.survival_comp.hunger = 54
	player.experience = 12
	var dave := player.serialize()
	_check(GameManagerGlobal.switch_character("marie"), "Dave to Marie")
	_check(GameManagerGlobal.get_player() == player, "stable Player/component ownership")
	_check(player.character_id == "marie", "Marie canonical identity")
	_check(player.illustration.art_key == "marie", "Marie illustration identity")
	_check(not player.inventory_comp.has_item("wood"), "separate character inventory")
	_check(world.get_node_or_null("marie_npc") == null, "no duplicate active Marie")
	_check(world.get_node_or_null("dave_npc") is NPC, "Dave becomes inactive survivor")
	_check(get_tree().get_nodes_in_group("players").size() == 1, "exactly one Player")
	player.inventory_comp.add_item("stone", 3)
	var marie := player.serialize()
	_check(not GameManagerGlobal.switch_character("invalid"), "unknown switch rejected")
	_check(player.serialize() == marie, "invalid switch leaves state intact")
	_check(SaveManagerGlobal.save_game(0) == OK, "save both character states")
	_check(GameManagerGlobal.load_game(0), "load switched voyage")
	while GameManagerGlobal.is_loading:
		await get_tree().process_frame
	player = GameManagerGlobal.get_player()
	_check(player.character_id == "marie", "load keeps active survivor")
	_check(PartySystemGlobal.get_controlled_character_id() == "marie", "party follows loaded ID")
	_check(GameManagerGlobal.switch_character("dave_npc"), "legacy NPC ID switches back")
	_check(player.inventory_comp.serialize() == dave.inventory, "Dave inventory survives reload")
	_check(player.equipment_comp.serialize() == dave.equipment, "Dave equipment survives reload")
	_check(player.health_comp.current_health == 63, "Dave health preserved")
	_check(player.survival_comp.hunger == 54, "Dave survival preserved")
	_check(player.experience == 12, "Dave experience preserved")
	_check(GameManagerGlobal.switch_character("marie"), "repeat switch")
	_check(player.inventory_comp.serialize() == marie.inventory, "Marie inventory preserved")
	var malformed := GameManagerGlobal.snapshot()
	malformed.world.npcs.dave_npc.player_state.health = "bad"
	_check(not StateValidation.state(malformed), "inactive state validated before load")
	player.health_comp.die()
	_check(not GameManagerGlobal.switch_character("dave"), "cannot escape death by switching")
	GameManagerGlobal.new_game("marie")
	while GameManagerGlobal.is_loading:
		await get_tree().process_frame
	_check(GameManagerGlobal.get_player().character_id == "marie", "direct Marie start")
	_check(
		GameManagerGlobal.world.get_node_or_null("marie_npc") == null, "Marie start no duplicate"
	)
	_check(GameManagerGlobal.switch_character("dave"), "fresh Marie to Dave")
	_check(
		GameManagerGlobal.get_player().inventory_comp.get_all_items().is_empty(),
		"new game resets packs"
	)
	print("SELECTION: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(1 if _failed else 0)
