class_name TurnManager
extends RefCounted

const CardDataScript := preload("res://scripts/data/card_data.gd")
const CardInstanceScript := preload("res://scripts/state/card_instance.gd")
const EnemyAIResolverScript := preload("res://scripts/combat/enemy_ai_resolver.gd")
const CardEffectResolverScript := preload("res://scripts/combat/card_effect_resolver.gd")

var enemy_ai = EnemyAIResolverScript.new()
var card_effects = CardEffectResolverScript.new()


func start_debug_combat(enemy_id: String) -> Array[String]:
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

	var enemy_data := DataRegistry.get_enemy(enemy_id)
	if enemy_data.is_empty():
		logs.append("Missing enemy data: %s" % enemy_id)
		return logs
	RunState.combat.enemies.clear()
	RunState.combat.enemies.append(enemy_ai.create_enemy(enemy_data))
	var drawn: Array[Dictionary] = RunState.deck.draw_cards(int(DataRegistry.get_balance("combat.draw_per_turn", 6)))
	logs.append("Combat started: %s." % enemy_data.get("name", enemy_id))
	logs.append("Drew %d cards." % drawn.size())
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
	logs.append("Played %s." % CardDataScript.card_name(card))
	logs.append_array(card_effects.resolve(card, target_index))
	_update_outcome(logs)
	return logs


func end_player_turn() -> Array[String]:
	var logs: Array[String] = []
	if RunState.combat.outcome != "active":
		return logs
	var discarded := RunState.deck.discard_hand()
	logs.append("Ended turn. Discarded %d cards." % discarded)
	logs.append_array(enemy_ai.execute_enemy_turn())
	_update_outcome(logs)
	if RunState.combat.outcome == "active":
		_start_player_turn(logs)
	return logs


func _start_player_turn(logs: Array[String]) -> void:
	RunState.combat.turn_index += 1
	RunState.combat.player_block = 0
	RunState.combat.energy = RunState.combat.max_energy
	var drawn: Array[Dictionary] = RunState.deck.draw_cards(int(DataRegistry.get_balance("combat.draw_per_turn", 6)))
	logs.append("Turn %d started. Drew %d cards." % [RunState.combat.turn_index, drawn.size()])


func _update_outcome(logs: Array[String]) -> void:
	var any_alive := false
	for enemy in RunState.combat.enemies:
		if int(enemy.get("hp", 0)) > 0:
			any_alive = true
	if not any_alive:
		RunState.combat.outcome = "victory"
		RunState.combat.in_combat = false
		logs.append("Victory.")
	elif RunState.current_hp <= 0:
		RunState.combat.outcome = "defeat"
		RunState.combat.in_combat = false
		logs.append("Defeat.")
