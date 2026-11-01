class_name HUD
extends CanvasLayer
## Responsive presentation. Every button requests a gameplay-system operation.

const THEME = preload("res://resources/IslandTheme.tres")
const COPY = preload("res://resources/UICopy.tres")
const TOUCH_SCRIPT = preload("res://scripts/ui/TouchControls.gd")
const VITAL_COLORS := [Color("dd8074"), Color("dfc071"), Color("9cbf79"), Color("7ac4d4")]

var _root: Control
var _gameplay: Control
var _modal: PanelContainer
var _content: VBoxContainer
var _scroll: ScrollContainer
var _status: Label
var _prompt: Label
var _toast: Label
var _bars: Array[ProgressBar] = []
var _bar_labels: Array[Label] = []
var _menu := "main"
var _toast_time := 0.0
var _refresh_time := 0.0
var _dialogue_text := ""
var _loading_label: Label
var _selected_character := "dave"
var _current_npc_id: String = ""
var _npc_dialogue_mode: String = "main"  # main, talk, configure


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = THEME.duplicate()
	_root.set_meta("base_font_size", _root.theme.default_font_size)
	add_child(_root)
	_build_hud()
	_modal = PanelContainer.new()
	_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal.anchor_left = 0.12
	_modal.anchor_right = 0.88
	_modal.anchor_top = 0.06
	_modal.anchor_bottom = 0.94
	_root.add_child(_modal)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_modal.add_child(_scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_content)
	_toast = Label.new()
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_left = -400
	_toast.offset_right = 400
	_toast.offset_top = 6
	_toast.offset_bottom = 42
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_color_override("font_color", Color("ffda93"))
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_toast)
	GameManagerGlobal.menu_requested.connect(show_menu)
	GameManagerGlobal.message_posted.connect(_show_message)
	GameManagerGlobal.game_ready.connect(_bind_player)
	GameManagerGlobal.loading_changed.connect(_loading_progress)
	QuestSystemGlobal.dialogue_posted.connect(_on_dialogue)
	QuestSystemGlobal.quests_changed.connect(_refresh_menu)
	show_menu("main")


func _build_hud() -> void:
	_gameplay = Control.new()
	_gameplay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gameplay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_gameplay)
	var stats := VBoxContainer.new()
	stats.position = Vector2(24, 24)
	stats.custom_minimum_size = Vector2(220, 0)
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gameplay.add_child(stats)
	for index in 4:
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(220, 22)
		bar.show_percentage = false
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = VITAL_COLORS[index]
		style.corner_radius_top_left = 4
		style.corner_radius_bottom_left = 4
		bar.add_theme_stylebox_override("fill", style)
		stats.add_child(bar)
		var label := Label.new()
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color("13262c"))
		bar.add_child(label)
		_bars.append(bar)
		_bar_labels.append(label)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 16)
	stats.add_child(_status)
	var navigation := HBoxContainer.new()
	navigation.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	navigation.offset_left = -504
	navigation.offset_top = 24
	navigation.offset_right = -24
	_gameplay.add_child(navigation)
	for entry in [
		["PACK", "inventory"],
		["CRAFT", "crafting"],
		["QUESTS", "journal"],
		["MAP", "map"],
		["PAUSE", "pause"]
	]:
		var button := _button(navigation, entry[0], GameManagerGlobal.handle_action.bind(entry[1]))
		button.custom_minimum_size = Vector2(84, 72)
		button.add_theme_font_size_override("font_size", 16)
	_prompt = Label.new()
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_prompt.offset_left = -340
	_prompt.offset_right = 340
	_prompt.offset_top = 65
	_prompt.offset_bottom = 105
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_color_override("font_color", Color("ffe0a1"))
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gameplay.add_child(_prompt)
	var touch := Control.new()
	touch.set_script(TOUCH_SCRIPT)
	touch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gameplay.add_child(touch)
	var quick := HBoxContainer.new()
	quick.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	quick.offset_left = -210
	quick.offset_right = 210
	quick.offset_top = -82
	quick.offset_bottom = -10
	_gameplay.add_child(quick)
	for entry in [
		["1 · Eat", "quick_food"],
		["2 · Drink", "quick_water"],
		["3 · Heal", "quick_heal"],
		["4 · Equip", "quick_weapon"]
	]:
		var button := _button(quick, entry[0], GameManagerGlobal.handle_action.bind(entry[1]))
		button.add_theme_font_size_override("font_size", 16)


