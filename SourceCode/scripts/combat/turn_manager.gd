class_name TurnManager
extends RefCounted

const CardDataScript := preload("res://scripts/data/card_data.gd")
const CardInstanceScript := preload("res://scripts/state/card_instance.gd")
const EnemyAIResolverScript := preload("res://scripts/combat/enemy_ai_resolver.gd")
const CardEffectResolverScript := preload("res://scripts/combat/card_effect_resolver.gd")
const CompanionCombatSystemScript := preload("res://scripts/combat/companion_combat_system.gd")
const OathTacticResolverScript := preload("res://scripts/combat/oath_tactic_resolver.gd")
const BondSystemScript := preload("res://scripts/systems/bond_system.gd")

var enemy_ai = EnemyAIResolverScript.new()
var card_effects = CardEffectResolverScript.new()
var companion_combat = CompanionCombatSystemScript.new()
var oath_resolver = OathTacticResolverScript.new()
var bond_system = BondSystemScript.new()


func start_combat(enemy_id: String) -> Array[String]:
	var logs: Array[String] = []
	if not RunState.is_run_active:
		RunState.start_new_run()
	RunState.combat.reset()
	RunState.deck.discard_hand()
	RunState.combat.in_combat = true
	RunState.combat.outcome = "active"
	RunState.combat.turn_index = 1
	RunState.combat.max_energy = int(DataRegistry.get_balance("combat.energy_per_turn", 4))
	RunState.combat.energy = RunState.combat.max_energy
	RunState.combat.cards_played_this_turn = 0

	var enemy_ids := MapState.get_selected_enemy_ids(enemy_id)
	RunState.combat.enemies.clear()
	var enemy_names: Array[String] = []
	for selected_id in enemy_ids:
		var enemy_data := DataRegistry.get_enemy(selected_id)
		if enemy_data.is_empty():
			logs.append("Missing enemy data: %s" % selected_id)
			continue
		RunState.combat.enemies.append(enemy_ai.create_enemy(enemy_data))
		enemy_names.append(String(enemy_data.get("name", selected_id)))
	if RunState.combat.enemies.is_empty():
		return logs
	var node_type := MapState.get_selected_node_type() if MapState.has_selected_node() else "combat_fallback"
	RunTelemetry.begin_combat(enemy_ids[0], node_type)
	var drawn: Array[Dictionary] = RunState.deck.draw_cards(int(DataRegistry.get_balance("combat.draw_per_turn", 6)))
	logs.append("Combat started: %s." % ", ".join(PackedStringArray(enemy_names)))
	logs.append("Drew %d cards." % drawn.size())
	_apply_equipment_start_bonuses(logs)
	logs.append_array(oath_resolver.on_combat_start())
	logs.append_array(companion_combat.apply_bond_start_bonuses())
	return logs


func play_card(hand_index: int, target_index: int = 0) -> Array[String]:
	var logs: Array[String] = []
	if RunState.combat.outcome != "active":
		return logs
	if hand_index < 0 or hand_index >= RunState.deck.hand.size():
		return logs
	var instance: Dictionary = RunState.deck.hand[hand_index]
	var card := DataRegistry.get_card(CardInstanceScript.get_card_id(instance))
	var cost := CardDataScript.card_cost(card)
	if cost > RunState.combat.energy:
		logs.append("Not enough energy for %s." % CardDataScript.card_name(card))
		return logs

	RunState.combat.energy -= cost
	RunState.deck.play_card(hand_index)
	RunState.combat.cards_played_this_turn += 1
	RunTelemetry.record_card_play(CardInstanceScript.get_card_id(instance))
	logs.append("Played %s." % CardDataScript.card_name(card))
	logs.append_array(card_effects.resolve(card, target_index, instance))
	logs.append_array(oath_resolver.on_card_play(card, target_index))
	_update_outcome(logs)
	return logs


func end_player_turn() -> Array[String]:
	var logs: Array[String] = []
	if RunState.combat.outcome != "active":
		return logs
	var discarded := RunState.deck.discard_hand()
	logs.append("Ended turn. Discarded %d cards." % discarded)
	logs.append_array(companion_combat.execute_end_turn_attacks())
	_update_outcome(logs)
	if RunState.combat.outcome != "active":
		return logs
	logs.append_array(enemy_ai.execute_enemy_turn())
	_update_outcome(logs)
	if RunState.combat.outcome == "active":
		_start_player_turn(logs)
	return logs


func _start_player_turn(logs: Array[String]) -> void:
	RunState.combat.turn_index += 1
	RunState.combat.player_block = 0
	RunState.combat.energy = RunState.combat.max_energy
	RunState.combat.cards_played_this_turn = 0
	var drawn: Array[Dictionary] = RunState.deck.draw_cards(int(DataRegistry.get_balance("combat.draw_per_turn", 6)))
	logs.append("Turn %d started. Drew %d cards." % [RunState.combat.turn_index, drawn.size()])
	logs.append_array(companion_combat.apply_bond_start_bonuses())
	if RunState.combat.healing_reduction_turns > 0:
		RunState.combat.healing_reduction_turns -= 1
		if RunState.combat.healing_reduction_turns <= 0:
			RunState.combat.healing_reduction_percent = 0
			logs.append("Healing reduction faded.")


func _update_outcome(logs: Array[String]) -> void:
	var any_alive := false
	for enemy in RunState.combat.enemies:
		if int(enemy.get("hp", 0)) > 0:
			any_alive = true
	if not any_alive:
		RunState.combat.outcome = "victory"
		RunState.combat.in_combat = false
		logs.append("Victory.")
		var node_type := MapState.get_selected_node_type() if MapState.has_selected_node() else "combat_fallback"
		var gold_table: Dictionary = DataRegistry.get_balance("rewards.gold_by_node_type", {})
		var gold_gain := int(gold_table.get(node_type, 0))
		if gold_gain > 0:
			RunState.gold += gold_gain
			logs.append("Gained %d gold." % gold_gain)
		logs.append_array(bond_system.award_for_victory(node_type))
		RunTelemetry.end_combat("victory", RunState.combat.turn_index)
	elif RunState.current_hp <= 0:
		RunState.combat.outcome = "defeat"
		RunState.combat.in_combat = false
		logs.append("Defeat.")
		RunTelemetry.end_combat("defeat", RunState.combat.turn_index)


func _apply_equipment_start_bonuses(logs: Array[String]) -> void:
	var start_block := RunState.equipment.get_total_bonus("start_block")
	if start_block > 0:
		RunState.combat.player_block += start_block
		logs.append("Equipment: gained %d start block." % start_block)
