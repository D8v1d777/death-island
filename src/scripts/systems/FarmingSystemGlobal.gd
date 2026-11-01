extends Node
## Farming system - farm plots, crop growth, harvesting.
## Integrated with base storage, world time, and save system.

signal plot_changed(plot_id: String)
signal crop_harvested(plot_id: String, crop_id: String, harvest_count: int)
signal crop_planted(plot_id: String, crop_id: String)

const CROP_DEFINITION = preload("res://scripts/data/CropDefinition.gd")
const DAY_MINUTES := 1440.0

var farm_plots: Dictionary = {}  # plot_id -> FarmPlotData
var _plot_counter := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_lifecycle.call_deferred()


func _connect_lifecycle() -> void:
	GameManagerGlobal.game_ready.connect(_on_game_ready)
	BaseStorageGlobal.storage_changed.connect(_on_storage_changed)


func _on_game_ready() -> void:
	var world := GameManagerGlobal.world
	if is_instance_valid(world) and not world.day_changed.is_connected(_on_day_changed):
		world.day_changed.connect(_on_day_changed)
	farm_plots.clear()
	_plot_counter = 0
	_initialize_farm_plots()


func _initialize_farm_plots() -> void:
	# Create default farm plots near base area (around position 2, 0, 35)
	var base_pos := Vector3(2, 0, 35)
	for x in range(-1, 2):
		for z in range(-1, 2):
			if x == 0 and z == 0:
				continue
			var plot_id := "farm_plot_%d" % _plot_counter
			_plot_counter += 1
			farm_plots[plot_id] = {
				"plot_id": plot_id,
				"position": base_pos + Vector3(x * 3.0, 0, z * 3.0),
				"state": "empty",  # empty, tilled, planted, watered, mature, harvested
				"crop_id": "",
				"stage": 0,
				"watered_stages": [],
				"planted_time": 0.0,
				"last_watered_time": 0.0,
				"regrowth_count": 0
			}
	plot_changed.emit("all")


func _on_day_changed(_new_day: int) -> void:
	_update_all_plots()


func _on_storage_changed() -> void:
	# Check if farmer NPC can now perform actions
	pass


func _world_minutes() -> float:
	var world := GameManagerGlobal.world as IslandWorld
	return world.elapsed / world.DAY_SECONDS * DAY_MINUTES if is_instance_valid(world) else 0.0


func _update_all_plots() -> void:
	var elapsed := _world_minutes()
	for plot_id in farm_plots:
		_update_plot(plot_id, elapsed)


func _update_plot(plot_id: String, current_time: float) -> void:
	var plot: Dictionary = farm_plots[plot_id]
	if plot.state == "planted" or plot.state == "watered":
		_check_growth(plot, current_time)
	elif (
		plot.state == "mature"
		and CropDefinition.CROP_DEFINITIONS.get(plot.crop_id, {}).get("regrows", false)
	):
		# Regrowth handled at harvest time
		pass


func _check_growth(plot: Dictionary, current_time: float) -> void:
	var crop_def: Dictionary = CropDefinition.CROP_DEFINITIONS.get(plot.crop_id, {})
	if crop_def.is_empty():
		return

	var stage_durations: Array = crop_def.get("stage_durations_minutes", [])
	if plot.stage >= stage_durations.size():
		plot.state = "mature"
		plot_changed.emit(plot.plot_id)
		return

	var stage_duration: float = stage_durations[plot.stage]
	var time_since_stage: float = current_time - plot.planted_time
	if plot.stage > 0:
		# Calculate cumulative time for previous stages
		for i in range(plot.stage):
			time_since_stage -= stage_durations[i]

	if time_since_stage >= stage_duration:
		plot.stage += 1
		plot.planted_time = current_time

		# Check if water is needed for this stage
		var water_per_stage: Array = crop_def.get("water_per_stage", [])
		if plot.stage <= water_per_stage.size() and water_per_stage[plot.stage - 1] > 0:
			if not (plot.stage - 1) in plot.watered_stages:
				plot.state = "planted"  # Needs watering
			else:
				plot.state = "watered"
		else:
			plot.state = "watered"

		if plot.stage >= stage_durations.size():
			plot.state = "mature"

		plot_changed.emit(plot.plot_id)


func create_plot(position: Vector3) -> String:
	var plot_id := "farm_plot_%d" % _plot_counter
	_plot_counter += 1
	farm_plots[plot_id] = {
		"plot_id": plot_id,
		"position": position,
		"state": "empty",
		"crop_id": "",
		"stage": 0,
		"watered_stages": [],
		"planted_time": 0.0,
		"last_watered_time": 0.0,
		"regrowth_count": 0
	}
	plot_changed.emit(plot_id)
	return plot_id


func get_plot(plot_id: String) -> Dictionary:
	return farm_plots.get(plot_id, {}).duplicate(true)


func get_all_plots() -> Dictionary:
	var result: Dictionary = {}
	for plot_id in farm_plots:
		result[plot_id] = farm_plots[plot_id].duplicate(true)
	return result


func get_plots_in_range(position: Vector3, radius: float) -> Array[String]:
	var result: Array[String] = []
	for plot_id in farm_plots:
		var plot: Dictionary = farm_plots[plot_id]
		if plot.position.distance_to(position) <= radius:
			result.append(plot_id)
	return result


