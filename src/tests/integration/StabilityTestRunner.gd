extends Node
## Regression cases for real respawn/save/progression failures, using isolated saves.

var _passed := 0
var _failed := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveManagerGlobal.save_directory = "user://stability-test-saves/"
	call_deferred("_run")


func _check(value: bool, description: String) -> void:
	if value:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL: " + description)


func _run() -> void:
	GameManagerGlobal.new_game()
	while GameManagerGlobal.is_loading:
		await get_tree().process_frame
	for index in 2:
		await get_tree().process_frame
	await _test_respawn_save()
	_test_legacy_recipes()
	_test_invalid_states()
	await _test_loot_capacity()
	_test_failed_quit()
	for slot in [0, 1, SaveManagerGlobal.AUTOSAVE_SLOT]:
		SaveManagerGlobal.delete_save(slot)
	GameManagerGlobal.pause_game()
	for index in 2:
		await get_tree().process_frame
	print("STABILITY: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(1 if _failed else 0)


func _test_respawn_save() -> void:
	var player := GameManagerGlobal.get_player()
	var wood := GameManagerGlobal.world.get_node("beach_wood_1") as ResourceNode
	for index in wood.max_gathers:
		_check(wood.interact(player), "gather before depletion")
		wood._process(0.4)
	_check(not wood.can_interact(), "resource depleted")
	wood._process(wood.respawn_seconds + 0.01)
	_check(wood.can_interact(), "natural respawn restores resource")
	_check(float(wood.serialize().respawn_timer) >= 0, "respawn timer remains saveable")
	_check(StateValidation.state(GameManagerGlobal.snapshot()), "respawn preserves valid snapshot")
	SaveManagerGlobal.delete_save(0)
	_check(SaveManagerGlobal.save_game(0) == OK, "save succeeds after natural respawn")
	if not SaveManagerGlobal.load_game(0).is_empty():
		for index in 2:
			await get_tree().process_frame
		GameManagerGlobal.load_game(0)
		while GameManagerGlobal.is_loading:
			await get_tree().process_frame
		for index in 2:
			await get_tree().process_frame
		wood = GameManagerGlobal.world.get_node("beach_wood_1") as ResourceNode
		_check(wood.can_interact(), "respawned resource survives actual reload")
	# Keep later corruption cases independent of this regression's outcome.
	wood.deserialize({"gathers": 0, "is_depleted": false, "respawn_timer": 0})


func _test_legacy_recipes() -> void:
	for legacy in [[], ["stone_axe"], ["stone_axe", "unknown"]]:
		CraftingSystemGlobal.restore_known(legacy)
		for recipe in ["stone_axe", "campfire", "workbench", "forge"]:
			_check(
				CraftingSystemGlobal.is_recipe_known(recipe),
				"legacy save keeps progression " + recipe
			)
		_check(not CraftingSystemGlobal.is_recipe_known("unknown"), "unknown recipe filtered")


func _test_invalid_states() -> void:
	var snapshot := GameManagerGlobal.snapshot()
	_check(StateValidation.state(snapshot), "valid fixture before semantic corruption")
	var malformed := snapshot.duplicate(true)
	malformed.world.enemies.boar_shore.health = 0
	malformed.world.enemies.boar_shore.dead = false
	_check(not StateValidation.state(malformed), "zero-health active enemy rejected")
	malformed = snapshot.duplicate(true)
	malformed.quests.ending = "unknown-ending"
	_check(not StateValidation.state(malformed), "unknown ending cannot trap player")
	malformed = snapshot.duplicate(true)
	malformed.quests.states["unknown-quest"] = "active"
	_check(not StateValidation.state(malformed), "unknown quest rejected")
	malformed = snapshot.duplicate(true)
	malformed.quests.choices["kindling"] = "unknown-choice"
	_check(not StateValidation.state(malformed), "unknown quest choice rejected")
	_check(
		SaveManagerGlobal.save_game(1, malformed) == ERR_INVALID_DATA, "invalid state not written"
	)
	_check(GameManagerGlobal.snapshot() == snapshot, "invalid save cannot mutate live state")


func _test_failed_quit() -> void:
	var world := GameManagerGlobal.world
	SaveManagerGlobal._busy = true
	GameManagerGlobal.request_quit_to_main_menu()
	SaveManagerGlobal._busy = false
	_check(GameManagerGlobal.world == world, "failed quit-save retains current world")
	_check(GameManagerGlobal.ui._menu != "main", "failed quit-save does not return to title")
	if GameManagerGlobal.world == world:
		_check(GameManagerGlobal.save(0) == OK, "retained session can retry saving")


func _test_loot_capacity() -> void:
	var world := GameManagerGlobal.world as IslandWorld
	var enemy := world.get_node("boar_shore") as Enemy
	for index in IslandWorld.MAX_OBJECTS:
		world.spawn_pickup("wood", 1, Vector3(40, 0.1, 40))
	var kills_before := int(QuestSystemGlobal.kills.get("wild_boar", 0))
	enemy.health_comp.take_damage(1000, null, true)
	_check(
		enemy._pending_loot == {"raw_meat": 2, "hide": 2}, "full pickup cap retains all rolled loot"
	)
	GameManagerGlobal.world = null
	enemy._deliver_loot()
	GameManagerGlobal.world = world
	_check(enemy._pending_loot.size() == 2, "teardown cannot consume undelivered loot")
	_check(SaveManagerGlobal.save_game(0) == OK, "pending loot is saveable")
	await get_tree().process_frame
	GameManagerGlobal.load_game(0)
	while GameManagerGlobal.is_loading:
		await get_tree().process_frame
	world = GameManagerGlobal.world as IslandWorld
	enemy = world.get_node("boar_shore") as Enemy
	_check(enemy._pending_loot == {"raw_meat": 2, "hide": 2}, "pending loot survives reload")
	for index in 2:
		get_tree().get_nodes_in_group("pickups")[0].queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
		enemy._deliver_loot()
	_check(enemy._pending_loot.is_empty(), "retained loot delivered when capacity returns")
	var rewards: Dictionary = {}
	for pickup: ItemPickup in get_tree().get_nodes_in_group("pickups"):
		if pickup.item_id != "wood":
			rewards[pickup.item_id] = int(rewards.get(pickup.item_id, 0)) + pickup.count
	_check(rewards == {"raw_meat": 2, "hide": 2}, "retry neither loses nor duplicates rewards")
	_check(
		int(QuestSystemGlobal.kills.get("wild_boar", 0)) == kills_before + 1,
		"retry never rerolls kill credit"
	)
