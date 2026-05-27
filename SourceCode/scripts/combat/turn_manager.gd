class_name TurnManager
extends RefCounted

const CardDataScript := preload("res://scripts/data/card_data.gd")
const CardInstanceScript := preload("res://scripts/state/card_instance.gd")
const EnemyAIResolverScript := preload("res://scripts/combat/enemy_ai_resolver.gd")
const CardEffectResolverScript := preload("res://scripts/combat/card_effect_resolver.gd")
const CompanionCombatSystemScript := preload("res://scripts/combat/companion_combat_system.gd")
const OathTacticResolverScript := preload("res://scripts/combat/oath_tactic_resolver.gd")
const BondSystemScript := preload("res://scripts/systems/bond_system.gd")
const CardPlayRulesScript := preload("res://scripts/combat/card_play_rules.gd")

var enemy_ai = EnemyAIResolverScript.new()
var card_effects = CardEffectResolverScript.new()
var companion_combat = CompanionCombatSystemScript.new()
var oath_resolver = OathTacticResolverScript.new()
var bond_system = BondSystemScript.new()
var last_update_advanced_wave := false


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

	var enemy_waves: Array = MapState.get_selected_enemy_waves(enemy_id)
	if enemy_waves.is_empty():
		logs.append("Missing enemy wave data.")
		return logs
	RunState.combat.enemy_waves = _duplicate_enemy_waves(enemy_waves)
	RunState.combat.wave_index = 0
	RunState.combat.wave_count = maxi(RunState.combat.enemy_waves.size(), 1)
	RunState.combat.wave_hp_lost.clear()
	RunState.combat.wave_turns.clear()
	var first_wave_ids := _enemy_ids_for_wave(0)
	var enemy_names := _spawn_enemy_wave(first_wave_ids, logs)
	if RunState.combat.enemies.is_empty():
		return logs
	var node_type := MapState.get_selected_node_type() if MapState.has_selected_node() else "combat_fallback"
	RunTelemetry.begin_combat(first_wave_ids[0], node_type, RunState.combat.wave_count, _flatten_enemy_waves(RunState.combat.enemy_waves))
	RunTelemetry.record_combat_wave(1, RunState.combat.wave_count, first_wave_ids)
	var drawn: Array[Dictionary] = RunState.deck.draw_cards(int(DataRegistry.get_balance("combat.draw_per_turn", 6)))
	_start_wave_record()
	if RunState.combat.wave_count > 1:
		logs.append("Combat started: Wave 1/%d - %s." % [RunState.combat.wave_count, ", ".join(PackedStringArray(enemy_names))])
	else:
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
	var validation := CardPlayRulesScript.validate_play(card, hand_index, target_index)
	if not bool(validation.get("ok", false)):
		logs.append(String(validation.get("message", "")))
		return logs

	var cost := CardDataScript.card_cost(card)
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
	if last_update_advanced_wave:
		_start_player_turn(logs)
		return logs
	logs.append_array(enemy_ai.execute_enemy_turn())
	_update_outcome(logs)
	if RunState.combat.outcome == "active":
		_start_player_turn(logs)
	return logs


func _start_player_turn(logs: Array[String]) -> void:
	RunState.combat.turn_index += 1
	RunState.combat.player_block = 0
	var energy_penalty: int = maxi(RunState.combat.energy_reduction_next_turn, 0)
	RunState.combat.energy = maxi(RunState.combat.max_energy - energy_penalty, 0)
	RunState.combat.energy_reduction_next_turn = 0
	RunState.combat.cards_played_this_turn = 0
	var drawn: Array[Dictionary] = RunState.deck.draw_cards(int(DataRegistry.get_balance("combat.draw_per_turn", 6)))
	logs.append("Turn %d started. Drew %d cards." % [RunState.combat.turn_index, drawn.size()])
	if energy_penalty > 0:
		logs.append("Enemy disruption reduced energy by %d." % energy_penalty)
	logs.append_array(companion_combat.apply_bond_start_bonuses())
	if RunState.combat.healing_reduction_turns > 0:
		RunState.combat.healing_reduction_turns -= 1
		if RunState.combat.healing_reduction_turns <= 0:
			RunState.combat.healing_reduction_percent = 0
			logs.append("Healing reduction faded.")


func _update_outcome(logs: Array[String]) -> void:
	last_update_advanced_wave = false
	var any_alive := false
	for enemy in RunState.combat.enemies:
		if int(enemy.get("hp", 0)) > 0:
			any_alive = true
	if not any_alive:
		if _advance_wave(logs):
			last_update_advanced_wave = true
			return
		_close_current_wave_record()
		RunState.combat.outcome = "victory"
		RunState.combat.in_combat = false
		logs.append("Victory.")
		var node_type := MapState.get_selected_node_type() if MapState.has_selected_node() else "combat_fallback"
		var gold_table: Dictionary = DataRegistry.get_balance("rewards.gold_by_node_type", {})
		var gold_gain := int(gold_table.get(node_type, 0))
		if gold_gain > 0:
			RunState.gold += gold_gain
			logs.append("Gained %d gold." % gold_gain)
		logs.append_array(_grant_elite_equipment_reward(node_type))
		logs.append_array(bond_system.award_for_victory(node_type))
		RunTelemetry.end_combat("victory", RunState.combat.turn_index)
	elif RunState.current_hp <= 0:
		_close_current_wave_record()
		RunState.combat.outcome = "defeat"
		RunState.combat.in_combat = false
		logs.append("Defeat.")
		RunTelemetry.end_combat("defeat", RunState.combat.turn_index)


