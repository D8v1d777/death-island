extends CanvasLayer
class_name HUD

@onready var health_bar: ProgressBar = $HealthBar
@onready var stamina_bar: ProgressBar = $StaminaBar
@onready var hunger_bar: ProgressBar = $HungerBar
@onready var thirst_bar: ProgressBar = $ThirstBar
@onready var interaction_label: Label = $InteractionLabel
@onready var pause_menu: Panel = $PauseMenu
@onready var inventory_panel: Panel = $InventoryPanel
@onready var inventory_grid: GridContainer = $InventoryPanel/InventoryGrid
@onready var crafting_panel: Panel = $CraftingPanel
@onready var crafting_list: VBoxContainer = $CraftingPanel/CraftingList

var _player: Node = null
var _is_paused: bool = false
var _show_inventory: bool = false
var _show_crafting: bool = false

func _ready() -> void:
	var current_scene = get_tree().current_scene
	if current_scene:
		_player = current_scene.get_node_or_null("Player")

	if _player:
		var health_comp = _player.get_node_or_null("HealthComponent")
		var survival_comp = _player.get_node_or_null("SurvivalComponent")
		var inventory_comp = _player.get_node_or_null("InventoryComponent")

		if health_comp:
			health_comp.health_changed.connect(_on_health_changed)
			_on_health_changed(health_comp.current_health, health_comp.max_health)

		if survival_comp:
			survival_comp.hunger_changed.connect(_on_hunger_changed)
			survival_comp.thirst_changed.connect(_on_thirst_changed)
			survival_comp.stamina_changed.connect(_on_stamina_changed)
			_on_hunger_changed(survival_comp.hunger)
			_on_thirst_changed(survival_comp.thirst)
			_on_stamina_changed(survival_comp.stamina)

		if inventory_comp:
			inventory_comp.inventory_changed.connect(_on_inventory_changed)
			_on_inventory_changed()

	# Connect signals
	GameManagerGlobal.game_paused.connect(_on_game_paused)
	GameManagerGlobal.game_resumed.connect(_on_game_resumed)
	$PauseMenu/PauseContainer/ResumeButton.pressed.connect(_on_resume_pressed)
	$PauseMenu/PauseContainer/SaveButton.pressed.connect(_on_save_pressed)
	$PauseMenu/PauseContainer/LoadButton.pressed.connect(_on_load_pressed)
	$PauseMenu/PauseContainer/QuitButton.pressed.connect(_on_quit_pressed)

	# Hide panels initially
	pause_menu.visible = false
	inventory_panel.visible = false
	crafting_panel.visible = false
	interaction_label.visible = false

func _process(delta: float) -> void:
	if not _player:
		return

	# Update interaction label
	var target = _player.get_interaction_target()
	if target and target.has_method("get_interaction_text"):
		var text = target.get_interaction_text()
		interaction_label.text = text
		interaction_label.visible = true
	else:
		interaction_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_TAB:
				toggle_inventory()
			KEY_C:
				toggle_crafting()
			KEY_ESCAPE:
				if _show_inventory:
					toggle_inventory()
				elif _show_crafting:
					toggle_crafting()
				else:
					GameManagerGlobal.toggle_pause()

func toggle_inventory() -> void:
	_show_inventory = not _show_inventory
	inventory_panel.visible = _show_inventory
	crafting_panel.visible = false
	_show_crafting = false
	_update_inventory_display()

func toggle_crafting() -> void:
	_show_crafting = not _show_crafting
	crafting_panel.visible = _show_crafting
	inventory_panel.visible = false
	_show_inventory = false
	_update_crafting_display()

func _on_game_paused() -> void:
	_is_paused = true
	pause_menu.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_game_resumed() -> void:
	_is_paused = false
	pause_menu.visible = false
	inventory_panel.visible = false
	crafting_panel.visible = false
	_show_inventory = false
	_show_crafting = false
	if _player:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_health_changed(current: float, max: float) -> void:
	health_bar.max_value = max
	health_bar.value = current

func _on_hunger_changed(value: float) -> void:
	hunger_bar.max_value = 100
	hunger_bar.value = value