func _bind_player() -> void:
	var player := GameManagerGlobal.get_player()
	if player:
		player.inventory_comp.inventory_changed.connect(_refresh_menu)
		player.equipment_comp.equipment_changed.connect(_on_equipment)


func _unhandled_input(event: InputEvent) -> void:
	for action in ["pause", "inventory", "crafting", "journal"]:
		if event.is_action_pressed(action):
			GameManagerGlobal.handle_action(action)
			get_viewport().set_input_as_handled()
			return


func _process(delta: float) -> void:
	_toast_time -= delta
	_toast.visible = _toast_time > 0
	_refresh_time -= delta
	if _refresh_time > 0:
		return
	_refresh_time = 0.1
	var player := GameManagerGlobal.get_player()
	if not player:
		return
	var values := [
		player.health_comp.current_health,
		player.survival_comp.stamina,
		player.survival_comp.hunger,
		player.survival_comp.thirst
	]
	var names := ["HEALTH", "STAMINA", "HUNGER", "THIRST"]
	for index in 4:
		_bars[index].value = values[index]
		_bar_labels[index].text = "%s   %d / 100" % [names[index], roundi(values[index])]
	_status.text = (
		"%s · %s\n%s"
		% [
			CharacterRoster.display_name(player.character_id).to_upper(),
			GameManagerGlobal.world.get_time_string(),
			GameManagerGlobal.world.current_region.capitalize()
		]
	)
	if GameManagerGlobal.last_save_failed:
		_status.text += "\nSAVE FAILED · retry in Pause"
	var target := player.get_interaction_target()
	_prompt.text = "E / GATHER · " + target.get_interaction_text() if target else ""


func show_menu(menu: String) -> void:
	_menu = menu
	_gameplay.visible = menu.is_empty()
	_modal.visible = not menu.is_empty()
	if not menu.is_empty():
		call_deferred("_render_menu")


func _refresh_menu() -> void:
	if _menu in ["inventory", "crafting", "dialogue", "journal", "npc_dialogue", "npc_configure"]:
		call_deferred("_render_menu")


func _on_equipment(_slot: String, _item: String) -> void:
	_refresh_menu()


func _render_menu() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_loading_label = null
	var title := _menu.replace("_", " ").to_upper()
	if _menu == "main":
		title = "DEATH ISLAND"
	var header := HBoxContainer.new()
	_content.add_child(header)
	var label := _text(header, title, 32)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _menu not in ["main", "loading", "death", "ending"]:
		_button(header, "Back", _back)
	match _menu:
		"main":
			_main_menu()
		"pause":
			_pause_menu()
		"confirm_quit":
			_text(_content, "Saving failed. Leave this voyage and lose unsaved progress?")
			_button(
				_content,
				"Leave without saving",
				GameManagerGlobal.request_quit_to_main_menu.bind(true)
			)
		"inventory":
			_inventory_menu()
		"crafting":
			_crafting_menu()
		"journal":
			_journal_menu()
		"map":
			_map_menu()
		"save", "load":
			_slots_menu()
		"settings":
			_settings_menu()
		"dialogue":
			_dialogue_menu()
		"npc_dialogue":
			_npc_dialogue_menu()
		"npc_configure":
			_npc_configure_menu()
		"beacon":
			_beacon_menu()
		"death":
			_text(_content, "The island claimed another night. Your last living save is safe.")
			_button(_content, "Load a save", GameManagerGlobal.open_menu.bind("load"))
			_button(_content, "Return to title", GameManagerGlobal.request_quit_to_main_menu)
		"ending":
			_text(
				_content, QuestSystemGlobal.DIALOGUE.endings.get(QuestSystemGlobal.ending, ""), 24
			)
			_text(
				_content,
				"Thank you for playing Death Island. Original code, narrative and low-poly art."
			)
			_button(_content, "Return to title", GameManagerGlobal.request_quit_to_main_menu)
		"loading":
			_loading_label = _text(_content, "Preparing the island…", 24)
			_text(
				_content,
				"Start with driftwood and stone. Craft an axe, find fresh water, and talk to Mara."
			)
		"help":
			_text(_content, COPY.text.guide)
	var first := _content.find_children("*", "Button", true, false)
	if not first.is_empty():
		first[0].grab_focus()
	apply_text_scale()


