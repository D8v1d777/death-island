class_name CropDefinition
extends Resource
## Data-driven crop definitions for farming system.

# Predefined crop configurations (3+ distinct crops)
const CROP_DEFINITIONS: Dictionary = {
	"potato":
	{
		"crop_id": "potato",
		"display_name": "Potato",
		"seed_item_id": "potato_seed",
		"harvest_item_id": "potato",
		"growth_stages": 4,
		"stage_durations_minutes": [240.0, 240.0, 240.0, 240.0],
		"water_per_stage": [1, 1, 1, 1],
		"harvest_yield": 3,
		"harvest_yield_variance": 1,
		"regrows": false,
		"description": "Hardy tuber. Grows in 16 hours. Good staple crop."
	},
	"corn":
	{
		"crop_id": "corn",
		"display_name": "Corn",
		"seed_item_id": "corn_seed",
		"harvest_item_id": "corn",
		"growth_stages": 5,
		"stage_durations_minutes": [300.0, 300.0, 300.0, 300.0, 300.0],
		"water_per_stage": [2, 2, 2, 2, 2],
		"harvest_yield": 2,
		"harvest_yield_variance": 1,
		"regrows": false,
		"description": "Tall grain. Grows in 25 hours. High calorie yield."
	},
	"tomato":
	{
		"crop_id": "tomato",
		"display_name": "Tomato",
		"seed_item_id": "tomato_seed",
		"harvest_item_id": "tomato",
		"growth_stages": 4,
		"stage_durations_minutes": [180.0, 180.0, 180.0, 180.0],
		"water_per_stage": [1, 2, 2, 1],
		"harvest_yield": 4,
		"harvest_yield_variance": 2,
		"regrows": true,
		"regrowth_stages": 2,
		"regrowth_duration_minutes": 360.0,
		"description": "Fast-growing fruit. Regrows after harvest. Needs more water mid-growth."
	},
	"herb":
	{
		"crop_id": "herb",
		"display_name": "Medicinal Herb",
		"seed_item_id": "herb_seed",
		"harvest_item_id": "herb",
		"growth_stages": 3,
		"stage_durations_minutes": [120.0, 120.0, 120.0],
		"water_per_stage": [1, 1, 1],
		"harvest_yield": 2,
		"harvest_yield_variance": 1,
		"regrows": true,
		"regrowth_stages": 1,
		"regrowth_duration_minutes": 240.0,
		"description": "Quick-growing herb for bandages and medicine. Regrows once."
	}
}

@export var crop_id: String = ""
@export var display_name: String = ""
@export var seed_item_id: String = ""
@export var harvest_item_id: String = ""
@export var growth_stages: int = 4
@export var stage_durations_minutes: Array[float] = [360.0, 360.0, 360.0, 360.0]
@export var water_per_stage: Array[int] = [1, 1, 1, 1]
@export var harvest_yield: int = 1
@export var harvest_yield_variance: int = 0
@export var regrows: bool = false
@export var regrowth_stages: int = 2
@export var regrowth_duration_minutes: float = 480.0
@export var required_tool: String = ""
@export var soil_type: String = "any"
@export var season: String = "any"
@export var description: String = ""


static func get_definition(crop_id: String) -> Dictionary:
	return CROP_DEFINITIONS.get(crop_id, {})


static func get_all_crop_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(CROP_DEFINITIONS.keys())
	return ids


static func total_growth_time(crop_id: String) -> float:
	var def := get_definition(crop_id)
	var total := 0.0
	for duration in def.get("stage_durations_minutes", []):
		total += duration
	return total


static func create_from_id(crop_id: String) -> CropDefinition:
	var def := get_definition(crop_id)
	if def.is_empty():
		return null
	var crop := CropDefinition.new()
	for key in def:
		crop.set(key, def[key])
	return crop
