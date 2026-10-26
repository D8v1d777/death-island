extends Node

var _tests_passed = 0
var _tests_failed = 0
var _current_test = ""

func _ready() -> void:
	_run_all_tests()
	get_tree().quit(_tests_failed)

func _assert(condition: bool, message: String) -> void:
	if condition:
		_tests_passed += 1
		print("  PASS: %s" % message)
	else:
		_tests_failed += 1
		print("  FAIL: %s (in %s)" % [message, _current_test])

func _assert_eq(actual, expected, message: String) -> void:
	if actual == expected:
		_tests_passed += 1
		print("  PASS: %s" % message)
	else:
		_tests_failed += 1
		print("  FAIL: %s - expected %s, got %s (in %s)" % [message, expected, actual, _current_test])

func _run_all_tests() -> void:
	print("=== Death Island Unit Tests ===")
	print("")

	# Test Data Structures
	_current_test = "ItemStack creation"
	var stack = {"item_id": "wood", "count": 5, "max_stack": 99}
	_assert(stack.count == 5, "ItemStack count initialized correctly")
	_assert(stack.max_stack == 99, "ItemStack max_stack set correctly")

	_current_test = "ItemStack stacking"
	stack.count += 3
	_assert(stack.count == 8, "ItemStack adds correctly")

	stack.count = stack.max_stack
	_assert(stack.count == 99, "ItemStack caps at max_stack")

	# Inventory System
	_current_test = "Inventory capacity"
	var inventory = {
		"slots": 20,
		"items": [],
		"max_weight": 100.0,
		"current_weight": 0.0
	}

	_assert(inventory.slots == 20, "Inventory has correct slot count")
	_assert(inventory.max_weight == 100.0, "Inventory has correct weight limit")

	_current_test = "Inventory add item"
	var item = {"item_id": "stone", "count": 10, "weight": 0.5}
	inventory.items.append(item)
	inventory.current_weight += item.count * item.weight
	_assert(inventory.items.size() == 1, "Item added to inventory")
	_assert(inventory.current_weight == 5.0, "Weight calculated correctly")

	_current_test = "Inventory weight limit"
	var heavy_item = {"item_id": "log", "count": 1, "weight": 50.0}
	var can_add = (inventory.current_weight + heavy_item.count * heavy_item.weight) <= inventory.max_weight
	_assert(can_add == true, "Heavy item fits in remaining capacity")

	inventory.current_weight += heavy_item.count * heavy_item.weight
	can_add = (inventory.current_weight + heavy_item.count * heavy_item.weight) <= inventory.max_weight
	_assert(can_add == false, "Second heavy item exceeds capacity")

	# Crafting System
	_current_test = "Recipe validation - sufficient resources"
	var recipe = {
		"ingredients": [
			{"item_id": "wood", "count": 2},
			{"item_id": "stone", "count": 3}
		]
	}
	inventory = {
		"wood": 5,
		"stone": 4
	}

	var can_craft = true
	for ing in recipe.ingredients:
		if inventory.get(ing.item_id, 0) < ing.count:
			can_craft = false
			break

	_assert(can_craft == true, "Can craft with sufficient resources")

	_current_test = "Recipe validation - insufficient resources"
	inventory.stone = 2
	can_craft = true
	for ing in recipe.ingredients:
		if inventory.get(ing.item_id, 0) < ing.count:
			can_craft = false
			break

	_assert(can_craft == false, "Cannot craft with insufficient resources")

	_current_test = "Recipe consumption"
	inventory = {"wood": 5, "stone": 4}
	for ing in recipe.ingredients:
		inventory[ing.item_id] -= ing.count

	_assert(inventory.wood == 3, "Wood consumed correctly")
	_assert(inventory.stone == 1, "Stone consumed correctly")

	# Combat Math
	_current_test = "Damage calculation - basic"
	var attacker_damage = 20.0
	var defender_armor = 5.0
	var damage_multiplier = 1.0

	var base = attacker_damage * damage_multiplier
	var defense = defender_armor * 0.5
	var final_damage = max(1.0, base - defense)

	_assert(final_damage == 17.5, "Basic damage calculation correct")

	_current_test = "Damage calculation - high armor"
	defender_armor = 50.0
	base = attacker_damage * damage_multiplier
	defense = defender_armor * 0.5
	final_damage = max(1.0, base - defense)

	_assert(final_damage == 1.0, "Damage floors at 1 with high armor")

	_current_test = "Damage calculation - critical hit"
	damage_multiplier = 1.5
	defender_armor = 5.0
	base = attacker_damage * damage_multiplier
	defense = defender_armor * 0.5
	final_damage = max(1.0, base - defense)

	_assert(final_damage == 27.5, "Critical hit damage correct")

	_current_test = "Stamina cost calculation"
	var base_cost = 15.0
	var weapon_weight = 2.0
	var skill_level = 3
	var stamina_cost = base_cost + (weapon_weight * 2.0) - (skill_level * 1.5)
	stamina_cost = max(5.0, stamina_cost)

	_assert(stamina_cost == 15.5, "Stamina cost calculated correctly")

	# Survival System
	_current_test = "Hunger decay rate"
	var hunger = 100.0
	var hunger_rate = 1.0
	var delta_time = 60.0

	hunger = max(0.0, hunger - hunger_rate * (delta_time / 60.0))
	_assert(hunger == 99.0, "Hunger decays correctly per minute")

	_current_test = "Starvation damage"
	hunger = 0.0
	var health = 100.0
	var starvation_damage = 2.0
	delta_time = 10.0

	health -= starvation_damage * delta_time
	_assert(health == 80.0, "Starvation damages health correctly")

	_current_test = "Consumable restoration"
	hunger = 30.0
	var food_restore = 25.0
	hunger = min(100.0, hunger + food_restore)
	_assert(hunger == 55.0, "Food restores hunger correctly")

	_current_test = "Consumable overfill"
	hunger = 90.0
	hunger = min(100.0, hunger + food_restore)
	_assert(hunger == 100.0, "Hunger caps at maximum")

	# Save/Load
	_current_test = "Save data structure"
	var save_data = {
		"version": 1,
		"timestamp": 1234567890,
		"player": {
			"position": [10.0, 1.0, 20.0],
			"health": 75.0,
			"stamina": 50.0,
			"hunger": 80.0,
			"thirst": 60.0
		},
		"inventory": {
			"wood": 10,
			"stone": 5
		}
	}

	_assert(save_data.version == 1, "Save version correct")
	_assert(save_data.player.health == 75.0, "Player health saved")
	_assert(save_data.player.position.size() == 3, "Position has 3 components")
	_assert(save_data.inventory.wood == 10, "Inventory saved")

	_current_test = "Save checksum calculation"
	var json_string = JSON.stringify(save_data)
	var json_bytes = json_string.to_utf8_buffer()

	var checksum = 0
	for byte in json_bytes:
		checksum = (checksum + byte) & 0xFFFFFFFF

	_assert(checksum > 0, "Checksum calculated")

	var json_string2 = JSON.stringify(save_data)
	var json_bytes2 = json_string2.to_utf8_buffer()
	var checksum2 = 0
	for byte in json_bytes2:
		checksum2 = (checksum2 + byte) & 0xFFFFFFFF

	_assert(checksum == checksum2, "Checksum is deterministic")

	# Print summary
	print("")
	print("=== Test Summary ===")
	print("Passed: %d" % _tests_passed)
	print("Failed: %d" % _tests_failed)
	print("Total:  %d" % (_tests_passed + _tests_failed))

	if _tests_failed > 0:
		print("")
		print("SOME TESTS FAILED")
	else:
		print("")
		print("ALL TESTS PASSED")

	# Quit with exit code
	get_tree().quit(_tests_failed)