func _advance_wave(logs: Array[String]) -> bool:
	var next_wave_index: int = RunState.combat.wave_index + 1
	if next_wave_index >= RunState.combat.wave_count:
		return false
	_close_current_wave_record()
	RunState.combat.wave_index = next_wave_index
	var enemy_ids := _enemy_ids_for_wave(next_wave_index)
	var enemy_names := _spawn_enemy_wave(enemy_ids, logs)
	if RunState.combat.enemies.is_empty():
		return false
	_start_wave_record()
	RunTelemetry.record_combat_wave(next_wave_index + 1, RunState.combat.wave_count, enemy_ids)
	logs.append("Wave %d/%d arrived: %s." % [
		next_wave_index + 1,
		RunState.combat.wave_count,
		", ".join(PackedStringArray(enemy_names)),
	])
	return true


func _grant_elite_equipment_reward(node_type: String) -> Array[String]:
	var logs: Array[String] = []
	if node_type != "elite":
		return logs
	var config: Dictionary = DataRegistry.get_balance("rewards.elite_equipment_reward", {})
	if not bool(config.get("enabled", false)):
		return logs
	var rarities: Array = config.get("rarities", [])
	var pool: Array[Dictionary] = []
	for item in DataRegistry.get_all_equipment():
		if typeof(item) != TYPE_DICTIONARY:
			continue
		if not rarities.is_empty() and not rarities.has(String(item.get("rarity", ""))):
			continue
		pool.append(item)
	if pool.is_empty():
		return logs
	var item: Dictionary = RngService.pick(pool, {})
	var instance := RunState.equipment.add_equipment(String(item.get("id", "")))
	if instance.is_empty():
		return logs
	logs.append("Elite spoils: gained %s." % item.get("name", "equipment"))
	return logs


func _spawn_enemy_wave(enemy_ids: Array, logs: Array[String]) -> Array[String]:
	RunState.combat.enemies.clear()
	var enemy_names: Array[String] = []
	for selected_id in enemy_ids:
		var enemy_id := String(selected_id)
		var enemy_data := DataRegistry.get_enemy(enemy_id)
		if enemy_data.is_empty():
			logs.append("Missing enemy data: %s" % enemy_id)
			continue
		RunState.combat.enemies.append(enemy_ai.create_enemy(enemy_data))
		enemy_names.append(String(enemy_data.get("name", enemy_id)))
	return enemy_names


func _enemy_ids_for_wave(wave_index: int) -> Array[String]:
	var ids: Array[String] = []
	if wave_index < 0 or wave_index >= RunState.combat.enemy_waves.size():
		return ids
	var raw_wave: Variant = RunState.combat.enemy_waves[wave_index]
	if typeof(raw_wave) != TYPE_ARRAY:
		return ids
	for enemy_id in raw_wave:
		var id_text := String(enemy_id)
		if not id_text.is_empty():
			ids.append(id_text)
	return ids


func _duplicate_enemy_waves(waves: Array) -> Array:
	var duplicate: Array = []
	for wave in waves:
		if typeof(wave) != TYPE_ARRAY:
			continue
		var ids: Array[String] = []
		for enemy_id in wave:
			var id_text := String(enemy_id)
			if not id_text.is_empty():
				ids.append(id_text)
		if not ids.is_empty():
			duplicate.append(ids)
	return duplicate


func _flatten_enemy_waves(waves: Array) -> Array[String]:
	var ids: Array[String] = []
	for wave in waves:
		if typeof(wave) != TYPE_ARRAY:
			continue
		for enemy_id in wave:
			var id_text := String(enemy_id)
			if not id_text.is_empty():
				ids.append(id_text)
	return ids


func _start_wave_record() -> void:
	RunState.combat.wave_start_hp = RunState.current_hp
	RunState.combat.wave_start_turn = maxi(RunState.combat.turn_index, 1)


func _close_current_wave_record() -> void:
	var expected_size: int = RunState.combat.wave_index + 1
	if RunState.combat.wave_hp_lost.size() >= expected_size:
		return
	RunState.combat.wave_hp_lost.append(maxi(RunState.combat.wave_start_hp - RunState.current_hp, 0))
	RunState.combat.wave_turns.append(maxi(RunState.combat.turn_index - RunState.combat.wave_start_turn + 1, 1))


func _apply_equipment_start_bonuses(logs: Array[String]) -> void:
	var start_block := RunState.equipment.get_total_bonus("start_block")
	if start_block > 0:
		RunState.combat.player_block += start_block
		logs.append("Equipment: gained %d start block." % start_block)
