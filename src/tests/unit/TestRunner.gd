extends Node
## Regression tests call production APIs, including failure/rollback paths.

var passed := 0
var failed := 0


func _ready() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: " + message)


func _run() -> void:
	_test_inventory()
	_test_crafting()
	_test_health_survival()
	_test_combat()
	_test_character_roster()
	print("UNIT: %d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed else 0)


func _test_inventory() -> void:
	var inventory := InventoryComponent.new()
	add_child(inventory)
	inventory.max_slots = 2
	inventory.max_weight = 200
	check(inventory.add_item("wood", 99), "first full stack")
	check(inventory.add_item("wood", 1), "overflow opens second stack")
	check(inventory.get_used_slots() == 2, "stack overflow counts slots")
	check(not inventory.add_item("stone", 1), "slot cap enforced")
	check(not inventory.remove_item("wood", -1), "negative removal rejected")
	check(not inventory.remove_item("wood", 0), "zero removal rejected")
	check(not inventory.add_item("unknown", 1), "unknown item rejected")
	check(inventory.get_count("wood") == 100, "failed operations leave inventory intact")
	inventory.clear()
	inventory.max_weight = 1
	check(inventory.add_item("stone", 2), "exact weight limit")
	check(not inventory.add_item("fiber"), "overweight insertion rejected")
	var before := inventory.serialize()
	check(not inventory.deserialize({"stone": -20}), "malformed save rejected")
	check(inventory.serialize() == before, "invalid restore is atomic")
	check(inventory.deserialize({"wood": {"count": 2, "weight": 0}}), "v1 count migration")
	check(inventory.get_current_weight() == 1.0, "saved weight cannot bypass definition")
	inventory.free()


func _test_crafting() -> void:
	var inventory := InventoryComponent.new()
	add_child(inventory)
	inventory.add_item("wood", 4)
	inventory.add_item("stone", 6)
	var result := CraftingSystemGlobal.craft("stone_axe", inventory, "", 2)
	check(result.success, "batch craft succeeds")
	check(inventory.get_count("stone_axe") == 2, "batch output committed")
	check(
		inventory.get_count("wood") == 0 and inventory.get_count("stone") == 0,
		"batch costs committed"
	)
	inventory.clear()
	inventory.add_item("wood", 2)
	inventory.add_item("stone", 3)
	var before := inventory.serialize()
	check(
		not CraftingSystemGlobal.craft("stone_axe", inventory, "", 2).success,
		"batch validates all costs"
	)
	check(inventory.serialize() == before, "failed batch preserves materials")
	check(
		not CraftingSystemGlobal.craft("stone_axe", inventory, "", 0).success, "zero batch rejected"
	)
	inventory.clear()
	inventory.add_item("raw_meat", 1)
	check(
		not CraftingSystemGlobal.craft("cooked_meat", inventory).success,
		"cooking requires a station"
	)
	check(
		CraftingSystemGlobal.craft("cooked_meat", inventory, "campfire").success,
		"cooking succeeds at station"
	)
	inventory.clear()
	inventory.max_slots = 2
	inventory.add_item("wood", 10)
	inventory.add_item("stone", 10)
	before = inventory.serialize()
	check(
		not CraftingSystemGlobal.craft("stone_axe", inventory).success,
		"full output capacity rejects crafting"
	)
	check(inventory.serialize() == before, "output failure rolls back costs")
	inventory.free()


func _test_health_survival() -> void:
	var health := HealthComponent.new()
	add_child(health)
	check(health.take_damage(10), "first hit is not invulnerable")
	check(not health.take_damage(10), "consecutive hit respects invulnerability")
	health.heal(-20)
	check(health.current_health == 90, "negative healing rejected")
	health.take_damage(100, null, true)
	check(health.is_dead(), "lethal damage kills")
	health.deserialize({"current_health": 75, "max_health": 100})
	check(not health.is_dead(), "loading living health resets death")
	check(health.take_damage(5), "restore resets hit timer")
	health.free()
	var survival := SurvivalComponent.new()
	add_child(survival)
	survival._process(60.0)
	check(is_equal_approx(survival.hunger, 99.0), "hunger is per minute")
	check(is_equal_approx(survival.thirst, 98.5), "thirst is per minute")
	check(not survival.consume_stamina(-5), "negative stamina cost rejected")
	survival.consume_stamina(25)
	survival._process(0.1)
	check(survival.stamina == 75, "regen delay after action")
	survival.free()


func _test_combat() -> void:
	check(CombatSystemGlobal.calculate_damage(20, 5) == 17.5, "armor damage math")
	check(CombatSystemGlobal.calculate_damage(20, 100) == 1, "minimum damage")
	check(CombatSystemGlobal.calculate_damage(20, 5, true) == 27.5, "critical damage")
	var target := Node3D.new()
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	target.add_child(health)
	add_child(target)
	check(
		CombatSystemGlobal.apply_damage(self, target, 10, 0, 0).damage == 10,
		"successful hit reports damage"
	)
	check(
		CombatSystemGlobal.apply_damage(self, target, 10, 0, 0).damage == 0,
		"blocked hit reports no damage"
	)
	health.take_damage(100, null, true)
	check(
		not CombatSystemGlobal.apply_damage(self, target, 10).killed,
		"already dead target cannot be killed twice"
	)
	target.free()


func _test_character_roster() -> void:
	check(CharacterRoster.has_character("dave"), "Dave profile is registered")
	check(CharacterRoster.has_character("MARIE"), "Marie lookup is case-insensitive")
	check(CharacterRoster.display_name("marie") == "Marie", "Marie display name resolves")
	check(CharacterRoster.art_key("dave") == "dave", "Dave resolves to dedicated art key")
	check(CharacterRoster.art_key("marie") == "marie", "Marie resolves to dedicated art key")
	check(CharacterRoster.normalize_id("unknown") == "dave", "unknown ID safely falls back to Dave")
	check(DataCatalogGlobal.art.textures.has("dave"), "Dave runtime texture is registered")
	check(DataCatalogGlobal.art.textures.has("marie"), "Marie runtime texture is registered")