func apply_text_scale() -> void:
	if not is_instance_valid(_root):
		return
	var scale_factor := clampf(float(GameManagerGlobal.settings.text_scale), 1.0, 1.4)
	_root.theme.default_font_size = roundi(int(_root.get_meta("base_font_size")) * scale_factor)
	for control: Control in _root.find_children("*", "Control", true, false):
		if control.has_theme_font_size_override("font_size"):
			if not control.has_meta("base_font_size"):
				control.set_meta("base_font_size", control.get_theme_font_size("font_size"))
			control.add_theme_font_size_override(
				"font_size", roundi(int(control.get_meta("base_font_size")) * scale_factor)
			)
	for button: Button in _content.find_children("*", "Button", true, false):
		button.custom_minimum_size.x = 90 * scale_factor


func _main_menu() -> void:
	_text(_content, "THE TIDE TOOK EVERYTHING. WHAT WILL YOU KEEP?", 20)
	_text(_content, COPY.text.intro)
	_text(
		_content, "You begin as Dave. Meet others, earn their trust, and choose who survives.", 18
	)
	_button(_content, "New voyage", func(): GameManagerGlobal.new_game("dave"))
	_button(_content, "Continue / Load", GameManagerGlobal.open_menu.bind("load"))
	_button(_content, "Settings", GameManagerGlobal.open_menu.bind("settings"))
	_button(_content, "Controls & survival guide", GameManagerGlobal.open_menu.bind("help"))
	_text(_content, "DEVELOPMENT BUILD · 0.3.0 · Illustrated 2.5D", 16)


func _pause_menu() -> void:
	_button(_content, "Resume voyage", GameManagerGlobal.resume_game)
	_button(_content, "Save game", GameManagerGlobal.open_menu.bind("save"))
	_button(_content, "Load game", GameManagerGlobal.open_menu.bind("load"))
	_button(_content, "Settings", GameManagerGlobal.open_menu.bind("settings"))
	_button(_content, "Controls & survival guide", GameManagerGlobal.open_menu.bind("help"))
	_button(_content, "Return to title", GameManagerGlobal.request_quit_to_main_menu)
	if GameManagerGlobal.last_save_failed:
		_button(_content, "Leave without saving…", GameManagerGlobal.open_menu.bind("confirm_quit"))


func _inventory_menu() -> void:
	var player := GameManagerGlobal.get_player()
	if not player:
		return
	var inventory := player.inventory_comp
	_button(_content, "Craft from this inventory", GameManagerGlobal.open_menu.bind("crafting"))
	_text(
		_content,
		(
			"%d / %d stacks · %.1f / %.0f kg · XP %d"
			% [
				inventory.get_used_slots(),
				inventory.max_slots,
				inventory.get_current_weight(),
				inventory.max_weight,
				player.experience
			]
		)
	)
	var weapon := player.equipment_comp.get_equipped()
	_text(
		_content,
		(
			"Weapon: %s · Condition %d · Armor %.0f"
			% [
				DataCatalogGlobal.item_name(weapon) if not weapon.is_empty() else "Unarmed",
				player.equipment_comp.condition(weapon),
				player.equipment_comp.armor()
			]
		)
	)
	_button(
		_content,
		"Repair equipped tool / weapon (1 stone or iron ingot)",
		GameManagerGlobal.repair_equipment
	)
	for key in inventory.get_all_items():
		var row := HBoxContainer.new()
		_content.add_child(row)
		var item := DataCatalogGlobal.item(key)
		var description := _text(
			row, "%s × %d\n%s" % [item.display_name, inventory.get_count(key), item.description], 18
		)
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var verb := "Use"
		if not item.equipment_slot.is_empty():
			verb = "Equip"
		elif not item.structure.is_empty():
			verb = "Build"
		_button(row, verb, GameManagerGlobal.use_item.bind(key))
		_button(row, "Drop 1", GameManagerGlobal.drop_item.bind(key))


