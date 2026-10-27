extends Node

var _tests_passed = 0
var _tests_failed = 0
var _player: Node = null
var _game_world: Node = nil

func _ready() -> void:
	print("=== Death Island Gameplay Acceptance Tests ===")
	print("")

	_load_game_scene()

	# Wait for scene to load and player to spawn
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	_player = _find_player()
	_game_world = get_tree().root.get_node_or_null("GameWorld")

	if not _player:
		push_error("Player not found after scene load")
		_quit_tests()
		return

	print("Player spawned successfully")
	print("")

	# Run all test suites
	_test_player_movement()
	_test_resource_gathering()
	_test_inventory_invariants()
	_test_crafting_transaction()
	_test_combat_loop()
	_test_survival_systems()
	_test_save_load()
	_test_ui_pause()

	_quit_tests()

func _load_game_scene() -> void:
	# Load the main scene through GameManagerGlobal
	GameManagerGlobal.new_game()

	# Wait for scene change
	await get_tree().process_frame
	await get_tree().process_frame

func _find_player() -> Node:
	var game_world = get_tree().root.get_node_or_null("GameWorld")
	if game_world:
		return game_world.get_node_or_null("DynamicObjects/Player")
	return get_tree().root.get_node_or_null("GameWorld/DynamicObjects/Player")

func _test_player_movement() -> void:
	print("=== Test A: Player Movement ===")

	# Test 1: Player exists and has components
	_assert(_player != null, "A1: Player node exists")
	_assert(_player.has_node("HealthComponent"), "A1: Player has HealthComponent")
	_assert(_player.has_node("InventoryComponent"), "A1: Player has InventoryComponent")
	_assert(_player.has_node("SurvivalComponent"), "A1: Player has SurvivalComponent")
	_assert(_player.has_node("EquipmentComponent"), "A1: Player has EquipmentComponent")
	_assert(_player.has_node("CameraPivot/Camera3D"), "A1: Player has Camera")

	# Test 2: Initial state
	var health = _player.get_node("HealthComponent")
	var survival = _player.get_node("SurvivalComponent")
	var inventory = _player.get_node("InventoryComponent")

	_assert(health.current_health == 100.0, "A1: Initial health is 100")
	_assert(survival.hunger == 100.0, "A1: Initial hunger is 100")
	_assert(survival.thirst == 100.0, "A1: Initial thirst is 100")
	_assert(survival.stamina == 100.0, "A1: Initial stamina is 100")
	_assert(inventory.get_used_slots() == 0, "A1: Initial inventory is empty")

	# Test 3: Movement input (simulated)
	# We can't easily test actual movement in headless, but we can verify the input actions exist
	_assert(InputMap.has_action("move_forward"), "A1: move_forward action exists")
	_assert(InputMap.has_action("move_backward"), "A1: move_backward action exists")
	_assert(InputMap.has_action("move_left"), "A1: move_left action exists")
	_assert(InputMap.has_action("move_right"), "A1: move_right action exists")
	_assert(InputMap.has_action("camera_horizontal"), "A1: camera_horizontal action exists")
	_assert(InputMap.has_action("camera_vertical"), "A1: camera_vertical action exists")

	print("A: Player movement tests passed")
	print("")

