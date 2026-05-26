class_name OathTacticResolver
extends RefCounted


func on_combat_start() -> Array[String]:
	var logs: Array[String] = []
	for companion in RunState.party.companions:
		match String(companion.get("oath_id", "")):
			"sera_smoke_step":
				var block: int = RunState.deck.hand.size()
				RunState.combat.player_block += block
				RunTelemetry.record_oath_trigger("sera_smoke_step")
				logs.append("%s oath Smoke Step: gained %d block." % [companion.get("name", "Sera"), block])
			"eldric_oathwall":
				RunState.combat.enemy_attack_reduction += 2
				RunTelemetry.record_oath_trigger("eldric_oathwall")
				logs.append("%s oath Oathwall: first enemy attack reduced by 2." % companion.get("name", "Eldric"))
			"tor_low_stance":
				if RunState.current_hp * 100 <= RunState.max_hp * 50:
					RunState.combat.player_block += 6
					RunTelemetry.record_oath_trigger("tor_low_stance")
					logs.append("%s oath Low Stance: gained 6 block." % companion.get("name", "Tor"))
			"noa_first_read":
				var drawn := RunState.deck.draw_cards(1)
				RunTelemetry.record_oath_trigger("noa_first_read")
				logs.append("%s oath First Read: drew %d card." % [companion.get("name", "Noa"), drawn.size()])
			"isol_lantern":
				if RunState.current_hp * 100 <= RunState.max_hp * 50:
					var healed := _heal(2)
					RunTelemetry.record_oath_trigger("isol_lantern")
					logs.append("%s oath Lantern: healed %d HP." % [companion.get("name", "Isol"), healed])
	return logs


