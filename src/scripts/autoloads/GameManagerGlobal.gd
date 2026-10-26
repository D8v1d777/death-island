extends Node

## Central game state coordinator. Handles scene transitions, pause/resume, game flow.

signal game_paused
signal game_resumed
signal scene_changing(new_scene_path: String)
signal scene_changed(scene_name: String)
signal new_game_started
signal game_loaded(save_slot: int)
signal game_saved(save_slot: int)
signal quit_to_main_menu

@export_group("Configuration")
@export var initial_scene: String = "res://scenes/GameWorld.tscn"
@export var loading_screen_path: String = ""

@export_group("Runtime State (Read-Only)")
@export var current_scene_name: String = ""
@export var is_paused: bool = false
@export var is_loading: bool = false

var _current_scene: Node = null
var _previous_scene: String = ""

func _ready() -> void:
	# Ensure we're in the scene tree root
	if not is_inside_tree():
		push_error("GameManagerGlobal must be an autoload")
		return

	# Load initial scene after tree is ready
	call_deferred("_load_initial_scene")

func _load_initial_scene() -> void:
	change_scene(initial_scene)

func change_scene(target_scene_path: String) -> void:
	if is_loading:
		push_warning("Scene change already in progress")
		return

	if _current_scene and _current_scene.is_inside_tree():
		_previous_scene = current_scene_name

	is_loading = true
	scene_changing.emit(target_scene_path)

	# Show loading screen if available
	var loading_screen := _instantiate_loading_screen()
	if loading_screen:
		get_tree().root.add_child(loading_screen)
		loading_screen.show()

	# Use deferred to allow loading screen to show
	call_deferred("_do_change_scene", target_scene_path, loading_screen)

func _do_change_scene(target_scene_path: String, loading_screen: Node) -> void:
	var err = get_tree().change_scene_to_file(target_scene_path)
	if err != OK:
		push_error("Failed to change scene to: ", target_scene_path, " error: ", err)
		if loading_screen and loading_screen.is_inside_tree():
			loading_screen.queue_free()
		is_loading = false
		return

	# Wait for scene to be ready
	await get_tree().process_frame
	await get_tree().process_frame

	_current_scene = get_tree().current_scene
	current_scene_name = _current_scene.scene_file_path.get_file()

	if loading_screen and loading_screen.is_inside_tree():
		loading_screen.queue_free()

	is_loading = false
	scene_changed.emit(current_scene_name)

func _instantiate_loading_screen() -> Node:
	if loading_screen_path.is_empty():
		return null
	var packed_scene = ResourceLoader.load(loading_screen_path)
	if not packed_scene:
		push_warning("Loading screen not found: ", loading_screen_path)
		return null
	return packed_scene.instantiate()

func pause_game() -> void:
	if is_paused:
		return
	is_paused = true
	get_tree().paused = true
	game_paused.emit()

func resume_game() -> void:
	if not is_paused:
		return
	is_paused = false
	get_tree().paused = false
	game_resumed.emit()

func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()

func new_game() -> void:
	# Clear any existing save data for new game
	SaveManagerGlobal.delete_save(-1)  # -1 = quicksave
	SaveManagerGlobal.delete_save(0)   # slot 0

	# Reset to initial state
	change_scene(initial_scene)
	new_game_started.emit()

func load_game(save_slot: int) -> void:
	var save_data = SaveManagerGlobal.load_game(save_slot)
	if not save_data:
		push_error("Failed to load game from slot: ", save_slot)
		return

	# Apply save data to systems
	_apply_save_data(save_data)

	# Load the scene the player was in
	var scene_path = save_data.get("scene_path", initial_scene)
	change_scene(scene_path)

	# Restore player position after scene loads
	call_deferred("_restore_player_state", save_data)

	game_loaded.emit(save_slot)

func _restore_player_state(save_data: Dictionary) -> void:
	var player = _find_player()
	if not player:
		push_warning("Player not found after scene load")
		return

	# Restore transform
	if save_data.has("player_position"):
		player.global_position = Vector3(save_data["player_position"])
	if save_data.has("player_rotation"):
		player.global_rotation = Vector3(save_data["player_rotation"])

	# Restore stats via components
	var health_comp = player.get_node_or_null("HealthComponent")
	if health_comp and save_data.has("player_health"):
		health_comp.current_health = save_data["player_health"]

	var survival_comp = player.get_node_or_null("SurvivalComponent")
	if survival_comp:
		if save_data.has("player_hunger"):
			survival_comp.hunger = save_data["player_hunger"]
		if save_data.has("player_thirst"):
			survival_comp.thirst = save_data["player_thirst"]
		if save_data.has("player_stamina"):
			survival_comp.stamina = save_data["player_stamina"]

func _apply_save_data(save_data: Dictionary) -> void:
	# Apply world state
	if save_data.has("world_time"):
		# TimeOfDayGlobal.set_time(save_data["world_time"])
		pass

	# Apply inventory
	if save_data.has("inventory"):
		# InventoryGlobal.load_from_dict(save_data["inventory"])
		pass

	# Apply known recipes
	if save_data.has("known_recipes"):
		# CraftingSystemGlobal.set_known_recipes(save_data["known_recipes"])
		pass

	# Apply quest state
	if save_data.has("quests"):
		# QuestSystemGlobal.load_state(save_data["quests"])
		pass

	# Apply NPC trust
	if save_data.has("npc_trust"):
		# NPCTrustGlobal.load_state(save_data["npc_trust"])
		pass

func _find_player() -> Node:
	if not _current_scene:
		return null
	# Player is typically in GameWorld
	var game_world = _current_scene.get_node_or_null("GameWorld")
	if game_world:
		return game_world.get_node_or_null("Player")
	return _current_scene.get_node_or_null("Player")

func request_quit_to_main_menu() -> void:
	quit_to_main_menu.emit()

func get_current_scene() -> Node:
	return _current_scene

func get_previous_scene() -> String:
	return _previous_scene