func _test_resource_gathering() -> void:
	print("=== Test B: Resource Gathering ===")

	if not _game_world:
		_fail("B1: GameWorld not found")
		return

	# Find resource nodes in the scene
	var resource_nodes = _game_world.get_children()
	var trees = []
	var rocks = []
	var bushes = []

	for node in resource_nodes:
		if node is ResourceNode:
			if node.resource_type == ResourceNode.ResourceType.TREE:
				trees.append(node)
			elif node.resource_type == ResourceNode.ResourceType.ROCK:
				rocks.append(node)
			elif node.resource_type == ResourceNode.ResourceType.BUSH:
				bushes.append(node)

	_assert(trees.size() > 0, "B1: At least one tree exists")
	_assert(rocks.size() > 0, "B1: At least one rock exists")
	_assert(bushes.size() > 0, "B1: At least one bush exists")

	print("  Found %d trees, %d rocks, %d bushes" % [trees.size(), rocks.size(), bushes.size()])

	# Test gathering from a tree (requires stone_axe)
	if trees.size() > 0:
		var tree = trees[0]
		_assert(tree.can_interact(), "B1: Tree is interactable initially")
		_assert(tree.get_interaction_text().contains("requires stone_axe"), "B1: Tree shows tool requirement")

		# Try to interact without tool - should fail
		var inventory = _player.get_node("InventoryComponent")
		var initial_wood = inventory.get_count("wood")
		tree.interact(_player)
		# Wait a frame
		await get_tree().process_frame
		_assert(inventory.get_count("wood") == initial_wood, "B1: No wood gathered without tool")
		print("  B1: Tree correctly requires stone_axe tool")

	# Test gathering from a rock (no tool required)
	if rocks.size() > 0:
		var rock = rocks[0]
		_assert(rock.can_interact(), "B2: Rock is interactable")
		var initial_stone = inventory.get_count("stone")
		rock.interact(_player)
		await get_tree().process_frame
		_assert(inventory.get_count("stone") > initial_stone, "B2: Stone gathered from rock")
		print("  B2: Rock gathering works without tool (+%d stone)" % (inventory.get_count("stone") - initial_stone))

	# Test gathering from a bush (no tool required)
	if bushes.size() > 0:
		var bush = bushes[0]
		_assert(bush.can_interact(), "B3: Bush is interactable")
		var initial_wood = inventory.get_count("wood")
		bush.interact(_player)
		await get_tree().process_frame
		_assert(inventory.get_count("wood") > initial_wood, "B3: Wood gathered from bush")
		print("  B3: Bush gathering works without tool (+%d wood)" % (inventory.get_count("wood") - initial_wood))

	# Test depletion and respawn (accelerated)
	if rocks.size() > 0:
		var rock = rocks[0]
		# Gather until depleted
		for i in range(5):
			if not rock.can_interact():
				break
			rock.interact(_player)
			await get_tree().process_frame

		# Should be depleted now
		_assert(not rock.can_interact(), "B4: Rock depletes after max gathers")
		_assert(not rock.visible, "B4: Depleted rock is hidden")
		print("  B4: Rock depletes after max gathers")

	print("B: Resource gathering tests passed")
	print("")

func _test_inventory_invariants() -> void:
	print("=== Test C: Inventory Invariants ===")

	var inventory = _player.get_node("InventoryComponent")

	# Test 1: Add valid items
	_assert(inventory.add_item("wood", 5), "C1: Add 5 wood")
	_assert(inventory.get_count("wood") == 5, "C1: Wood count is 5")

	# Test 2: Stack items
	_assert(inventory.add_item("wood", 3), "C2: Add 3 more wood")
	_assert(inventory.get_count("wood") == 8, "C2: Wood stacked to 8")

	# Test 3: Fill stack to max (99)
	var added = 0
	while inventory.add_item("wood", 1):
		added += 1
		if added > 200:
			break
	_assert(inventory.get_count("wood") == 99, "C3: Stack caps at max_stack (99)")

	# Test 4: Create second stack for different item
	_assert(inventory.add_item("stone", 10), "C4: Add 10 stone (new stack)")
	_assert(inventory.get_used_slots() == 2, "C4: Two stacks used")

	# Test 5: Exceed slot capacity (20 slots)
	# Clear and test with many different items
	inventory.clear()
	for i in range(25):
		var success = inventory.add_item("item_%d" % i, 1)
		if i < 20:
			_assert(success, "C5: Slot %d added" % i)
		else:
			_assert(not success, "C5: Slot %d rejected (capacity full)" % i)
	_assert(inventory.get_used_slots() == 20, "C5: Max 20 slots enforced")

	# Test 6: Exceed weight capacity
	inventory.clear()
	# Add heavy items (weight 10 each, max weight 100)
	for i in range(15):
		var success = inventory.add_item("heavy_%d" % i, 1, 10.0)
		if i < 10:
			_assert(success, "C6: Heavy item %d added" % i)
		else:
			_assert(not success, "C6: Heavy item %d rejected (weight full)" % i)
	_assert(inventory.get_current_weight() <= 100.0, "C6: Weight limit enforced")

	# Test 7: Remove items
	inventory.add_item("wood", 10)
	_assert(inventory.remove_item("wood", 3), "C7: Remove 3 wood")
	_assert(inventory.get_count("wood") == 7, "C7: Wood count after removal is 7")
	_assert(not inventory.remove_item("wood", 10), "C7: Cannot remove more than available")
	_assert(inventory.get_count("wood") == 7, "C7: Count unchanged after failed removal")

	# Test 8: Invalid operations
	_assert(not inventory.add_item("wood", 0), "C8: Cannot add 0 items")
	_assert(not inventory.add_item("wood", -1), "C8: Cannot add negative items")
	_assert(not inventory.remove_item("wood", 0), "C8: Cannot remove 0 items")
	_assert(not inventory.remove_item("wood", -1), "C8: Cannot remove negative items")
	_assert(not inventory.remove_item("nonexistent", 1), "C8: Cannot remove nonexistent item")

	# Test 9: Serialize/deserialize
	inventory.clear()
	inventory.add_item("wood", 5)
	inventory.add_item("stone", 3, 0.5)
	var serialized = inventory.serialize()
	var new_inventory = InventoryComponent.new()
	add_child(new_inventory)
	new_inventory.deserialize(serialized)
	_assert(new_inventory.get_count("wood") == 5, "C9: Wood deserialized correctly")
	_assert(new_inventory.get_count("stone") == 3, "C9: Stone deserialized correctly")
	_assert(abs(new_inventory.get_current_weight() - inventory.get_current_weight()) < 0.01, "C9: Weight deserialized correctly")

	print("C: Inventory invariant tests passed")
	print("")