func _on_thirst_changed(value: float) -> void:
	thirst_bar.max_value = 100
	thirst_bar.value = value

func _on_stamina_changed(value: float) -> void:
	stamina_bar.max_value = 100
	stamina_bar.value = value

func _on_inventory_changed() -> void:
	if _show_inventory:
		_update_inventory_display()

func _update_inventory_display() -> void:
	if not _player:
		return

	var inventory_comp = _player.get_node_or_null("InventoryComponent")
	if not inventory_comp:
		return

	# Clear grid
	for child in inventory_grid.get_children():
		child.queue_free()

	var items = inventory_comp.get_all_items()
	for item_id in items:
		var count = items[item_id]
		var label = Label.new()
		label.text = "%s x%d" % [item_id, count]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inventory_grid.add_child(label)

func _update_crafting_display() -> void:
	# Clear list
	for child in crafting_list.get_children():
		child.queue_free()

	var known = CraftingSystemGlobal.get_known_recipes()
	var inventory_comp = _player.get_node_or_null("InventoryComponent")
	var inventory = inventory_comp.get_all_items() if inventory_comp else {}

	for recipe_id in known:
		var recipe = CraftingSystemGlobal.get_recipe(recipe_id)
		if not recipe:
			continue

		var hbox = HBoxContainer.new()

		var name_label = Label.new()
		name_label.text = recipe.display_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_label)

		var can_craft = recipe.can_craft(inventory)
		var cost_text = ""
		for ing in recipe.ingredients:
			cost_text += "%s:%d " % [ing.item_id, ing.count]

		var cost_label = Label.new()
		cost_label.text = cost_text
		cost_label.add_theme_color_override("font_color", can_craft ? Color.GREEN : Color.RED)
		hbox.add_child(cost_label)

		var craft_btn = Button.new()
		craft_btn.text = "Craft"
		craft_btn.disabled = not can_craft
		craft_btn.pressed.connect(_on_craft_pressed.bind(recipe_id))
		hbox.add_child(craft_btn)

		crafting_list.add_child(hbox)

func _on_craft_pressed(recipe_id: String) -> void:
	var inventory_comp = _player.get_node_or_null("InventoryComponent")
	if not inventory_comp:
		return

	var recipe = CraftingSystemGlobal.get_recipe(recipe_id)
	if recipe == null:
		return
	var inventory = inventory_comp.get_all_items()
	var result = CraftingSystemGlobal.craft(recipe_id, inventory)
	if not result.get("success", false):
		return

	# CraftingSystemGlobal validates and consumes a snapshot. Apply the same
	# ingredient delta to the authoritative inventory before adding the result.
	for ingredient in recipe.ingredients:
		if not inventory_comp.remove_item(ingredient.item_id, ingredient.count):
			push_error("Inventory changed during crafting; refusing to add result")
			return

	var result_definition = ResourceLoader.load("res://resources/definitions/items/%s.tres" % result.result_item)
	var result_weight = result_definition.weight if result_definition else 0.1
	if not inventory_comp.add_item(result.result_item, result.count, result_weight):
		# Roll back ingredients if the result cannot fit.
		for ingredient in recipe.ingredients:
			var definition = ResourceLoader.load("res://resources/definitions/items/%s.tres" % ingredient.item_id)
			inventory_comp.add_item(ingredient.item_id, ingredient.count, definition.weight if definition else 0.1)
		push_warning("Not enough inventory capacity to hold the crafted item")
		return

	_update_inventory_display()
	_update_crafting_display()

func _on_resume_pressed() -> void:
	GameManagerGlobal.resume_game()

func _on_save_pressed() -> void:
	SaveManagerGlobal.save_game(0)
	LoggerGlobal.info("Game saved", "HUD")

func _on_load_pressed() -> void:
	var save_data = SaveManagerGlobal.load_game(0)
	if save_data:
		GameManagerGlobal.load_game(0)
		LoggerGlobal.info("Game loaded", "HUD")

func _on_quit_pressed() -> void:
	GameManagerGlobal.request_quit_to_main_menu()