func _crafting_menu() -> void:
	var player := GameManagerGlobal.get_player()
	if not player:
		return
	_button(_content, "Open inventory", GameManagerGlobal.open_menu.bind("inventory"))
	_text(
		_content,
		(
			"Inventory · %d stacks · %.1f kg"
			% [player.inventory_comp.get_used_slots(), player.inventory_comp.get_current_weight()]
		),
		18
	)
	_text(_content, COPY.text.crafting, 18)
	for key in CraftingSystemGlobal.get_known_recipes():
		var recipe := CraftingSystemGlobal.get_recipe(key)
		var station: String = GameManagerGlobal.world.nearby_station(
			player.global_position, recipe.required_station
		)
		var preview := CraftingSystemGlobal.preview(key, player.inventory_comp, station)
		var cost := ""
		for ingredient in recipe.ingredients:
			cost += (
				"%s %d/%d   "
				% [
					DataCatalogGlobal.item_name(ingredient.item_id),
					player.inventory_comp.get_count(ingredient.item_id),
					ingredient.count
				]
			)
		if not recipe.required_station.is_empty():
			cost += " · " + recipe.required_station
		var row := HBoxContainer.new()
		_content.add_child(row)
		var label := _text(row, recipe.display_name + "\n" + cost, 18)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var button := _button(row, "Craft", GameManagerGlobal.craft.bind(key))
		button.disabled = not preview.success
		button.tooltip_text = "Ready" if preview.success else preview.reason


func _journal_menu() -> void:
	if QuestSystemGlobal.recruited:
		_button(_content, "Companion orders", GameManagerGlobal.open_menu.bind("dialogue"))
	_text(
		_content,
		(
			"Mara's trust: %d · Companion: %s"
			% [
				QuestSystemGlobal.trust,
				"Following and assisting" if QuestSystemGlobal.recruited else "Not recruited"
			]
		)
	)
	for quest: QuestDefinition in QuestSystemGlobal.QUESTS.entries:
		_text(
			_content,
			(
				quest.title
				+ " · "
				+ str(QuestSystemGlobal.states.get(quest.quest_id, "offered")).capitalize()
			),
			24
		)
		_text(_content, quest.description)
		if QuestSystemGlobal.choices.has(quest.quest_id):
			_text(_content, "Your choice: " + QuestSystemGlobal.choices[quest.quest_id], 18)


func _map_menu() -> void:
	_text(_content, COPY.text.map)
	for region in IslandWorld.ISLAND.regions:
		var unlocked: bool = region.id in GameManagerGlobal.world.discovered
		var button := _button(
			_content, region.name + " · " + region.hint, GameManagerGlobal.travel.bind(region.id)
		)
		button.disabled = not unlocked
		button.add_theme_font_size_override("font_size", 18)


func _slots_menu() -> void:
	var saves := SaveManagerGlobal.list_saves()
	for slot in range(-2, 10):
		var exists := false
		var timestamp := "Empty"
		for entry in saves:
			if entry.slot == slot:
				exists = true
				timestamp = Time.get_datetime_string_from_unix_time(int(entry.timestamp)).replace(
					"T", " "
				)
		var callback := (
			GameManagerGlobal.load_game.bind(slot) if _menu == "load" else _save_slot.bind(slot)
		)
		var button := _button(
			_content, "%s · %s" % [SaveManagerGlobal.slot_name(slot), timestamp], callback
		)
		button.disabled = _menu == "load" and not exists


func _save_slot(slot: int) -> void:
	GameManagerGlobal.save(slot)
	call_deferred("_render_menu")


func _settings_menu() -> void:
	var settings := GameManagerGlobal.settings
	_slider("Text size", "text_scale", 1.0, 1.4, 0.1, float(settings.text_scale))
	_slider("Master volume", "volume", 0, 1, 0.05, float(settings.volume))
	_slider("Camera sensitivity", "sensitivity", 0.001, 0.02, 0.001, float(settings.sensitivity))
	_slider("Touch control size", "controls_scale", 0.8, 1.2, 0.05, float(settings.controls_scale))
	_slider("Touch opacity", "controls_opacity", 0.3, 1, 0.05, float(settings.controls_opacity))
	for entry in [["Haptic feedback", "vibration"], ["Left-handed controls", "left_handed"]]:
		var toggle := CheckButton.new()
		toggle.text = entry[0]
		toggle.custom_minimum_size.y = 72
		toggle.button_pressed = settings[entry[1]]
		toggle.toggled.connect(func(value: bool): GameManagerGlobal.update_setting(entry[1], value))
		_content.add_child(toggle)
	var quality := OptionButton.new()
	quality.custom_minimum_size.y = 72
	for label in [
		"Low · 30 FPS cap · 60m view",
		"Medium · 60 FPS cap · 100m view",
		"High · 60 FPS cap · 140m view"
	]:
		quality.add_item(label)
	quality.selected = settings.quality
	quality.item_selected.connect(
		func(value: int): GameManagerGlobal.update_setting("quality", value)
	)
	_content.add_child(quality)
	if GameManagerGlobal.get_player():
		_button(_content, "Export local frame-time CSV", GameManagerGlobal.export_telemetry)