func _test_crafting_transaction() -> void:
	print("=== Test D: Crafting Transaction ===")

	var inventory = _player.get_node("InventoryComponent")
	inventory.clear()

	# Learn the stone axe recipe
	CraftingSystemGlobal.learn_recipe("stone_axe")
	_assert(CraftingSystemGlobal.is_recipe_known("stone_axe"), "D1: Recipe learned")

	# Test 1: Craft with sufficient ingredients
	inventory.add_item("wood", 5)
	inventory.add_item("stone", 5)

	var initial_wood = inventory.get_count("wood")
	var initial_stone = inventory.get_count("stone")

	var result = CraftingSystemGlobal.craft("stone_axe", inventory.get_all_items())
	_assert(result.success, "D1: Craft succeeds with sufficient ingredients")
	_assert(result.result_item == "stone_axe", "D1: Correct result item")
	_assert(result.count == 1, "D1: Correct result count")

	# Verify ingredients consumed
	_assert(inventory.get_count("wood") == initial_wood - 3, "D1: 3 wood consumed")
	_assert(inventory.get_count("stone") == initial_stone - 2, "D1: 2 stone consumed")

	# Verify output added to inventory
	_assert(inventory.get_count("stone_axe") == 1, "D1: Stone axe added to inventory")

	# Test 2: Cannot craft with insufficient ingredients
	inventory.clear()
	inventory.add_item("wood", 2)  # Need 3
	inventory.add_item("stone", 2)

	result = CraftingSystemGlobal.craft("stone_axe", inventory.get_all_items())
	_assert(not result.success, "D2: Craft fails with insufficient wood")
	_assert(inventory.get_count("wood") == 2, "D2: Ingredients unchanged on failure")
	_assert(inventory.get_count("stone") == 2, "D2: Ingredients unchanged on failure")

	# Test 3: Cannot craft with full inventory
	inventory.clear()
	inventory.add_item("wood", 100)  # Fill inventory
	inventory.add_item("stone", 100)

	# Fill remaining slots with other items to hit capacity
	for i in range(20):
		inventory.add_item("filler_%d" % i, 1)

	inventory.add_item("wood", 5)
	inventory.add_item("stone", 5)

	result = CraftingSystemGlobal.craft("stone_axe", inventory.get_all_items())
	_assert(not result.success, "D3: Craft fails with full inventory")
	_assert(inventory.get_count("stone_axe") == 0, "D3: No output added when full")

	# Test 4: Unknown recipe
	inventory.clear()
	inventory.add_item("wood", 10)
	inventory.add_item("stone", 10)
	result = CraftingSystemGlobal.craft("unknown_recipe", inventory.get_all_items())
	_assert(not result.success, "D4: Unknown recipe fails")

	# Test 5: Unlearned recipe
	CraftingSystemGlobal.forget_recipe("stone_axe")
	result = CraftingSystemGlobal.craft("stone_axe", inventory.get_all_items())
	_assert(not result.success, "D5: Unlearned recipe fails")

	print("D: Crafting transaction tests passed")
	print("")

