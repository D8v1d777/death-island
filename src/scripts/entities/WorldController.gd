class_name IslandWorld
extends Node3D
## Fixed authored map, day/night, stations, persistence and bounded hit feedback.

signal day_changed(new_day: int)

const ISLAND = preload("res://resources/definitions/Island.tres")
const RESOURCE_SCENE = preload("res://scenes/ResourceNode.tscn")
const ENEMY_SCENE = preload("res://scenes/Enemy.tscn")
const PICKUP_SCENE = preload("res://scenes/ItemPickup.tscn")
const NPC_SCENE = preload("res://scenes/NPC.tscn")
const DAY_SECONDS := 1440.0
const MAX_OBJECTS := 64
const HIT_POOL_SIZE := 12
const GROUND_SHADER = preload("res://assets/illustrated/Ground.gdshader")
const WATER_SHADER = preload("res://assets/illustrated/Water.gdshader")

var elapsed := 600.0
var discovered: Array[String] = ["beach"]
var current_region := "beach"
var _enemies: Dictionary = {}
var _npcs: Dictionary = {}
var _environment: Environment
var _hit_pool: Array[Label3D] = []
var _hit_times: Array[float] = []
var _hit_index := 0
var _region_timer := 0.0
var _samples: Array[float] = []
var _ground_material: ShaderMaterial
var _last_day := 0


func _ready() -> void:
	_build_environment()
	_build_content()
	for index in HIT_POOL_SIZE:
		var label := LowPoly.label(self, "", Vector3.ZERO, Color("ffe1a6"))
		label.visible = false
		_hit_pool.append(label)
		_hit_times.append(0.0)


func _build_environment() -> void:
	_environment = Environment.new()
	_environment.background_mode = Environment.BG_COLOR
	_environment.background_color = Color("254a53")
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.ambient_light_color = Color("f2dfb8")
	_environment.ambient_light_energy = 0.85
	_environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var environment_node := WorldEnvironment.new()
	environment_node.environment = _environment
	add_child(environment_node)
	_build_painted_ground()
	for region in ISLAND.regions:
		var bounds: Rect2 = region.bounds
		var ground := StaticBody3D.new()
		ground.collision_layer = 16
		ground.collision_mask = 0
		var size := Vector3(bounds.size.x, 0.5, bounds.size.y)
		ground.position = Vector3(bounds.get_center().x, -0.25, bounds.get_center().y)
		add_child(ground)
		LowPoly.collision(ground, size, Vector3.ZERO)
		var marker := Landmark.new()
		marker.kind = "travel"
		marker.title = region.name
		marker.position = region.center + Vector3(-6, 0, -3)
		add_child(marker)
	for boundary in [Vector3(-51, 2, 0), Vector3(51, 2, 0), Vector3(0, 2, -51), Vector3(0, 2, 51)]:
		var body := StaticBody3D.new()
		body.position = boundary
		body.collision_layer = 16
		add_child(body)
		LowPoly.collision(
			body, Vector3(2, 6, 104) if boundary.x != 0 else Vector3(104, 6, 2), Vector3.ZERO
		)
	_build_foliage()


func _build_foliage() -> void:
	for entry in DataCatalogGlobal.art.decor:
		var prop := StaticBody3D.new()
		prop.position = entry.position
		prop.collision_layer = 16
		prop.collision_mask = 0
		add_child(prop)
		IllustratedArt.sprite(prop, entry.art, entry.height)
		if entry.art in ["tree", "palm"]:
			LowPoly.collision(prop, Vector3(0.6, 2, 0.6), Vector3.UP)


func _build_painted_ground() -> void:
	_ground_material = ShaderMaterial.new()
	_ground_material.shader = GROUND_SHADER
	for key in ["sand", "grass", "stone"]:
		_ground_material.set_shader_parameter(key, DataCatalogGlobal.art.textures[key])
	if DisplayServer.get_name() == "headless":
		return
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(100, 100)
	var floor_node := MeshInstance3D.new()
	floor_node.mesh = mesh
	floor_node.material_override = _ground_material
	add_child(floor_node)
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(260, 260)
	var ocean := MeshInstance3D.new()
	ocean.mesh = water_mesh
	ocean.position.y = -0.12
	var water_material := ShaderMaterial.new()
	water_material.shader = WATER_SHADER
	ocean.material_override = water_material
	add_child(ocean)
	for index in 16:
		var foam := Sprite3D.new()
		foam.texture = DataCatalogGlobal.art.textures.foam
		foam.pixel_size = 0.025
		foam.rotation.x = -PI / 2
		foam.position = Vector3(-48 + index * 6.4, 0.04, 49.5)
		add_child(foam)


