extends Node

signal combat_started(attacker: Node, defender: Node)
signal combat_ended(attacker: Node, defender: Node)
signal hit_dealt(attacker: Node, defender: Node, damage: float, is_critical: bool)
signal hit_received(defender: Node, attacker: Node, damage: float)
signal entity_defeated(entity: Node, by: Node)

const BASE_CRIT_CHANCE: float = 0.05
const BASE_CRIT_MULTIPLIER: float = 1.5
const ARMOR_DAMAGE_REDUCTION: float = 0.5

func calculate_damage(attacker_damage: float, defender_armor: float, is_critical: bool = false) -> float:
	var multiplier = BASE_CRIT_MULTIPLIER if is_critical else 1.0
	var base = attacker_damage * multiplier
	var defense = defender_armor * ARMOR_DAMAGE_REDUCTION
	return max(1.0, base - defense)

func roll_critical(crit_chance: float = BASE_CRIT_CHANCE) -> bool:
	return randf() < crit_chance

func calculate_stamina_cost(base_cost: float, weapon_weight: float, skill_level: int) -> float:
	var cost = base_cost + (weapon_weight * 2.0) - (skill_level * 1.5)
	return max(5.0, cost)

func apply_damage(attacker: Node, defender: Node, base_damage: float, armor: float = 0.0, crit_chance: float = BASE_CRIT_CHANCE) -> Dictionary:
	var is_crit = roll_critical(crit_chance)
	var final_damage = calculate_damage(base_damage, armor, is_crit)
	var health_comp = defender.get_node_or_null("HealthComponent")
	var was_dead = health_comp.is_dead() if health_comp else true
	var applied := false
	if health_comp and not was_dead:
		applied = health_comp.take_damage(final_damage, attacker)
		if applied and health_comp.is_dead():
			entity_defeated.emit(defender, attacker)

	if applied:
		hit_dealt.emit(attacker, defender, final_damage, is_crit)
		hit_received.emit(defender, attacker, final_damage)

	return {
		"damage": final_damage if applied else 0.0,
		"is_critical": is_crit if applied else false,
		"killed": health_comp.is_dead() if health_comp else false,
		"already_dead": was_dead,
		"applied": applied
	}

func start_combat(attacker: Node, defender: Node) -> void:
	combat_started.emit(attacker, defender)

func end_combat(attacker: Node, defender: Node) -> void:
	combat_ended.emit(attacker, defender)