func on_card_play(card: Dictionary, target_index: int) -> Array[String]:
	var logs: Array[String] = []
	for companion in RunState.party.companions:
		var oath_id := String(companion.get("oath_id", ""))
		var best_target := _best_target_index(target_index)
		match oath_id:
			"sera_second_cut":
				if RunState.combat.cards_played_this_turn == 2:
					RunTelemetry.record_oath_trigger("sera_second_cut")
					logs.append(_deal_oath_damage(companion, best_target, 3, "Second Cut"))
			"sera_quick_claim":
				if int(card.get("cost", 0)) == 0 and _consume_flag("sera_quick_claim_used"):
					_add_mark(best_target, 1)
					RunTelemetry.record_oath_trigger("sera_quick_claim")
					logs.append("%s oath Quick Claim: applied 1 Tactical Mark." % companion.get("name", "Sera"))
			"eldric_shared_guard":
				if _card_has_effect(card, "block"):
					RunState.combat.player_block += 2
					RunTelemetry.record_oath_trigger("eldric_shared_guard")
					logs.append("%s oath Shared Guard: gained 2 block." % companion.get("name", "Eldric"))
			"eldric_last_stand":
				if _card_has_effect(card, "block") and RunState.current_hp * 100 <= RunState.max_hp * 40:
					RunState.combat.player_block += 2
					RunTelemetry.record_oath_trigger("eldric_last_stand")
					logs.append("%s oath Last Stand: gained 2 block." % companion.get("name", "Eldric"))
			"bram_blood_wager":
				if _card_has_effect(card, "lose_hp"):
					RunTelemetry.record_oath_trigger("bram_blood_wager")
					logs.append(_deal_oath_damage(companion, best_target, 4, "Blood Wager"))
			"bram_hard_bargain":
				if _card_has_effect(card, "lose_hp") and _consume_flag("bram_hard_bargain_used"):
					RunState.combat.energy += 1
					RunTelemetry.record_oath_trigger("bram_hard_bargain")
					logs.append("%s oath Hard Bargain: refunded 1 energy." % companion.get("name", "Bram"))
			"maren_measured_care":
				if _card_has_effect(card, "heal"):
					RunState.combat.player_block += 2
					RunTelemetry.record_oath_trigger("maren_measured_care")
					logs.append("%s oath Measured Care: gained 2 block." % companion.get("name", "Maren"))
			"maren_no_free_debt":
				if _card_has_effect(card, "heal") and _consume_flag("maren_no_free_debt_used"):
					RunState.combat.energy += 1
					RunTelemetry.record_oath_trigger("maren_no_free_debt")
					logs.append("%s oath No Free Debt: refunded 1 energy." % companion.get("name", "Maren"))
			"maren_clean_bandage":
				if _card_has_effect(card, "block") and _consume_flag(_turn_key(oath_id, companion)):
					var healed := _heal(1)
					RunTelemetry.record_oath_trigger("maren_clean_bandage")
					logs.append("%s oath Clean Bandage: healed %d HP." % [companion.get("name", "Maren"), healed])
			"tor_shield_rent":
				if _card_has_effect(card, "block"):
					RunState.combat.player_block += 3
					RunTelemetry.record_oath_trigger("tor_shield_rent")
					logs.append("%s oath Shield Rent: gained 3 block." % companion.get("name", "Tor"))
			"lina_green_pin":
				if _card_has_effect(card, "tactical_mark"):
					_add_mark(best_target, 1)
					RunTelemetry.record_oath_trigger("lina_green_pin")
					logs.append("%s oath Green Pin: applied 1 extra Tactical Mark." % companion.get("name", "Lina"))
			"lina_bitter_dose":
				if String(card.get("type", "")) == "skill" and _consume_flag(_turn_key(oath_id, companion)):
					RunTelemetry.record_oath_trigger("lina_bitter_dose")
					logs.append(_deal_oath_damage(companion, best_target, 2, "Bitter Dose"))
			"lina_last_leaf":
				if _card_has_effect(card, "heal"):
					_add_mark(best_target, 1)
					RunTelemetry.record_oath_trigger("lina_last_leaf")
					logs.append("%s oath Last Leaf: applied 1 Tactical Mark." % companion.get("name", "Lina"))
			"noa_star_count":
				if RunState.combat.cards_played_this_turn == 3 and _consume_flag(_turn_key(oath_id, companion)):
					var drawn := RunState.deck.draw_cards(1)
					RunTelemetry.record_oath_trigger("noa_star_count")
					logs.append("%s oath Star Count: drew %d card." % [companion.get("name", "Noa"), drawn.size()])
			"noa_zero_map":
				if int(card.get("cost", 0)) == 0 and _consume_flag("noa_zero_map_used"):
					RunState.combat.energy += 1
					RunTelemetry.record_oath_trigger("noa_zero_map")
					logs.append("%s oath Zero Map: gained 1 energy." % companion.get("name", "Noa"))
			"isol_white_guard":
				if _card_has_effect(card, "heal") and _consume_flag("isol_white_guard_used"):
					RunState.combat.player_block += 5
					RunTelemetry.record_oath_trigger("isol_white_guard")
					logs.append("%s oath White Guard: gained 5 block." % companion.get("name", "Isol"))
			"isol_mercy_line":
				if _card_has_effect(card, "block") and _consume_flag(_turn_key(oath_id, companion)):
					var healed := _heal(1)
					RunTelemetry.record_oath_trigger("isol_mercy_line")
					logs.append("%s oath Mercy Line: healed %d HP." % [companion.get("name", "Isol"), healed])
	return logs