func till_plot(plot_id: String) -> bool:
	var plot: Dictionary = farm_plots.get(plot_id, {})
	if not plot or plot.state != "empty":
		return false
	plot.state = "tilled"
	plot_changed.emit(plot_id)
	return true


func plant_crop(plot_id: String, crop_id: String, player_inventory: InventoryComponent) -> bool:
	var plot: Dictionary = farm_plots.get(plot_id, {})
	if not plot or plot.state != "tilled":
		return false

	var crop_def: Dictionary = CropDefinition.CROP_DEFINITIONS.get(crop_id, {})
	if crop_def.is_empty():
		return false

	var seed_item: String = crop_def.get("seed_item_id", "")
	if not player_inventory.has_item(seed_item, 1):
		return false

	if not player_inventory.remove_item(seed_item, 1):
		return false

	plot.state = "planted"
	plot.crop_id = crop_id
	plot.stage = 0
	plot.planted_time = _world_minutes()
	plot.watered_stages.clear()
	plot.regrowth_count = 0

	crop_planted.emit(plot_id, crop_id)
	plot_changed.emit(plot_id)
	return true


func water_plot(plot_id: String, player_inventory: InventoryComponent) -> bool:
	var plot: Dictionary = farm_plots.get(plot_id, {})
	if not plot or (plot.state != "planted" and plot.state != "watered"):
		return false

	if plot.stage >= plot.watered_stages.size():
		# Already watered for current stage
		return true

	var crop_def: Dictionary = CropDefinition.CROP_DEFINITIONS.get(plot.crop_id, {})
	var water_per_stage: Array = crop_def.get("water_per_stage", [])
	if plot.stage >= water_per_stage.size() or water_per_stage[plot.stage] <= 0:
		plot.watered_stages.append(plot.stage)
		plot.state = "watered"
		plot.last_watered_time = _world_minutes()
		plot_changed.emit(plot_id)
		return true

	var water_needed: int = water_per_stage[plot.stage]
	if not player_inventory.has_item("water", water_needed):
		return false

	if not player_inventory.remove_item("water", water_needed):
		return false

	plot.watered_stages.append(plot.stage)
	plot.state = "watered"
	plot.last_watered_time = _world_minutes()
	plot_changed.emit(plot_id)
	return true


func harvest_plot(plot_id: String, player_inventory: InventoryComponent) -> int:
	var plot: Dictionary = farm_plots.get(plot_id, {})
	if not plot or plot.state != "mature":
		return 0

	var crop_def: Dictionary = CropDefinition.CROP_DEFINITIONS.get(plot.crop_id, {})
	if crop_def.is_empty():
		return 0

	var harvest_item: String = crop_def.get("harvest_item_id", "")
	var base_yield: int = crop_def.get("harvest_yield", 1)
	var variance: int = crop_def.get("harvest_yield_variance", 0)
	var harvest_count := maxi(1, base_yield + randi_range(-variance, variance))

	var added := 0
	for i in range(harvest_count):
		if player_inventory.add_item(harvest_item, 1):
			added += 1
		else:
			break

	if added > 0:
		crop_harvested.emit(plot_id, plot.crop_id, added)

		# Handle regrowth
		if (
			crop_def.get("regrows", false)
			and plot.regrowth_count < crop_def.get("regrowth_stages", 0)
		):
			plot.regrowth_count += 1
			plot.stage = crop_def.get("growth_stages", 4) - crop_def.get("regrowth_stages", 2)
			plot.planted_time = _world_minutes()
			plot.watered_stages.clear()
			plot.state = "watered"
		else:
			plot.state = "empty"
			plot.crop_id = ""
			plot.stage = 0
			plot.watered_stages.clear()
			plot.regrowth_count = 0

		plot_changed.emit(plot_id)

	return added


func get_plot_state_text(plot_id: String) -> String:
	var plot: Dictionary = farm_plots.get(plot_id, {})
	if not plot:
		return "Unknown"
	var crop_def := CropDefinition.get_definition(plot.crop_id)

	var text: String = plot.state
	match plot.state:
		"empty":
			text = "Empty"
		"tilled":
			text = "Tilled - Ready to plant"
		"planted":
			text = (
				"%s - Stage %d/%d (Needs water)"
				% [
					crop_def.get("display_name", plot.crop_id),
					plot.stage + 1,
					crop_def.get("growth_stages", 4)
				]
			)
		"watered":
			text = (
				"%s - Stage %d/%d (Watered)"
				% [
					crop_def.get("display_name", plot.crop_id),
					plot.stage + 1,
					crop_def.get("growth_stages", 4)
				]
			)
		"mature":
			text = "%s - READY TO HARVEST" % [crop_def.get("display_name", plot.crop_id)]
		"harvested":
			text = "Harvested"
	return text


func serialize() -> Dictionary:
	var data: Dictionary = {}
	for plot_id in farm_plots:
		data[plot_id] = farm_plots[plot_id].duplicate(true)
	return data


func deserialize(data: Dictionary) -> void:
	farm_plots.clear()
	_plot_counter = 0
	for plot_id in data:
		farm_plots[plot_id] = data[plot_id].duplicate(true)
		var num_str: String = plot_id.replace("farm_plot_", "")
		if num_str.is_valid_int():
			_plot_counter = max(_plot_counter, int(num_str) + 1)
	plot_changed.emit("all")
