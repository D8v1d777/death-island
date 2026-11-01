extends Node
## End-to-end tests run real scenes, physics, transactions and save files.

var passed := 0
var failed := 0
var _player: Player
var _world: IslandWorld


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveManagerGlobal.save_directory = "user://test-saves/"
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: " + message)


func _run() -> void:
	GameManagerGlobal.new_game()
	while GameManagerGlobal.is_loading:
		await get_tree().process_frame
	_player = GameManagerGlobal.get_player()
	_world = GameManagerGlobal.world
	check(_player != null, "game creates player")
	if not _player:
		get_tree().quit(1)
		return
	await _test_physics_and_input()
	_test_gathering_crafting()
	await _test_combat()
	_test_progression()
	await _test_world_progression()
	var companion_tests := preload("res://tests/integration/CompanionTests.gd").new()
	add_child(companion_tests)
	await companion_tests.run(self)
	companion_tests.queue_free()
	await _test_persistence()
	await _test_pause_and_menus()
	_test_endings()
	for slot in range(-2, 10):
		SaveManagerGlobal.delete_save(slot)
	check(OS.get_environment("DEATH_ISLAND_TEST_FAIL") != "1", "intentional failure probe")
	print("INTEGRATION: %d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed else 0)


func _frames(count: int) -> void:
	for index in count:
		await get_tree().physics_frame


func _test_physics_and_input() -> void:
	await _frames(20)
	check(_player.is_on_floor(), "player lands on island geometry")
	check(
		_player.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "2.5D orthographic projection"
	)
	check(is_equal_approx(_player.camera_pivot.rotation.x, -PI / 4), "fixed angled camera")
	var start := _player.global_position
	Input.action_press("move_forward")
	await _frames(20)
	Input.action_release("move_forward")
	check(_player.global_position.z < start.z - 0.5, "forward input moves toward camera facing")
	check(get_tree().get_nodes_in_group("players").size() == 1, "exactly one player")
	for action in ["move_forward", "move_backward", "attack_light", "interact", "pause"]:
		check(not InputMap.action_get_events(action).is_empty(), "mapped input: " + action)
	var touch := InputEventScreenTouch.new()
	touch.index = 2
	touch.pressed = true
	touch.position = Vector2(160, 540)
	InputManagerGlobal._unhandled_input(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 2
	drag.position = Vector2(220, 540)
	InputManagerGlobal._input(drag)
	check(
		is_equal_approx(InputManagerGlobal.joystick_value.x, 0.5),
		"touch preserves analog magnitude"
	)
	touch.index = 3
	touch.position = Vector2(180, 550)
	InputManagerGlobal._unhandled_input(touch)
	check(InputManagerGlobal._joystick_finger == 2, "second finger cannot steal joystick")
	GameManagerGlobal.pause_game()
	check(InputManagerGlobal.joystick_value == Vector2.ZERO, "pause clears held input")
	GameManagerGlobal.resume_game()


func _test_gathering_crafting() -> void:
	_player.inventory_comp.clear()
	var wood := _world.get_node("beach_wood_1") as ResourceNode
	var stone := _world.get_node("beach_stone_1") as ResourceNode
	check(wood.interact(_player), "wood can be gathered without crafting deadlock")
	check(stone.interact(_player), "stone can be gathered by hand")
	stone._process(0.4)
	check(stone.interact(_player), "repeat gathering after cooldown")
	check(
		CraftingSystemGlobal.craft("stone_axe", _player.inventory_comp).success,
		"gather to craft loop"
	)
	check(_player.use_item("stone_axe"), "axe equipped from real inventory")
	check(_player.equipment_comp.has_working_tool("stone_axe"), "equipped tool is usable")
	var ore := _world.get_node("cliff_ore_1") as ResourceNode
	check(ore.interact(_player), "axe unlocks ore gathering")
	check(_player.illustration.action_name == "gather", "gathering drives the illustrated action")
	var condition := _player.equipment_comp.condition("stone_axe")
	_player.use_item("stone_axe")
	check(
		_player.equipment_comp.condition("stone_axe") == condition,
		"reequip cannot reset durability"
	)
	for index in 5:
		wood._process(0.4)
		wood.interact(_player)
	check(not wood.can_interact(), "node depletes after bounded gathers")
	var saved := wood.serialize()
	wood._process(200)
	check(wood.can_interact(), "node respawns")
	wood.deserialize(saved)
	check(not wood.can_interact(), "restoring depletion preserves timer and state")
	_player.inventory_comp.add_item("water", 1)
	_player.survival_comp.thirst = 40
	check(_player.use_item("water"), "water consumed")
	check(
		_player.illustration.action_name == "drink", "consuming water drives the illustrated action"
	)
	check(_player.survival_comp.thirst == 80, "water applies restoration")


func _test_combat() -> void:
	var enemy := _world.get_node("boar_shore") as Enemy
	_player.global_position = Vector3(24, 0.1, 22)
	enemy.global_position = _player.global_position + Vector3(0, 0, -2)
	_player._facing = Vector3.FORWARD
	await _frames(2)
	check(enemy.get_state() in [Enemy.AIState.CHASE, Enemy.AIState.WINDUP], "enemy detects player")
	_player.survival_comp.stamina = 100
	check(_player.attack(false), "light attack starts")
	check(_player.illustration.action_name == "attack", "combat drives the illustrated action")
	check(_player.survival_comp.stamina < 100, "attack spends stamina")
	check(
		enemy.health_comp.current_health < enemy.enemy_definition.max_health,
		"melee hits nearby enemy"
	)
	_player._attack_cooldown = 0
	_player.perform_action("dodge")
	check(_player.illustration.action_name == "dodge", "dodging drives the illustrated action")
	var health := _player.health_comp.current_health
	check(not _player.health_comp.take_damage(10), "dodge grants damage immunity")
	check(_player.health_comp.current_health == health, "dodged hit does not change health")
	enemy.health_comp.take_damage(1000, _player, true)
	check(enemy.get_state() == Enemy.AIState.DEAD, "enemy death state")
	check(get_tree().get_nodes_in_group("pickups").size() >= 2, "boar drops meat and hide")
	var kill_count := int(QuestSystemGlobal.kills.get("wild_boar", 0))
	enemy.health_comp.take_damage(1000, _player, true)
	check(
		int(QuestSystemGlobal.kills.get("wild_boar", 0)) == kill_count,
		"death rewards cannot duplicate"
	)
	for pickup: ItemPickup in get_tree().get_nodes_in_group("pickups").duplicate():
		pickup.interact(_player)
	check(_player.inventory_comp.has_item("raw_meat"), "meat loot collectable")
	await _frames(2)
	_player.global_position = Vector3(0, 0.1, 35)


func _test_progression() -> void:
	var inventory := _player.inventory_comp
	inventory.clear()
	inventory.add_item("wood", 40)
	inventory.add_item("stone", 35)
	inventory.add_item("fiber", 20)
	inventory.add_item("iron_ore", 15)
	check(_world.ISLAND.regions.size() == 5, "five authored regions")
	var before := _world.elapsed
	_world._process(1440)
	check(is_equal_approx(_world.elapsed - before, 1440), "one day is 24 minutes")
	check(CraftingSystemGlobal.craft("campfire", inventory).success, "campfire kit crafted")
	_player._facing = Vector3.RIGHT
	check(_world.place_structure("campfire_kit", _player), "campfire placed")
	inventory.add_item("raw_meat", 1)
	check(
		(
			CraftingSystemGlobal
			. craft(
				"cooked_meat", inventory, _world.nearby_station(_player.global_position, "campfire")
			)
			. success
		),
		"food processed at placed station"
	)
	QuestSystemGlobal.accept_quest()
	check(QuestSystemGlobal.complete_quest("share", inventory), "first quest shared outcome")
	check(QuestSystemGlobal.trust == 2, "choice changes trust")
	check(QuestSystemGlobal.recruit(), "trusted NPC can be recruited")
	QuestSystemGlobal.accept_quest()
	check(
		not QuestSystemGlobal.complete_quest("honest", inventory),
		"quest checks inventory requirements"
	)
	inventory.add_item("scrap", 3)
	check(QuestSystemGlobal.complete_quest("honest", inventory), "second quest hand-in")
	QuestSystemGlobal.accept_quest()
	inventory.add_item("crystal", 1)
	check(not QuestSystemGlobal.complete_quest("rescue", inventory), "guardian kill required")
	QuestSystemGlobal.record_kill("guardian")
	check(QuestSystemGlobal.complete_quest("rescue", inventory), "third quest complete")
	check(QuestSystemGlobal.trust == 6, "all shared choices accumulate trust")
	var completed := QuestSystemGlobal.serialize()
	check(not QuestSystemGlobal.complete_quest("rescue", inventory), "quest cannot pay twice")
	check(QuestSystemGlobal.serialize() == completed, "repeat hand-in leaves state unchanged")


func _test_persistence() -> void:
	_player.health_comp.deserialize({"current_health": 75})
	_player.survival_comp.hunger = 60
	_player.survival_comp.thirst = 80
	var snapshot := GameManagerGlobal.snapshot()
	for slot in range(-2, 10):
		SaveManagerGlobal.delete_save(slot)
		check(SaveManagerGlobal.save_game(slot, snapshot) == OK, "write slot %d" % slot)
		check(not SaveManagerGlobal.load_game(slot).is_empty(), "read slot %d" % slot)
	check(SaveManagerGlobal.list_saves().size() == 12, "10 manual + quicksave + autosave listed")
	check(
		SaveManagerGlobal.save_game(10, snapshot) == ERR_INVALID_PARAMETER, "invalid slot rejected"
	)
	check(SaveManagerGlobal.load_game(-3).is_empty(), "invalid load rejected")
	var new_snapshot := snapshot.duplicate(true)
	new_snapshot.player.health = 25
	check(SaveManagerGlobal.save_game(0, new_snapshot) == OK, "replacement write succeeds")
	var file := FileAccess.open(SaveManagerGlobal._get_save_path(0), FileAccess.WRITE)
	file.store_string("truncated")
	file.close()
	check(
		SaveManagerGlobal.load_game(0).player.health == 75,
		"corrupted primary recovers previous backup"
	)
	SaveManagerGlobal.delete_save(1)
	_write_fixture(1, snapshot, 99)
	check(SaveManagerGlobal.load_game(1).is_empty(), "future save version rejected")
	var malformed := snapshot.duplicate(true)
	malformed.player.position = [0, "bad", 0]
	_write_fixture(1, malformed, 2)
	check(
		SaveManagerGlobal.load_game(1).is_empty(), "valid checksum cannot bypass shape validation"
	)
	malformed = snapshot.duplicate(true)
	malformed.player.inventory = {"wood": -1}
	_write_fixture(1, malformed, 2)
	check(SaveManagerGlobal.load_game(1).is_empty(), "invalid inventory save rejected")
	malformed = snapshot.duplicate(true)
	malformed.player.experience = {"invalid": true}
	_write_fixture(1, malformed, 2)
	check(
		SaveManagerGlobal.load_game(1).is_empty(), "invalid experience rejected before live restore"
	)
	_write_fixture(1, snapshot, 1)
	check(
		SaveManagerGlobal.load_game(1).version == SaveManagerGlobal.SAVE_VERSION,
		"v1 migrates to current save version"
	)
	check(
		SaveManagerGlobal._calculate_checksum("123456789".to_utf8_buffer()) == 0xCBF43926,
		"CRC32 matches standard test vector"
	)
	_player.inventory_comp.clear()
	QuestSystemGlobal.reset()
	GameManagerGlobal.load_game(2)
	while GameManagerGlobal.is_loading:
		await get_tree().process_frame
	_player = GameManagerGlobal.get_player()
	_world = GameManagerGlobal.world
	check(_player.health_comp.current_health == 75, "load restores actual player health")
	check(is_equal_approx(_player.survival_comp.hunger, 60), "load restores hunger")
	check(
		_player.inventory_comp.serialize() == snapshot.player.inventory, "load restores inventory"
	)
	check(
		QuestSystemGlobal.trust == 6 and QuestSystemGlobal.recruited,
		"load restores trust and companion"
	)
	check(get_tree().get_nodes_in_group("structures").size() == 7, "stations and shelter persist")
	check(
		(_world.get_node("boar_shore") as Enemy).health_comp.is_dead(),
		"defeated enemy stays defeated"
	)
	check(
		get_tree().get_nodes_in_group("players").size() == 1,
		"load replaces rather than duplicates player"
	)


func _write_fixture(slot: int, state: Dictionary, version: int) -> void:
	var data := state.duplicate(true)
	data.version = version
	var bytes := JSON.stringify(data).to_utf8_buffer()
	var file := FileAccess.open(SaveManagerGlobal._get_save_path(slot), FileAccess.WRITE)
	file.store_32(SaveManagerGlobal.SAVE_MAGIC)
	file.store_16(version)
	file.store_32(SaveManagerGlobal._calculate_checksum(bytes))
	file.store_64(123456)
	file.store_buffer(bytes)
	file.close()


func _test_pause_and_menus() -> void:
	var hunger := _player.survival_comp.hunger
	GameManagerGlobal.open_menu("pause")
	await _frames(4)
	check(_player.survival_comp.hunger == hunger, "pause stops survival processing")
	check(GameManagerGlobal.ui._modal.visible, "pause modal visible")
	for menu in [
		"inventory",
		"crafting",
		"journal",
		"map",
		"settings",
		"save",
		"load",
		"dialogue",
		"beacon",
		"help"
	]:
		GameManagerGlobal.open_menu(menu)
		await get_tree().process_frame
		await get_tree().process_frame
		check(GameManagerGlobal.ui._content.get_child_count() > 1, "menu renders: " + menu)
	GameManagerGlobal.resume_game()
	check(not get_tree().paused, "resume works after paused UI")


func _test_endings() -> void:
	_player.inventory_comp.add_item("iron_ingot", 3)
	_player.inventory_comp.add_item("fiber", 2)
	var inventory := _player.inventory_comp.serialize()
	var quests := QuestSystemGlobal.serialize()
	check(
		QuestSystemGlobal.finish("together", _player.inventory_comp),
		"trusted rescue ending reachable"
	)
	check(QuestSystemGlobal.ending == "together", "ending recorded")
	check(
		not QuestSystemGlobal.finish("alone", _player.inventory_comp),
		"ending cannot be claimed twice"
	)
	QuestSystemGlobal.deserialize(quests)
	_player.inventory_comp.deserialize(inventory)
	check(QuestSystemGlobal.finish("stay", _player.inventory_comp), "stay ending reachable")
	QuestSystemGlobal.deserialize(quests)
	_player.inventory_comp.deserialize(inventory)
	QuestSystemGlobal.trust = -3
	check(
		not QuestSystemGlobal.finish("together", _player.inventory_comp),
		"low trust blocks shared rescue"
	)
	check(QuestSystemGlobal.finish("alone", _player.inventory_comp), "solo ending reachable")


func _test_world_progression() -> void:
	var inventory := _player.inventory_comp
	check(CraftingSystemGlobal.craft("workbench", inventory).success, "workbench craft")
	_player._facing = Vector3.LEFT
	check(_world.place_structure("workbench_kit", _player), "workbench placement")
	check(CraftingSystemGlobal.craft("forge", inventory, "workbench").success, "forge craft")
	_player._facing = Vector3.FORWARD
	check(_world.place_structure("forge_kit", _player), "forge placement")
	check(CraftingSystemGlobal.craft("iron_ingot", inventory, "forge", 3).success, "batch smelting")
	check(
		CraftingSystemGlobal.craft("iron_blade", inventory, "forge").success,
		"advanced weapon craft"
	)
	check(_player.use_item("iron_blade"), "advanced weapon equip")
	check(_player.equipment_comp.attack_damage() == 36, "advanced weapon increases damage")
	inventory.add_item("hide", 8)
	for recipe in ["hide_vest", "hide_hood", "hide_boots"]:
		check(
			CraftingSystemGlobal.craft(recipe, inventory, "workbench").success,
			"armor craft " + recipe
		)
		_player.use_item(recipe)
	check(_player.equipment_comp.armor() == 26, "complete hide set grants bonus")
	_player._facing = Vector3.BACK
	for part in ["foundation", "wall", "roof", "door"]:
		check(CraftingSystemGlobal.craft(part, inventory).success, "shelter craft " + part)
		check(_world.place_structure(part + "_kit", _player), "shelter placement " + part)
	var foundation: Structure
	for structure: Structure in get_tree().get_nodes_in_group("structures"):
		if structure.kind == "foundation":
			foundation = structure
	_player.health_comp.deserialize({"current_health": 30})
	check(_world.rest(_player, foundation), "completed shelter allows rest")
	check(_player.health_comp.current_health == 80, "rest heals player")
	for region in IslandWorld.ISLAND.regions:
		_player.global_position = region.center + Vector3.UP
		_world._update_region()
	check(_world.discovered.size() == 5, "all regions discoverable on foot")
	_player.global_position = Vector3(0, 0.1, 35)
	check(_world.fast_travel("jungle"), "travel to discovered safe region")
	check(_player.global_position.x == -25, "travel moves player to destination")
	_player.global_position = Vector3(0, 0.1, 35)
	var companion := _world.get_node("Mara") as Companion
	companion.global_position = Vector3(35, 0, 35)
	await _frames(2)
	check(
		companion.global_position.distance_to(Vector3(35, 0, 35)) < 1,
		"distance alone cannot teleport companion across regions"
	)
	var elapsed := _world.elapsed
	_world._process(IslandWorld.DAY_SECONDS * 3)
	check(is_equal_approx(_world.elapsed - elapsed, 4320), "three day/night cycles stay bounded")