func _slider(
	title: String, key: String, low: float, high: float, step: float, value: float
) -> void:
	_text(_content, title, 18)
	var slider := HSlider.new()
	slider.custom_minimum_size.y = 48
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value = value
	slider.value_changed.connect(func(next: float): GameManagerGlobal.update_setting(key, next))
	_content.add_child(slider)


func _dialogue_menu() -> void:
	_text(_content, QuestSystemGlobal.DIALOGUE.speaker, 24)
	_text(
		_content,
		_dialogue_text if not _dialogue_text.is_empty() else QuestSystemGlobal.DIALOGUE.introduction
	)
	_text(_content, "Trust: %d" % QuestSystemGlobal.trust, 18)
	var quest := QuestSystemGlobal.available_quest()
	if quest:
		_text(_content, quest.title + "\n" + quest.description)
		if QuestSystemGlobal.states.get(quest.quest_id, "") != "active":
			_button(_content, "Accept: " + quest.title, QuestSystemGlobal.accept_quest)
		else:
			for choice in quest.choices:
				_button(_content, choice.label, GameManagerGlobal.complete_quest.bind(choice.id))
	if QuestSystemGlobal.trust >= 2 and not QuestSystemGlobal.recruited:
		_button(_content, "Ask Mara to travel with you", QuestSystemGlobal.recruit)
	if QuestSystemGlobal.recruited:
		_companion_orders()


func _companion_orders() -> void:
	var companion := GameManagerGlobal.world.get_node("Mara") as Companion
	_text(
		_content,
		(
			"Order: %s · Carry %.1f / %.0f kg"
			% [
				companion.command,
				companion.inventory_comp.get_current_weight(),
				companion.inventory_comp.max_weight
			]
		)
	)
	for key in companion.inventory_comp.get_all_items():
		_text(
			_content,
			"%s × %d" % [DataCatalogGlobal.item_name(key), companion.inventory_comp.get_count(key)],
			18
		)
	for order in ["follow", "hold", "return", "assist"]:
		_button(_content, order.capitalize(), GameManagerGlobal.command_companion.bind(order))
	for resource in ResourceSystemGlobal.nearby_resources(
		companion.global_position, Companion.TASK_RADIUS
	):
		if companion.permitted_resource(resource):
			_button(
				_content,
				"Gather " + DataCatalogGlobal.item_name(resource.item_id),
				GameManagerGlobal.command_companion.bind("gather", str(resource.name))
			)


func _beacon_menu() -> void:
	if QuestSystemGlobal.states.get("guardian", "") != "complete":
		_text(_content, COPY.text.beacon)
		return
	_text(
		_content,
		"Repair costs: 3 iron ingots, 2 fiber, 1 signal crystal.\nThe signal is ready. What will you do?"
	)
	var together := _button(
		_content, "Call rescue for both of you", GameManagerGlobal.finish_story.bind("together")
	)
	together.disabled = QuestSystemGlobal.trust < 3
	_button(_content, "Leave the island alone", GameManagerGlobal.finish_story.bind("alone"))
	_button(
		_content,
		"Stay and keep the warning beacon lit",
		GameManagerGlobal.finish_story.bind("stay")
	)


func _back() -> void:
	if GameManagerGlobal.get_player():
		if _menu in ["settings", "save", "load", "help"]:
			GameManagerGlobal.open_menu("pause")
		else:
			GameManagerGlobal.resume_game()
	else:
		show_menu("main")


