# gdlint: disable=max-public-methods
# Keep UI request delegation in the existing coordinator.
extends Node
## Owns lifecycle and translates UI intent into gameplay-system requests.

signal game_paused
signal game_resumed
signal game_ready
signal menu_requested(menu: String)
signal message_posted(message: String)
signal loading_changed(progress: float)

const WORLD_PATH := "res://scenes/GameWorld.tscn"
const UI_PATH := "res://scenes/HUD.tscn"
const AUTOSAVE_INTERVAL := 180.0
const SETTINGS_PATH := "user://settings.cfg"

var world: Node3D
var ui: CanvasLayer
var is_paused := false
var is_loading := false
var last_save_failed := false
var settings: Dictionary = {
	"volume": 0.7,
	"sensitivity": 0.005,
	"vibration": true,
	"quality": 1,
	"controls_scale": 1.0,
	"controls_opacity": 0.7,
	"text_scale": 1.0,
	"left_handed": false
}
var _autosave_timer := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputManagerGlobal.action_requested.connect(handle_action)
	SaveManagerGlobal.save_corrupted.connect(_on_recovery)
	_load_settings()
	call_deferred("_boot")


func _boot() -> void:
	var current := get_tree().current_scene
	if current and current.scene_file_path == "res://scenes/Main.tscn":
		_ensure_ui()
		menu_requested.emit("main")


func _process(delta: float) -> void:
	if not is_instance_valid(world) or is_paused or is_loading:
		return
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0
		save(SaveManagerGlobal.AUTOSAVE_SLOT, false)


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_GO_BACK_REQUEST]:
		if is_instance_valid(world) and not is_loading:
			save(SaveManagerGlobal.AUTOSAVE_SLOT, false)
			open_menu("pause")


func new_game(character_id: String = "dave") -> void:
	_start_world({}, CharacterRoster.normalize_id(character_id))


func load_game(slot: int) -> bool:
	var data := SaveManagerGlobal.load_game(slot)
	if data.is_empty():
		message_posted.emit("This save is missing or damaged.")
		return false
	_start_world(data)
	return true


func _start_world(data: Dictionary, character_id: String = "dave") -> void:
	if is_loading:
		return
	is_loading = true
	_ensure_ui()
	menu_requested.emit("loading")
	InputManagerGlobal.reset()
	var error := ResourceLoader.load_threaded_request(WORLD_PATH)
	if error != OK:
		_load_failed()
		return
	var progress: Array = []
	while (
		ResourceLoader.load_threaded_get_status(WORLD_PATH, progress)
		== ResourceLoader.THREAD_LOAD_IN_PROGRESS
	):
		loading_changed.emit(float(progress[0]) if not progress.is_empty() else 0)
		await get_tree().process_frame
	if ResourceLoader.load_threaded_get_status(WORLD_PATH) != ResourceLoader.THREAD_LOAD_LOADED:
		_load_failed()
		return
	var packed := ResourceLoader.load_threaded_get(WORLD_PATH) as PackedScene
	if is_instance_valid(world):
		world.free()
	CraftingSystemGlobal.reset()
	QuestSystemGlobal.reset()
	world = packed.instantiate()
	get_tree().root.add_child(world)
	if data.is_empty():
		get_player().set_character_id(character_id)
	else:
		world.deserialize(data.world)
		get_player().deserialize(data.player)
		QuestSystemGlobal.deserialize(data.get("quests", {}))
		CraftingSystemGlobal.restore_known(data.get("known_recipes", []))
	_autosave_timer = 0
	last_save_failed = false
	is_loading = false
	is_paused = false
	get_tree().paused = false
	apply_settings()
	menu_requested.emit("")
	game_ready.emit()
	if not QuestSystemGlobal.ending.is_empty():
		open_menu("ending")
	elif get_player().health_comp.is_dead():
		open_menu("death")


func _load_failed() -> void:
	is_loading = false
	menu_requested.emit("main")
	message_posted.emit("Unable to load the island. Please retry.")


func _ensure_ui() -> void:
	if not is_instance_valid(ui):
		ui = load(UI_PATH).instantiate()
		ui.name = "UILayer"
		get_tree().root.add_child(ui)


func get_player() -> Player:
	if not is_instance_valid(world):
		return null
	return world.get_node_or_null("Player") as Player


func pause_game() -> void:
	is_paused = true
	get_tree().paused = true
	InputManagerGlobal.reset()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game_paused.emit()


func resume_game() -> void:
	var player := get_player()
	if not player or player.health_comp.is_dead() or not QuestSystemGlobal.ending.is_empty():
		return
	is_paused = false
	get_tree().paused = false
	InputManagerGlobal.reset()
	menu_requested.emit("")
	game_resumed.emit()


func open_menu(menu: String) -> void:
	if is_loading:
		return
	if is_instance_valid(world):
		pause_game()
		if menu == "pause" and not get_player().health_comp.is_dead():
			save(SaveManagerGlobal.AUTOSAVE_SLOT, false)
	menu_requested.emit(menu)


