extends Node
## Quest transitions, trust, recruitment and narrative endings are system-owned.

signal quests_changed
signal dialogue_posted(text: String)

const QUESTS = preload("res://resources/definitions/quests/Quests.tres")
const DIALOGUE = preload("res://resources/definitions/dialogue/Mara.tres")
const BEACON_COST := {"iron_ingot": 3, "fiber": 2, "crystal": 1}

var states: Dictionary = {}
var choices: Dictionary = {}
var kills: Dictionary = {}
var trust := 0
var recruited := false
var ending := ""


func reset() -> void:
	states.clear()
	choices.clear()
	kills.clear()
	trust = 0
	recruited = false
	ending = ""


func available_quest() -> QuestDefinition:
	for quest: QuestDefinition in QUESTS.entries:
		if states.get(quest.quest_id, "") == "complete":
			continue
		if quest.prerequisite.is_empty() or states.get(quest.prerequisite, "") == "complete":
			return quest
	return null


func accept_quest() -> void:
	var quest := available_quest()
	if quest:
		states[quest.quest_id] = "active"
		quests_changed.emit()


func complete_quest(choice_id: String, inventory: InventoryComponent) -> bool:
	var quest := available_quest()
	if not quest or states.get(quest.quest_id, "") != "active":
		return false
	if not quest.kill_target.is_empty() and int(kills.get(quest.kill_target, 0)) == 0:
		dialogue_posted.emit("The Guardian still keeps watch. Prepare before you face it.")
		return false
	for choice in quest.choices:
		if choice.id != choice_id:
			continue
		if not inventory.exchange(quest.costs, choice.rewards):
			dialogue_posted.emit("Gather the requested supplies and leave room for your reward.")
			return false
		states[quest.quest_id] = "complete"
		choices[quest.quest_id] = choice_id
		trust = clampi(trust + int(choice.trust), -10, 10)
		dialogue_posted.emit(choice.text)
		quests_changed.emit()
		GameManagerGlobal.save(SaveManagerGlobal.AUTOSAVE_SLOT, false)
		return true
	return false


func recruit() -> bool:
	if trust < 2 or recruited:
		return false
	recruited = true
	dialogue_posted.emit("Mara: I'll watch your back. Let's get off this island together.")
	quests_changed.emit()
	return true


func record_kill(enemy_id: String) -> void:
	if DataCatalogGlobal.enemies.has(enemy_id):
		kills[enemy_id] = mini(1000000, int(kills.get(enemy_id, 0)) + 1)
		quests_changed.emit()


func finish(choice: String, inventory: InventoryComponent) -> bool:
	if not ending.is_empty() or states.get("guardian", "") != "complete":
		return false
	if not DIALOGUE.endings.has(choice) or (choice == "together" and trust < 3):
		return false
	if not inventory.exchange(BEACON_COST, {}):
		GameManagerGlobal.message_posted.emit("Beacon needs 3 iron ingots, 2 fiber and a crystal.")
		return false
	ending = choice
	GameManagerGlobal.save(SaveManagerGlobal.AUTOSAVE_SLOT, false)
	GameManagerGlobal.open_menu("ending")
	return true


func serialize() -> Dictionary:
	return {
		"states": states.duplicate(),
		"choices": choices.duplicate(),
		"kills": kills.duplicate(),
		"trust": trust,
		"recruited": recruited,
		"ending": ending
	}


func deserialize(data: Dictionary) -> void:
	states = data.get("states", {}).duplicate()
	choices = data.get("choices", {}).duplicate()
	kills = data.get("kills", {}).duplicate()
	trust = clampi(int(data.get("trust", 0)), -10, 10)
	recruited = data.get("recruited", false)
	ending = data.get("ending", "")
	quests_changed.emit()