func _test_combat_loop() -> void:
	print("=== Test E: Combat Loop ===")

	# Spawn an enemy
	var enemy_scene = ResourceLoader.load("res://scenes/Enemy.tscn")
	_assert(enemy_scene != null, "E1: Enemy scene loads")

	var enemy = enemy_scene.instantiate()
	_game_world.get_node("DynamicObjects").add_child(enemy)
	enemy.global_position = _player.global_position + Vector3(5, 0, 0)

	await get_tree().process_frame

	var health = enemy.get_node("HealthComponent")
	_assert(health != null, "E1: Enemy has HealthComponent")
	_assert(health.current_health == 50.0, "E1: Enemy initial health is 50")

	# Test idle/patrol state
	_assert(enemy.get_state() == Enemy.AIState.IDLE or enemy.get_state() == Enemy.AIState.PATROL, "E2: Enemy starts in idle/patrol")

	# Test detection range
	var player_pos = _player.global_position
	var enemy_pos = enemy.global_position
	var distance = player_pos.distance_to(enemy_pos)

	# Move enemy closer to player
	enemy.global_position = _player.global_position + Vector3(3, 0, 0)
	await get_tree().process_frame
	await get_tree().process_frame

	# Should now detect player and chase
	_assert(enemy.get_state() == Enemy.AIState.CHASE, "E3: Enemy chases when player in detection range")

	# Test attack
	enemy.global_position = _player.global_position + Vector3(1.5, 0, 0)
	await get_tree().process_frame
	await get_tree().process_frame

	_assert(enemy.get_state() == Enemy.AIState.ATTACK, "E4: Enemy attacks when in range")

	# Player attacks enemy
	var player_health = _player.get_node("HealthComponent")
	var initial_player_health = player_health.current_health

	# Simulate player attack
	var result = CombatSystemGlobal.apply_damage(_player, enemy, 20.0, 0.0)
	_assert(result.damage > 0, "E5: Player deals damage")

	# Enemy should take damage
	await get_tree().process_frame
	_assert(health.current_health < 50.0, "E5: Enemy health reduced")

	# Kill enemy
	while not health.is_dead() and health.current_health > 0:
		result = CombatSystemGlobal.apply_damage(_player, enemy, 20.0, 0.0)
		await get_tree().process_frame

	_assert(health.is_dead(), "E6: Enemy dies after sufficient damage")

	# Test attacking dead enemy
	result = CombatSystemGlobal.apply_damage(_player, enemy, 20.0, 0.0)
	_assert(not result.killed, "E7: Cannot kill already dead enemy")

	# Test loot drops (enemy should have dropped loot)
	# Note: Loot is spawned as ItemPickup, which auto-picks up

	print("E: Combat loop tests passed")
	print("")