func handle_action(action: String) -> void:
	if is_loading:
		return
	if not get_player():
		return
	if action in ["pause", "inventory", "crafting", "journal", "map", "settings"]:
		if is_paused and action == "pause":
			resume_game()
		else:
			open_menu(action)
		return
	var player := get_player()
	if player and not is_paused:
		player.perform_action(action)


func save(slot: int, notify: bool = true) -> Error:
	var result := SaveManagerGlobal.save_game(slot)
	last_save_failed = result != OK
	if notify or last_save_failed:
		message_posted.emit("Game saved." if result == OK else "Save failed. Check free storage.")
	return result


func snapshot() -> Dictionary:
	var player := get_player()
	if not player or is_loading or player.health_comp.is_dead():
		return {}
	return {
		"player": player.serialize(),
		"world": world.serialize(),
		"quests": QuestSystemGlobal.serialize(),
		"known_recipes": CraftingSystemGlobal.get_known_recipes()
	}


func request_quit_to_main_menu(discard_unsaved: bool = false) -> void:
	var player := get_player()
	if not discard_unsaved and player and not player.health_comp.is_dead():
		if save(SaveManagerGlobal.AUTOSAVE_SLOT, false) != OK:
			pause_game()
			menu_requested.emit("pause")
			return
	if is_instance_valid(world):
		world.queue_free()
	world = null
	get_tree().paused = false
	is_paused = false
	last_save_failed = false
	InputManagerGlobal.reset()
	menu_requested.emit("main")


func use_item(item_id: String) -> void:
	var player := get_player()
	if player:
		player.use_item(item_id)


func repair_equipment() -> void:
	var player := get_player()
	if player:
		var success := player.equipment_comp.repair(player.inventory_comp)
		message_posted.emit(
			"Equipment repaired." if success else "No repair needed or missing materials."
		)


func drop_item(item_id: String) -> void:
	var player := get_player()
	if player and player.inventory_comp.has_item(item_id):
		if world.spawn_pickup(item_id, 1, player.global_position + player._facing * 2):
			player.inventory_comp.remove_item(item_id)


func travel(region_id: String) -> void:
	if is_instance_valid(world):
		world.fast_travel(region_id)


func complete_quest(choice: String) -> void:
	var player := get_player()
	if player:
		QuestSystemGlobal.complete_quest(choice, player.inventory_comp)


func finish_story(choice: String) -> void:
	var player := get_player()
	if player:
		QuestSystemGlobal.finish(choice, player.inventory_comp)


func command_companion(command: String, target_id: String = "") -> void:
	if not is_instance_valid(world):
		return
	var companion := world.get_node("Mara") as Companion
	var target := ResourceSystemGlobal.get_resource(target_id)
	if companion.issue_command(command, target):
		message_posted.emit("Mara: " + command.capitalize())
		resume_game()
	else:
		message_posted.emit("Mara cannot take that order here.")


func export_telemetry() -> void:
	if is_instance_valid(world):
		var result: Error = world.export_telemetry()
		message_posted.emit(
			"Saved user://performance.csv" if result == OK else "CSV export failed."
		)


func craft(recipe_id: String) -> void:
	var player := get_player()
	if not player:
		return
	var recipe := CraftingSystemGlobal.get_recipe(recipe_id)
	var station: String = world.nearby_station(
		player.global_position, recipe.required_station if recipe else ""
	)
	var result := CraftingSystemGlobal.craft(recipe_id, player.inventory_comp, station)
	message_posted.emit(
		(
			"Crafted " + DataCatalogGlobal.item_name(result.result_item)
			if result.success
			else result.reason
		)
	)
	if result.success:
		player.illustration.play_action(
			"cook" if recipe.required_station == "campfire" else "craft"
		)
		AudioManagerGlobal.play_ui_sfx("success")


func update_setting(key: String, value: Variant) -> void:
	if not settings.has(key):
		return
	settings[key] = value
	apply_settings()
	var config := ConfigFile.new()
	for setting in settings:
		config.set_value("game", setting, settings[setting])
	if config.save(SETTINGS_PATH) != OK:
		message_posted.emit("Could not save settings.")


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		for key in settings:
			var value: Variant = config.get_value("game", key, settings[key])
			if typeof(value) == typeof(settings[key]):
				settings[key] = value
	apply_settings()


func apply_settings() -> void:
	settings.text_scale = clampf(float(settings.text_scale), 1.0, 1.4)
	if is_instance_valid(ui):
		ui.apply_text_scale()
	AudioManagerGlobal.set_bus_volume_linear("Master", clampf(settings.volume, 0, 1))
	InputManagerGlobal.set_touch_sensitivity(settings.sensitivity)
	InputManagerGlobal.haptic_feedback_enabled = settings.vibration
	InputManagerGlobal.control_scale = clampf(settings.controls_scale, 0.8, 1.2)
	InputManagerGlobal.button_opacity = clampf(settings.controls_opacity, 0.3, 1)
	InputManagerGlobal.left_handed = settings.left_handed
	Engine.max_fps = 30 if settings.quality == 0 else 60
	var player := get_player()
	if player:
		player.camera.far = [60.0, 100.0, 140.0][clampi(settings.quality, 0, 2)]


func _on_recovery(_slot: int, reason: String) -> void:
	message_posted.emit(reason)
