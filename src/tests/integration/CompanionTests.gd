extends Node
## Real world nodes and disk saves; fixtures isolate inventory and encounter state.

var suite: Node
var player: Player
var mara: Companion
var wood: ResourceNode


func run(runner: Node) -> void:
	suite = runner
	player = GameManagerGlobal.get_player()
	mara = GameManagerGlobal.world.get_node("Mara")
	wood = ResourceSystemGlobal.get_resource("beach_wood_2")
	var inventory := player.inventory_comp.serialize()
	player.inventory_comp.clear()
	player.global_position = Vector3(4, 0.1, 39)
	mara.global_position = wood.global_position + Vector3(0, 0.1, 1.5)
	wood.deserialize({})
	check(not mara.issue_command("invent"), "reject unknown command")
	check(not mara.issue_command("gather"), "reject absent resource")
	check(
		not mara.issue_command("gather", ResourceSystemGlobal.get_resource("cliff_ore_1")),
		"reject distant tool-gated resource"
	)
	var tool := wood.required_tool
	wood.required_tool = "stone_axe"
	check(not mara.issue_command("gather", wood), "reject nearby tool gate without equipment")
	wood.required_tool = tool
	check(not mara.inventory_comp.add_item("invented", 1), "reject invalid carry item")
	check(not mara.inventory_comp.add_item("wood", -1), "reject invalid carry count")
	check(mara.issue_command("gather", wood), "accept permitted node")
	await frames(2)
	check(mara.inventory_comp.get_count("wood") == 2, "physics gathers into companion pack")
	check(wood._gathers == 1, "real node consumes one gather")
	check(not wood.gather_into(mara.inventory_comp), "shared node cooldown blocks duplicate gather")
	await frames(120)
	check(not wood.can_interact(), "companion depletes finite node")
	check(
		player.inventory_comp.get_count("wood") + mara.inventory_comp.get_count("wood") == 8,
		"node pays exactly four base rewards"
	)
	mara.issue_command("hold")
	mara.inventory_comp.clear()
	player.inventory_comp.clear()
	_test_capacity()
	await _test_combat_interrupt()
	await _test_movement()
	await _test_blocked_path()
	await _test_save()
	player = GameManagerGlobal.get_player()
	mara = GameManagerGlobal.world.get_node("Mara")
	mara.issue_command("hold")
	player.inventory_comp.deserialize(inventory)
	suite._player = player
	suite._world = GameManagerGlobal.world


func _test_capacity() -> void:
	check(mara.inventory_comp.add_item("wood", 24), "carry accepts exact weight capacity")
	check(not mara.inventory_comp.add_item("wood", 1), "carry rejects excess weight")
	wood.deserialize({})
	check(not wood.gather_into(mara.inventory_comp), "full pack rejects gather")
	check(wood._gathers == 0, "full pack preserves node rewards")
	mara.inventory_comp.clear()
	check(
		mara.inventory_comp.add_item("hide_hood", Companion.CARRY_SLOTS),
		"stack limits use four carry slots"
	)
	check(not mara.inventory_comp.add_item("hide_hood", 1), "fifth stack rejected")
	mara.inventory_comp.clear()
	mara.inventory_comp.add_item("wood", 4)
	mara.global_position = player.global_position + Vector3.RIGHT
	player.inventory_comp.max_weight = 0.5
	check(mara.transfer_carried(player) == 1, "partial transfer fills available capacity")
	check(mara.inventory_comp.get_count("wood") == 3, "partial transfer preserves remainder")
	check(mara.transfer_carried(player) == 0, "full player inventory preserves carry")
	player.inventory_comp.max_weight = 100
	check(mara.transfer_carried(player) == 3, "remaining carry transfers when space available")
	check(mara.transfer_carried(player) == 0, "repeated transfer cannot duplicate")
	check(player.inventory_comp.get_count("wood") == 4, "transfer conserves total items")
	var observer := func():
		check(
			mara.inventory_comp.get_count("wood") + player.inventory_comp.get_count("wood") == 6,
			"inventory observers see an atomic two-pack transaction"
		)
	mara.inventory_comp.add_item("wood", 2)
	mara.inventory_comp.inventory_changed.connect(observer)
	mara.transfer_carried(player)
	mara.inventory_comp.inventory_changed.disconnect(observer)
	var pickup := IslandWorld.PICKUP_SCENE.instantiate() as ItemPickup
	pickup.position = Vector3(15, 0.1, 40)
	GameManagerGlobal.world.add_child(pickup)
	check(pickup.collect_into(mara.inventory_comp), "pickup enters companion carry")
	check(not pickup.interact(player), "same pickup cannot also reward player")
	check(not pickup.is_in_group("pickups"), "collected pickup excluded from save immediately")
	mara.inventory_comp.clear()


