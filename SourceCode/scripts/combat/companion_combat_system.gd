class_name CompanionCombatSystem
extends RefCounted

const BondSystemScript := preload("res://scripts/systems/bond_system.gd")
const OathTacticResolverScript := preload("res://scripts/combat/oath_tactic_resolver.gd")

var bond_system = BondSystemScript.new()
var oath_resolver = OathTacticResolverScript.new()


func execute_end_turn_attacks() -> Array[String]:
	var logs: Array[String] = []
	for companion in RunState.party.companions:
		var target_index := _choose_marked_target()
		if target_index < 0:
			break
		var damage := _base_damage(companion) + int(companion.get("attack_bonus", 0)) + bond_system.get_damage_bonus(companion) + RunState.equipment.get_total_bonus("companion_attack_damage", String(companion.get("id", "")))
		var enemy: Dictionary = RunState.combat.enemies[target_index]
		enemy["hp"] = max(int(enemy.get("hp", 0)) - damage, 0)
		RunState.combat.enemies[target_index] = enemy
		logs.append("%s attacked marked target for %d." % [companion.get("name", "Companion"), damage])
		var mark_bonus := bond_system.get_mark_bonus(companion)
		if mark_bonus > 0 and int(enemy.get("hp", 0)) > 0:
			_add_mark(target_index, mark_bonus)
			logs.append("%s bond 100: applied %d Tactical Mark." % [companion.get("name", "Companion"), mark_bonus])
		logs.append_array(oath_resolver.on_companion_attack(companion, target_index))
	return logs


func apply_bond_start_bonuses() -> Array[String]:
	var logs: Array[String] = []
	for companion in RunState.party.companions:
		var block := bond_system.get_start_block_bonus(companion)
		if block > 0:
			RunState.combat.player_block += block
			logs.append("%s bond 60: gained %d start block." % [companion.get("name", "Companion"), block])
	return logs


func _base_damage(companion: Dictionary) -> int:
	var companion_data := DataRegistry.get_companion(String(companion.get("id", "")))
	return int(companion_data.get("base_attack", 3))


func _choose_marked_target() -> int:
	var best_index := -1
	var best_mark := -1
	for i in range(RunState.combat.enemies.size()):
		var enemy: Dictionary = RunState.combat.enemies[i]
		if int(enemy.get("hp", 0)) <= 0:
			continue
		var statuses: Dictionary = enemy.get("statuses", {})
		var mark := int(statuses.get("tactical_mark", 0))
		if mark > best_mark:
			best_mark = mark
			best_index = i
	return best_index


func _add_mark(target_index: int, amount: int) -> void:
	var enemy: Dictionary = RunState.combat.enemies[target_index]
	var statuses: Dictionary = enemy.get("statuses", {})
	statuses["tactical_mark"] = int(statuses.get("tactical_mark", 0)) + amount
	enemy["statuses"] = statuses
	RunState.combat.enemies[target_index] = enemy