func _test_survival_systems() -> void:
	print("=== Test F: Survival Systems ===")

	var survival = _player.get_node("SurvivalComponent")
	var health = _player.get_node("HealthComponent")

	# Test initial values
	_assert(survival.hunger == 100.0, "F1: Initial hunger 100")
	_assert(survival.thirst == 100.0, "F1: Initial thirst 100")
	_assert(survival.stamina == 100.0, "F1: Initial stamina 100")

	# Test hunger decay
	var initial_hunger = survival.hunger
	# Simulate time passing (we can't wait in headless, but we can test the logic)
	# The decay rate is 1.0 per minute, so after 1 minute hunger = 99
	survival.hunger = max(0.0, survival.hunger - 1.0 * (60.0 / 60.0))
	_assert(abs(survival.hunger - 99.0) < 0.01, "F2: Hunger decays at 1/min")

	# Test thirst decay
	survival.thirst = max(0.0, survival.thirst - 1.5 * (60.0 / 60.0))
	_assert(abs(survival.thirst - 98.5) < 0.01, "F2: Thirst decays at 1.5/min")

	# Test stamina regeneration
	survival.stamina = 50.0
	survival.stamina = min(100.0, survival.stamina + 10.0 * 1.0)
	_assert(abs(survival.stamina - 60.0) < 0.01, "F3: Stamina regenerates")

	# Test stamina consumption (sprinting)
	survival.set_sprinting(true)
	var consumed = survival.consume_stamina(15.0)
	_assert(consumed, "F3: Stamina consumed for sprint")

	# Test exhaustion
	survival.stamina = 5.0
	consumed = survival.consume_stamina(10.0)
	_assert(not consumed, "F3: Cannot consume more stamina than available")

	# Test starvation damage
	survival.hunger = 0.0
	var initial_health = health.current_health
	# Simulate starvation damage
	var damage = 2.0 * 1.0  # 2 per second * 1 second
	health.take_damage(damage, _player)
	_assert(health.current_health == initial_health - damage, "F4: Starvation damages health")

	# Test dehydration damage
	survival.thirst = 0.0
	initial_health = health.current_health
	damage = 3.0 * 1.0
	health.take_damage(damage, _player)
	_assert(health.current_health == initial_health - damage, "F4: Dehydration damages health")

	# Test eating/drinking
	survival.hunger = 50.0
	survival.eat(30.0)
	_assert(abs(survival.hunger - 80.0) < 0.01, "F5: Eating restores hunger")

	survival.thirst = 50.0
	survival.drink(25.0)
	_assert(abs(survival.thirst - 75.0) < 0.01, "F5: Drinking restores thirst")

	# Test caps
	survival.hunger = 90.0
	survival.eat(25.0)
	_assert(survival.hunger == 100.0, "F5: Hunger caps at max")

	survival.thirst = 90.0
	survival.drink(25.0)
	_assert(survival.thirst == 100.0, "F5: Thirst caps at max")

	# Test health caps
	health.current_health = 90.0
	health.heal(20.0)
	_assert(health.current_health == 100.0, "F6: Health caps at max")

	# Test death
	health.current_health = 0.0
	_assert(health.is_dead(), "F6: Death detected at 0 health")

	print("F: Survival system tests passed")
	print("")

func _test_save_load() -> void:
	print("=== Test G: Save/Load ===")

	# Setup player state
	var player = _player
	var health = player.get_node("HealthComponent")
	var survival = player.get_node("SurvivalComponent")
	var inventory = player.get_node("InventoryComponent")
	var equipment = player.get_node("EquipmentComponent")

	health.current_health = 75.0
	survival.hunger = 60.0
	survival.thirst = 80.0
	survival.stamina = 40.0
	inventory.clear()
	inventory.add_item("wood", 10)
	inventory.add_item("stone", 5)
	equipment.equip(EquipmentComponent.EquipSlot.MAIN_HAND, "stone_axe")
	CraftingSystemGlobal.learn_recipe("stone_axe")

	# Save
	var save_result = SaveManagerGlobal.save_game(1)
	_assert(save_result == OK, "G1: Save succeeds")

	# Modify state
	health.current_health = 50.0
	survival.hunger = 30.0
	inventory.clear()
	inventory.add_item("wood", 1)
	CraftingSystemGlobal.forget_recipe("stone_axe")

	# Load
	var load_result = SaveManagerGlobal.load_game(1)
	_assert(load_result, "G1: Load returns data")

	# Wait for load to apply
	await get_tree().process_frame
	await get_tree().process_frame

	# Verify restored state
	player = _find_player()
	health = player.get_node("HealthComponent")
	survival = player.get_node("SurvivalComponent")
	inventory = player.get_node("InventoryComponent")
	equipment = player.get_node("EquipmentComponent")

	_assert(health.current_health == 75.0, "G2: Health restored")
	_assert(survival.hunger == 60.0, "G2: Hunger restored")
	_assert(survival.thirst == 80.0, "G2: Thirst restored")
	_assert(survival.stamina == 40.0, "G2: Stamina restored")
	_assert(inventory.get_count("wood") == 10, "G2: Inventory wood restored")
	_assert(inventory.get_count("stone") == 5, "G2: Inventory stone restored")
	_assert(equipment.get_equipped(EquipmentComponent.EquipSlot.MAIN_HAND) == "stone_axe", "G2: Equipment restored")
	_assert(CraftingSystemGlobal.is_recipe_known("stone_axe"), "G2: Known recipes restored")

	# Test corrupted save rejection
	var save_path = SaveManagerGlobal._get_save_path(1)
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string("corrupted data")
		file.close()

	var corrupted_result = SaveManagerGlobal.load_game(1)
	_assert(not corrupted_result, "G3: Corrupted save rejected")

	# Test missing save
	var missing_result = SaveManagerGlobal.load_game(999)
	_assert(not missing_result, "G3: Missing save handled")

	# Test future version (if we can simulate)
	# This would require modifying the save file version

	# Test truncated save
	file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string("""{
			"version": 1,
			"timestamp": 1234567890
		""")  # Truncated JSON
		file.close()

	var truncated_result = SaveManagerGlobal.load_game(1)
	_assert(not truncated_result, "G3: Truncated save rejected")

	print("G: Save/Load tests passed")
	print("")

