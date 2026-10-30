extends Node

signal survival_update(delta_time: float)

# Global survival settings that affect all entities
@export var global_hunger_rate: float = 1.0
@export var global_thirst_rate: float = 1.5
@export var global_stamina_regen: float = 10.0


func apply_starvation_damage(entity: Node, delta: float) -> float:
	var survival = entity.get_node_or_null("SurvivalComponent")
	var health = entity.get_node_or_null("HealthComponent")

	if not survival or not health:
		return 0.0

	if survival.hunger <= 0.0:
		var damage = 2.0 * delta
		health.take_damage(damage, entity)
		return damage
	return 0.0


func apply_dehydration_damage(entity: Node, delta: float) -> float:
	var survival = entity.get_node_or_null("SurvivalComponent")
	var health = entity.get_node_or_null("HealthComponent")

	if not survival or not health:
		return 0.0

	if survival.thirst <= 0.0:
		var damage = 3.0 * delta
		health.take_damage(damage, entity)
		return damage
	return 0.0


func restore_hunger(entity: Node, amount: float) -> void:
	var survival = entity.get_node_or_null("SurvivalComponent")
	if survival:
		survival.eat(amount)


func restore_thirst(entity: Node, amount: float) -> void:
	var survival = entity.get_node_or_null("SurvivalComponent")
	if survival:
		survival.drink(amount)


func can_sprint(entity: Node) -> bool:
	var survival = entity.get_node_or_null("SurvivalComponent")
	if survival:
		return survival.stamina > 10.0
	return false


func drain_stamina(entity: Node, amount: float) -> bool:
	var survival = entity.get_node_or_null("SurvivalComponent")
	if survival:
		return survival.consume_stamina(amount)
	return false


func get_survival_status(entity: Node) -> Dictionary:
	var survival = entity.get_node_or_null("SurvivalComponent")
	if not survival:
		return {}

	return {
		"hunger": survival.hunger,
		"max_hunger": survival.max_hunger,
		"thirst": survival.thirst,
		"max_thirst": survival.max_thirst,
		"stamina": survival.stamina,
		"max_stamina": survival.max_stamina,
		"hunger_percent": survival.get_hunger_percent(),
		"thirst_percent": survival.get_thirst_percent(),
		"stamina_percent": survival.get_stamina_percent(),
		"is_starving": survival.hunger <= 0.0,
		"is_dehydrated": survival.thirst <= 0.0,
		"is_exhausted": survival.stamina <= 0.0
	}