func _show_message(message: String) -> void:
	_toast.text = message
	_toast_time = 4


func _loading_progress(progress: float) -> void:
	if is_instance_valid(_loading_label):
		_loading_label.text = "Preparing the island… %d%%" % int(progress * 100)


func _npc_dialogue_menu() -> void:
	var npc := GameManagerGlobal.world.get_node_or_null(_current_npc_id) as NPC
	if not npc:
		_back()
		return
	var rel := RelationshipSystemGlobal.get_relationship(_current_npc_id)
	var bond_level: int = rel.get("bond_level", 0)
	var bond_points: int = rel.get("bond_points", 0)
	var progress := RelationshipSystemGlobal.get_progress_to_next(_current_npc_id)
	var status: String = rel.get("status", "Neutral")
	var role: String = rel.get("assigned_role", "none")
	var is_teamed_up: bool = rel.get("is_teamed_up", false)
	var can_switch := RelationshipSystemGlobal.can_switch_character(_current_npc_id)

	# NPC name and portrait
	var header := HBoxContainer.new()
	_content.add_child(header)
	var name_label := _text(
		header, CharacterRoster.get_npc(_current_npc_id).get("display_name", _current_npc_id), 28
	)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Bond level display
	var bond_bar := ProgressBar.new()
	bond_bar.min_value = 0
	bond_bar.max_value = 1
	bond_bar.value = progress
	bond_bar.custom_minimum_size = Vector2(0, 20)
	bond_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bond_style := StyleBoxFlat.new()
	bond_style.bg_color = Color("2a3a4a")
	bond_style.corner_radius_top_left = 4
	bond_style.corner_radius_bottom_left = 4
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color("7ac4d4")
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_bottom_left = 4
	bond_bar.add_theme_stylebox_override("fill", fill_style)
	bond_bar.add_theme_stylebox_override("background", bond_style)
	_content.add_child(bond_bar)

	var bond_info := HBoxContainer.new()
	_content.add_child(bond_info)
	_text(bond_info, "Bond Level: %d (%s)" % [bond_level, status], 18).size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	_text(bond_info, "%d pts" % bond_points, 16)

	_text(_content, "Progress to next level: %d%%" % int(progress * 100), 16)

	# Current role
	if not role.is_empty() and role != "none":
		_text(_content, "Current Role: %s" % role.capitalize(), 18)

	# Team up status
	if is_teamed_up:
		_text(_content, "[Teamed Up]", 16).add_theme_color_override("font_color", Color("9cbf79"))

	# Dialogue text (from NPC's dialogue resource)
	var npc_data := CharacterRoster.get_npc(_current_npc_id)
	if npc_data and npc_data.get("dialogue_resource"):
		_text(_content, npc_data.dialogue_resource.introduction, 18)
	else:
		_text(_content, "No dialogue available.", 18)

	# Main interaction options
	_button(_content, "TALK", _open_talk_dialogue)

	var team_up_text := "TEAM UP" if not is_teamed_up else "STOP TEAMING UP"
	_button(_content, team_up_text, _toggle_team_up)

	_button(_content, "CONFIGURE", GameManagerGlobal.open_menu.bind("npc_configure"))

	# Character switch option (bond level 4+)
	if can_switch:
		var switch_btn := _button(
			_content,
			(
				"Switch to play as %s"
				% CharacterRoster.get_npc(_current_npc_id).get("display_name", _current_npc_id)
			),
			func(): _switch_character()
		)
		switch_btn.add_theme_color_override("font_color", Color("dfc071"))

	_button(_content, "Back", _back)