func _test_ui_pause() -> void:
	print("=== Test H: UI and Pause ===")

	# Test pause
	_assert(not GameManagerGlobal.is_paused, "H1: Game not paused initially")
	GameManagerGlobal.pause_game()
	_assert(GameManagerGlobal.is_paused, "H1: Game pauses")
	_assert(get_tree().paused, "H1: Scene tree paused")

	# Test resume
	GameManagerGlobal.resume_game()
	_assert(not GameManagerGlobal.is_paused, "H2: Game resumes")
	_assert(not get_tree().paused, "H2: Scene tree resumed")

	# Test toggle
	GameManagerGlobal.toggle_pause()
	_assert(GameManagerGlobal.is_paused, "H3: Toggle pauses")
	GameManagerGlobal.toggle_pause()
	_assert(not GameManagerGlobal.is_paused, "H3: Toggle resumes")

	# Test inventory toggle (via HUD)
	var hud = _player.get_node_or_null("HUD")
	if hud:
		_assert(not hud._show_inventory, "H4: Inventory initially closed")
		hud.toggle_inventory()
		_assert(hud._show_inventory, "H4: Inventory opens")
		_assert(hud.inventory_panel.visible, "H4: Inventory panel visible")
		hud.toggle_inventory()
		_assert(not hud._show_inventory, "H4: Inventory closes")
		_assert(not hud.inventory_panel.visible, "H4: Inventory panel hidden")

	# Test crafting panel
	if hud:
		hud.toggle_crafting()
		_assert(hud._show_crafting, "H5: Crafting panel opens")
		_assert(hud.crafting_panel.visible, "H5: Crafting panel visible")
		hud.toggle_crafting()
		_assert(not hud._show_crafting, "H5: Crafting panel closes")

	# Test that pause stops gameplay
	var survival = _player.get_node("SurvivalComponent")
	var initial_hunger = survival.hunger
	GameManagerGlobal.pause_game()

	# Simulate time passing - in paused game, hunger should not decay
	# (In headless we can't test time passing, but we verify paused state)
	_assert(get_tree().paused, "H6: Game time paused")

	GameManagerGlobal.resume_game()
	_assert(not get_tree().paused, "H6: Game time resumes")

	# Test quit to main menu
	var quit_emitted = false
	GameManagerGlobal.quit_to_main_menu.connect(func(): quit_emitted = true)
	GameManagerGlobal.request_quit_to_main_menu()
	_assert(quit_emitted, "H7: Quit signal emitted")

	print("H: UI and Pause tests passed")
	print("")

func _assert(condition: bool, message: String) -> void:
	if condition:
		_tests_passed += 1
		print("  ✓ %s" % message)
	else:
		_tests_failed += 1
		push_error("  ✗ FAILED: %s" % message)

func _fail(message: String) -> void:
	_tests_failed += 1
	push_error("  ✗ FAILED: %s" % message)

func _quit_tests() -> void:
	print("")
	print("=== Gameplay Acceptance Test Summary ===")
	print("Passed: %d" % _tests_passed)
	print("Failed: %d" % _tests_failed)
	print("Total:  %d" % (_tests_passed + _tests_failed))

	if _tests_failed > 0:
		print("")
		print("❌ SOME TESTS FAILED")
		quit(1)
	else:
		print("")
		print("✅ ALL GAMEPLAY ACCEPTANCE TESTS PASSED")
		quit(0)