func on_companion_attack(companion: Dictionary, target_index: int) -> Array[String]:
	var logs: Array[String] = []
	var oath_id := String(companion.get("oath_id", ""))
	match oath_id:
		"rowan_red_pursuit":
			if _target_mark(target_index) > 0:
				RunTelemetry.record_oath_trigger("rowan_red_pursuit")
				logs.append(_deal_oath_damage(companion, target_index, 2, "Red Pursuit"))
		"rowan_first_blood":
			var key: String = "rowan_first_blood_%s" % companion.get("id", "")
			if _target_mark(target_index) > 0 and _consume_flag(key):
				RunTelemetry.record_oath_trigger("rowan_first_blood")
				logs.append(_deal_oath_damage(companion, target_index, 3, "First Blood"))
		"rowan_spear_line":
			_add_mark(target_index, 1)
			RunTelemetry.record_oath_trigger("rowan_spear_line")
			logs.append("%s oath Spear Line: applied 1 Tactical Mark." % companion.get("name", "Rowan"))
		"bram_red_laugh":
			var key := "bram_red_laugh_%s" % companion.get("id", "")
			if _enemy_is_defeated(target_index) and _consume_flag(key):
				var healed := _heal(2)
				RunTelemetry.record_oath_trigger("bram_red_laugh")
				logs.append("%s oath Red Laugh: healed %d HP." % [companion.get("name", "Bram"), healed])
		"tor_mark_break":
			if _target_mark(target_index) > 0:
				RunTelemetry.record_oath_trigger("tor_mark_break")
				logs.append(_deal_oath_damage(companion, target_index, 2, "Mark Break"))
	return logs


func _deal_oath_damage(companion: Dictionary, target_index: int, amount: int, oath_name: String) -> String:
	if target_index < 0 or target_index >= RunState.combat.enemies.size():
		return "%s oath %s found no target." % [companion.get("name", "Companion"), oath_name]
	var enemy: Dictionary = RunState.combat.enemies[target_index]
	if int(enemy.get("hp", 0)) <= 0:
		return "%s oath %s found no living target." % [companion.get("name", "Companion"), oath_name]
	enemy["hp"] = max(int(enemy.get("hp", 0)) - amount, 0)
	RunState.combat.enemies[target_index] = enemy
	return "%s oath %s dealt %d damage." % [companion.get("name", "Companion"), oath_name, amount]


func _card_has_effect(card: Dictionary, effect_type: String) -> bool:
	for effect in card.get("effects", []):
		if typeof(effect) == TYPE_DICTIONARY and String(effect.get("type", "")) == effect_type:
			return true
	return false


func _target_mark(target_index: int) -> int:
	if target_index < 0 or target_index >= RunState.combat.enemies.size():
		return 0
	var enemy: Dictionary = RunState.combat.enemies[target_index]
	var statuses: Dictionary = enemy.get("statuses", {})
	return int(statuses.get("tactical_mark", 0))


func _add_mark(target_index: int, amount: int) -> void:
	if target_index < 0 or target_index >= RunState.combat.enemies.size():
		return
	var enemy: Dictionary = RunState.combat.enemies[target_index]
	if int(enemy.get("hp", 0)) <= 0:
		return
	var statuses: Dictionary = enemy.get("statuses", {})
	statuses["tactical_mark"] = int(statuses.get("tactical_mark", 0)) + amount
	enemy["statuses"] = statuses
	RunState.combat.enemies[target_index] = enemy


func _best_target_index(preferred_index: int) -> int:
	if _is_live_enemy(preferred_index):
		return preferred_index
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


func _is_live_enemy(enemy_index: int) -> bool:
	if enemy_index < 0 or enemy_index >= RunState.combat.enemies.size():
		return false
	var enemy: Dictionary = RunState.combat.enemies[enemy_index]
	return int(enemy.get("hp", 0)) > 0


func _enemy_is_defeated(enemy_index: int) -> bool:
	if enemy_index < 0 or enemy_index >= RunState.combat.enemies.size():
		return false
	var enemy: Dictionary = RunState.combat.enemies[enemy_index]
	return int(enemy.get("hp", 0)) <= 0


func _consume_flag(key: String) -> bool:
	if bool(RunState.combat.oath_flags.get(key, false)):
		return false
	RunState.combat.oath_flags[key] = true
	return true


func _turn_key(oath_id: String, companion: Dictionary) -> String:
	return "%s_%s_turn_%d" % [oath_id, companion.get("id", ""), RunState.combat.turn_index]


func _heal(amount: int) -> int:
	var before := RunState.current_hp
	RunState.current_hp = min(RunState.current_hp + amount, RunState.max_hp)
	return RunState.current_hp - before