func _npc_configure_menu() -> void:
	var npc := GameManagerGlobal.world.get_node_or_null(_current_npc_id) as NPC
	if not npc:
		_back()
		return

	var rel := RelationshipSystemGlobal.get_relationship(_current_npc_id)
	var bond_level: int = rel.get("bond_level", 0)
	var current_role: String = rel.get("assigned_role", "none")

	_text(
		_content,
		(
			"Configure %s"
			% CharacterRoster.get_npc(_current_npc_id).get("display_name", _current_npc_id)
		),
		28
	)
	_text(_content, "Bond Level: %d" % bond_level, 18)
	_text(
		_content,
		"Current Role: %s" % (current_role.capitalize() if current_role != "none" else "None"),
		18
	)

	if bond_level < 3:
		_text(_content, "Reach Bond Level 3 to assign roles.", 16).add_theme_color_override(
			"font_color", Color("dd8074")
		)
		_button(_content, "Back", func(): GameManagerGlobal.open_menu("npc_dialogue"))
		return

	var roles := ["none", "gatherer", "defender", "farmer", "survivor"]
	for role_id in roles:
		var role_enum := -1
		match role_id:
			"gatherer":
				role_enum = RoleDefinition.NPCRole.GATHERER
			"defender":
				role_enum = RoleDefinition.NPCRole.DEFENDER
			"farmer":
				role_enum = RoleDefinition.NPCRole.FARMER
			"survivor":
				role_enum = RoleDefinition.NPCRole.SURVIVOR
			_:
				role_enum = -1
		var role_config := RoleDefinition.get_config(role_enum)
		if role_id == "none":
			role_config = {
				"display_name": "None", "description": "No assigned role. NPC will follow or idle."
			}

		var role_btn := _button(
			_content,
			(
				"%s %s"
				% [
					role_config.get("display_name", role_id),
					"(Current)" if role_id == current_role else ""
				]
			),
			func(r = role_id): _assign_role(r)
		)
		if role_id == current_role:
			role_btn.add_theme_color_override("font_color", Color("7ac4d4"))

	_button(_content, "Back", func(): GameManagerGlobal.open_menu("npc_dialogue"))


func _open_talk_dialogue() -> void:
	var npc_data := CharacterRoster.get_npc(_current_npc_id)
	var dialogue := npc_data.get("dialogue_resource") as DialogueDefinition
	GameManagerGlobal.message_posted.emit(
		dialogue.introduction if dialogue else "No dialogue available."
	)


func _toggle_team_up() -> void:
	var npc := GameManagerGlobal.world.get_node_or_null(_current_npc_id) as NPC
	if not npc:
		return
	var rel := RelationshipSystemGlobal.get_relationship(_current_npc_id)
	var bond_level: int = rel.get("bond_level", 0)
	var is_teamed_up: bool = rel.get("is_teamed_up", false)

	if not is_teamed_up:
		if bond_level >= 2:
			RelationshipSystemGlobal.set_teamed_up(_current_npc_id, true)
			npc.npc_comp.issue_command("follow")
			GameManagerGlobal.message_posted.emit("%s joined your party!" % npc.name)
		else:
			GameManagerGlobal.message_posted.emit("Need Bond Level 2 to team up.")
	else:
		RelationshipSystemGlobal.set_teamed_up(_current_npc_id, false)
		npc.npc_comp.issue_command("hold")
		GameManagerGlobal.message_posted.emit("%s left your party." % npc.name)

	_refresh_menu()


func _assign_role(role_id: String) -> void:
	var npc := GameManagerGlobal.world.get_node_or_null(_current_npc_id) as NPC
	if not npc:
		return
	RelationshipSystemGlobal.set_assigned_role(_current_npc_id, role_id)
	npc.set_role(role_id)
	GameManagerGlobal.message_posted.emit("%s is now a %s." % [npc.name, role_id.capitalize()])
	GameManagerGlobal.open_menu("npc_configure")


func _switch_character() -> void:
	if PartySystemGlobal.switch_character(_current_npc_id):
		GameManagerGlobal.message_posted.emit(
			(
				"Now playing as %s!"
				% CharacterRoster.get_npc(_current_npc_id).get("display_name", _current_npc_id)
			)
		)
		GameManagerGlobal.resume_game()
	else:
		GameManagerGlobal.message_posted.emit("Cannot switch characters right now.")


func _on_dialogue(text: String) -> void:
	if text.begins_with("INTERACTION_NPC:"):
		_current_npc_id = text.replace("INTERACTION_NPC:", "")
		GameManagerGlobal.open_menu("npc_dialogue")
	else:
		_dialogue_text = text
		_refresh_menu()


func _button(parent: Node, title: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(90, 72)
	button.pressed.connect(callback)
	button.pressed.connect(AudioManagerGlobal.play_ui_sfx.bind("click"))
	parent.add_child(button)
	return button


func _text(parent: Node, content: String, font_size: int = 20) -> Label:
	var label := Label.new()
	label.text = content
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label