func _build_content() -> void:
	for definition in ISLAND.resource_nodes:
		var node := RESOURCE_SCENE.instantiate() as ResourceNode
		node.name = definition.id
		node.item_id = definition.item
		node.position = definition.position
		node.tint = definition.color
		node.form = definition.form
		node.required_tool = definition.get("tool", "")
		add_child(node)
	for spawn in ISLAND.enemy_spawns:
		var enemy := ENEMY_SCENE.instantiate() as Enemy
		enemy.name = spawn.id
		enemy.enemy_definition = DataCatalogGlobal.enemies[spawn.type]
		enemy.position = spawn.position
		add_child(enemy)
		_enemies[spawn.id] = enemy

	# Mara still owns the legacy quest, order and save contracts.
	var companion := Companion.new()
	companion.name = "Mara"
	companion.position = CharacterRoster.get_npc_starting_location("mara")
	add_child(companion)
	# Keep generic NPC work alongside the working companion until callers migrate.
	for npc_data in CharacterRoster.get_all_npcs():
		var npc_id: String = npc_data.npc_id
		if npc_id == "mara":
			continue
		var npc := NPC_SCENE.instantiate() as NPC
		npc.name = npc_id
		npc.position = npc_data.starting_location
		add_child(npc)
		npc.setup(npc_id)
		_npcs[npc_id] = npc

	var beacon := Landmark.new()
	beacon.position = Vector3(0, 0, 43)
	add_child(beacon)


func _process(delta: float) -> void:
	elapsed += delta
	_region_timer += delta
	if _samples.size() < 3600:
		_samples.append(delta * 1000)
	if _region_timer > 0.5:
		_region_timer = 0
		_update_region()
		var daylight := 0.7 + 0.3 * maxf(0, sin((get_time_of_day() - 0.25) * TAU))
		_environment.ambient_light_energy = daylight
		_ground_material.set_shader_parameter("daylight", daylight)
		_environment.background_color = Color("0c172d").lerp(Color("366475"), daylight)

	# Check for day change
	var current_day := int(elapsed / DAY_SECONDS)
	if current_day != _last_day:
		_last_day = current_day
		day_changed.emit(current_day)

	for index in HIT_POOL_SIZE:
		if _hit_times[index] > 0:
			_hit_times[index] -= delta
			_hit_pool[index].position.y += delta
			_hit_pool[index].visible = _hit_times[index] > 0


func _update_region() -> void:
	var player := GameManagerGlobal.get_player()
	if not player:
		return
	for region in ISLAND.regions:
		var point := Vector2(player.global_position.x, player.global_position.z)
		if (region.bounds as Rect2).has_point(point):
			current_region = region.id
			if not region.id in discovered:
				discovered.append(region.id)
				GameManagerGlobal.message_posted.emit("Discovered " + region.name)
				GameManagerGlobal.save(SaveManagerGlobal.AUTOSAVE_SLOT, false)
			break


func get_time_of_day() -> float:
	return fmod(elapsed / DAY_SECONDS, 1.0)


func get_time_string() -> String:
	var minutes := int(get_time_of_day() * 1440)
	return "Day %d · %02d:%02d" % [int(elapsed / DAY_SECONDS) + 1, minutes / 60, minutes % 60]


func nearby_station(at: Vector3, required: String) -> String:
	for structure: Structure in get_tree().get_nodes_in_group("structures"):
		if structure.kind == required and at.distance_to(structure.global_position) < 6:
			return structure.kind
	return ""


func place_structure(item_id: String, player: Player) -> bool:
	if get_tree().get_nodes_in_group("structures").size() >= MAX_OBJECTS:
		GameManagerGlobal.message_posted.emit("Building limit reached.")
		return false
	var kind := DataCatalogGlobal.item(item_id).structure
	var at := player.global_position + player._facing * 3.5
	at.y = 0
	if absf(at.x) > 47 or absf(at.z) > 47:
		return false
	if kind in ["wall", "roof", "door"]:
		var foundation: Structure
		for existing: Structure in get_tree().get_nodes_in_group("structures"):
			if (
				existing.kind == "foundation"
				and player.global_position.distance_to(existing.global_position) < 7
			):
				foundation = existing
		if not foundation:
			GameManagerGlobal.message_posted.emit("Stand near a shelter foundation first.")
			return false
		at = foundation.global_position
	for existing: Structure in get_tree().get_nodes_in_group("structures"):
		if at.distance_to(existing.global_position) < 2:
			if kind in ["wall", "roof", "door"] and existing.kind != kind:
				continue
			GameManagerGlobal.message_posted.emit("That position is occupied. Move and try again.")
			return false
	if not player.inventory_comp.remove_item(item_id):
		return false
	_add_structure(kind, at)
	player.illustration.play_action("build")
	GameManagerGlobal.message_posted.emit("Built " + kind + ".")
	return true


func _add_structure(kind: String, at: Vector3) -> void:
	var structure := Structure.new()
	structure.kind = kind
	structure.position = at
	add_child(structure)
	_refresh_shelter_visuals()


func _refresh_shelter_visuals() -> void:
	var structures := get_tree().get_nodes_in_group("structures")
	for foundation: Structure in structures:
		if foundation.kind != "foundation":
			continue
		var parts: Dictionary = {}
		for part: Structure in structures:
			if part.global_position.distance_to(foundation.global_position) < 1:
				parts[part.kind] = part
		if parts.has("wall") and parts.has("roof") and parts.has("door"):
			foundation.finish_shelter_visual()
			for key in ["wall", "roof", "door"]:
				parts[key].illustration.hide()


