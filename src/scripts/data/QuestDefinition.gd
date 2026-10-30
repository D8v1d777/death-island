class_name QuestDefinition
extends Resource
## Authored quest with alternative hand-in outcomes.

@export var quest_id := ""
@export var title := ""
@export_multiline var description := ""
@export var prerequisite := ""
@export var costs: Dictionary = {}
@export var kill_target := ""
@export var choices: Array[Dictionary] = []