func _test_combat_interrupt() -> void:
	wood.deserialize({})
	mara.global_position = wood.global_position + Vector3(0, 0.1, 1.5)
	mara.issue_command("gather", wood)
	var enemy := GameManagerGlobal.world.get_node("boar_jungle") as Enemy
	var saved := enemy.serialize()
	enemy.global_position = mara.global_position + Vector3.RIGHT * 2
	enemy.set_physics_process(false)
	var health := enemy.health_comp.current_health
	await frames(2)
	check(mara.state == Companion.State.ASSIST, "danger interrupts gather")
	check(wood._gathers == 0, "no gathering reward during combat")
	check(enemy.health_comp.current_health < health, "assist damages real enemy")
	check(mara.command == "gather", "combat preserves prior order")
	enemy.deserialize(saved)
	enemy.set_physics_process(true)
	await frames(2)
	check(wood._gathers == 1, "safe gathering resumes after combat")
	mara._task_remaining = 0.01
	await frames(2)
	check(mara.command == "return", "expired task cancels safely to return")
	mara.issue_command("hold")


func _test_movement() -> void:
	player.global_position = Vector3(0, 0.1, 43)
	mara.global_position = Vector3(8, 0.1, 43)
	mara.issue_command("hold")
	await frames(15)
	check(absf(mara.global_position.x - 8) < 0.1, "hold stays in position")
	mara.issue_command("follow")
	await frames(75)
	check(mara.global_position.distance_to(player.global_position) < 3, "follow approaches on foot")
	var at := mara.global_position
	await frames(20)
	check(at.distance_to(mara.global_position) < 0.1, "follow arrival avoids jitter")
	mara.global_position = Vector3(8, 0.1, 43)
	mara.inventory_comp.clear()
	mara.inventory_comp.add_item("wood", 2)
	var before := player.inventory_comp.get_count("wood")
	mara.issue_command("return")
	await frames(80)
	check(player.inventory_comp.get_count("wood") == before + 2, "return walks and transfers")
	check(mara.command == "follow", "empty return resumes escort")


func _test_save() -> void:
	mara.issue_command("hold")
	mara.inventory_comp.add_item("stone", 3)
	var before := mara.serialize()
	var snapshot := GameManagerGlobal.snapshot()
	check(SaveManagerGlobal.save_game(8, snapshot) == OK, "save companion carry to disk")
	var invalid := snapshot.duplicate(true)
	invalid.world.companion.inventory = {"wood": 1000}
	check(
		SaveManagerGlobal.save_game(8, invalid) == ERR_INVALID_DATA, "reject oversized saved carry"
	)
	invalid.world.companion = {"command": "gather", "position": "broken"}
	check(not StateValidation.state(invalid), "reject malformed companion before world replacement")
	check(
		int(SaveManagerGlobal.load_game(8).world.companion.inventory.get("stone", 0)) == 3,
		"invalid save leaves previous valid file intact"
	)
	check(GameManagerGlobal.load_game(8), "load companion world")
	while GameManagerGlobal.is_loading:
		await get_tree().process_frame
	mara = GameManagerGlobal.world.get_node("Mara")
	check(mara.inventory_comp.serialize() == before.inventory, "load preserves carried resources")
	check(mara.command == "hold", "load preserves hold command")
	check(
		mara.global_position.distance_to(StateValidation.vec3(before.position)) < 0.1,
		"load preserves held position"
	)
	var legacy := snapshot.duplicate(true)
	legacy.world.erase("companion")
	check(SaveManagerGlobal.save_game(9, legacy) == OK, "old v2 save accepted without companion")
	check(GameManagerGlobal.load_game(9), "load legacy world")
	while GameManagerGlobal.is_loading:
		await get_tree().process_frame
	mara = GameManagerGlobal.world.get_node("Mara")
	check(
		mara.command == "follow" and mara.inventory_comp.serialize().is_empty(),
		"old save defaults to follow and empty carry"
	)


func _test_blocked_path() -> void:
	player.global_position = Vector3(0, 0.1, 43)
	mara.global_position = Vector3(8, 0.1, 43)
	var cage := Node3D.new()
	GameManagerGlobal.world.add_child(cage)
	for offset in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		var wall := StaticBody3D.new()
		wall.collision_layer = 16
		wall.position = mara.global_position + offset * 0.65
		cage.add_child(wall)
		LowPoly.collision(wall, Vector3(0.2, 3, 2) if offset.x else Vector3(2, 3, 0.2), Vector3.UP)
	mara.issue_command("return")
	await frames(340)
	check(mara.command == "hold", "blocked return cancels within watchdog bound")
	check(absf(mara.global_position.x - 8) < 1, "blocked path never teleports")
	cage.queue_free()
	await frames(2)


func frames(count: int) -> void:
	for index in count:
		await get_tree().physics_frame


func check(condition: bool, message: String) -> void:
	suite.check(condition, "companion: " + message)