func rest(player: Player, foundation: Structure) -> bool:
	var parts: Array[String] = []
	for structure: Structure in get_tree().get_nodes_in_group("structures"):
		if structure.global_position.distance_to(foundation.global_position) < 1:
			parts.append(structure.kind)
	for part in ["foundation", "wall", "roof", "door"]:
		if not part in parts:
			GameManagerGlobal.message_posted.emit(
				"Shelter needs a foundation, wall, roof and door."
			)
			return false
	if _enemy_near(player.global_position):
		GameManagerGlobal.message_posted.emit("Enemies are too close to rest.")
		return false
	if player.survival_comp.hunger < 15 or player.survival_comp.thirst < 15:
		GameManagerGlobal.message_posted.emit("Eat and drink before resting.")
		return false
	elapsed += DAY_SECONDS / 4
	player.health_comp.heal(50)
	player.survival_comp.hunger -= 10
	player.survival_comp.thirst -= 10
	player.survival_comp.restore_stamina(100)
	var saved := GameManagerGlobal.save(SaveManagerGlobal.AUTOSAVE_SLOT, false) == OK
	GameManagerGlobal.message_posted.emit(
		(
			"Rested six hours. Health restored; game saved."
			if saved
			else "Rested six hours. Saving failed; retry from Pause."
		)
	)
	return true


func fast_travel(region_id: String) -> bool:
	var player := GameManagerGlobal.get_player()
	if not player or not region_id in discovered or _enemy_near(player.global_position):
		GameManagerGlobal.message_posted.emit(
			"Travel requires a discovered region and no nearby enemies."
		)
		return false
	for region in ISLAND.regions:
		if region.id == region_id:
			player.global_position = region.center + Vector3(0, 1, 0)
			player.velocity = Vector3.ZERO
			elapsed += 60
			GameManagerGlobal.save(SaveManagerGlobal.AUTOSAVE_SLOT, false)
			GameManagerGlobal.resume_game()
			return true
	return false


func _enemy_near(at: Vector3) -> bool:
	for enemy: Enemy in _enemies.values():
		if not enemy.health_comp.is_dead() and enemy.global_position.distance_to(at) < 12:
			return true
	return false


func spawn_pickup(item_id: String, count: int, at: Vector3) -> bool:
	if get_tree().get_nodes_in_group("pickups").size() >= MAX_OBJECTS:
		return false
	var pickup := PICKUP_SCENE.instantiate() as ItemPickup
	pickup.item_id = item_id
	pickup.count = count
	pickup.position = at
	add_child(pickup)
	return true


func show_hit(at: Vector3, damage: int) -> void:
	var label := _hit_pool[_hit_index]
	label.text = str(damage)
	label.position = at
	label.visible = true
	_hit_times[_hit_index] = 0.7
	_hit_index = (_hit_index + 1) % HIT_POOL_SIZE


func export_telemetry() -> Error:
	var file := FileAccess.open("user://performance.csv", FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	file.store_csv_line(PackedStringArray(["frame", "frame_ms"]))
	for index in _samples.size():
		file.store_csv_line(PackedStringArray([str(index), str(_samples[index])]))
	file.close()
	return OK


func serialize() -> Dictionary:
	var enemies: Dictionary = {}
	for key in _enemies:
		enemies[key] = _enemies[key].serialize()
	var npcs: Dictionary = {}
	for key in _npcs:
		npcs[key] = _npcs[key].serialize()
	var structures: Array = []
	for node in get_tree().get_nodes_in_group("structures"):
		structures.append(node.serialize())
	var pickups: Array = []
	for node in get_tree().get_nodes_in_group("pickups"):
		pickups.append(node.serialize())
	return {
		"elapsed": elapsed,
		"discovered": discovered.duplicate(),
		"resources": ResourceSystemGlobal.serialize(),
		"enemies": enemies,
		"npcs": npcs,
		"structures": structures,
		"pickups": pickups,
		"companion": get_node("Mara").serialize()
	}


func deserialize(data: Dictionary) -> void:
	get_node("Mara").deserialize(data.get("companion", {}))
	elapsed = float(data.get("elapsed", 360))
	discovered.assign(data.get("discovered", ["beach"]))
	ResourceSystemGlobal.deserialize(data.get("resources", {}))
	for key in data.get("enemies", {}):
		if _enemies.has(key):
			_enemies[key].deserialize(data.enemies[key])
	for key in data.get("npcs", {}):
		if _npcs.has(key):
			_npcs[key].deserialize(data.npcs[key])
	for structure in data.get("structures", []):
		_add_structure(structure.kind, StateValidation.vec3(structure.position))
	for pickup in data.get("pickups", []):
		spawn_pickup(pickup.item_id, int(pickup.count), StateValidation.vec3(pickup.position))
