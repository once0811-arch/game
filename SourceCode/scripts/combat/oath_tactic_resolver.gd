class_name OathTacticResolver
extends RefCounted


func on_combat_start() -> Array[String]:
	var logs: Array[String] = []
	for companion in RunState.party.companions:
		match String(companion.get("oath_id", "")):
			"sera_smoke_step":
				var block: int = RunState.deck.hand.size()
				RunState.combat.player_block += block
				logs.append("%s oath Smoke Step: gained %d block." % [companion.get("name", "Sera"), block])
			"eldric_oathwall":
				RunState.combat.enemy_attack_reduction += 2
				logs.append("%s oath Oathwall: first enemy attack reduced by 2." % companion.get("name", "Eldric"))
	return logs


func on_card_play(card: Dictionary, target_index: int) -> Array[String]:
	var logs: Array[String] = []
	for companion in RunState.party.companions:
		var oath_id := String(companion.get("oath_id", ""))
		match oath_id:
			"sera_second_cut":
				if RunState.combat.cards_played_this_turn == 2:
					logs.append(_deal_oath_damage(companion, target_index, 3, "Second Cut"))
			"sera_quick_claim":
				if int(card.get("cost", 0)) == 0 and not bool(RunState.combat.oath_flags.get("sera_quick_claim_used", false)):
					_add_mark(target_index, 1)
					RunState.combat.oath_flags["sera_quick_claim_used"] = true
					logs.append("%s oath Quick Claim: applied 1 Tactical Mark." % companion.get("name", "Sera"))
			"eldric_shared_guard":
				if _card_has_effect(card, "block"):
					RunState.combat.player_block += 2
					logs.append("%s oath Shared Guard: gained 2 block." % companion.get("name", "Eldric"))
			"eldric_last_stand":
				if _card_has_effect(card, "block") and RunState.current_hp * 100 <= RunState.max_hp * 40:
					RunState.combat.player_block += 2
					logs.append("%s oath Last Stand: gained 2 block." % companion.get("name", "Eldric"))
	return logs


func on_companion_attack(companion: Dictionary, target_index: int) -> Array[String]:
	var logs: Array[String] = []
	var oath_id := String(companion.get("oath_id", ""))
	match oath_id:
		"rowan_red_pursuit":
			if _target_mark(target_index) > 0:
				logs.append(_deal_oath_damage(companion, target_index, 2, "Red Pursuit"))
		"rowan_first_blood":
			var key: String = "rowan_first_blood_%s" % companion.get("id", "")
			if _target_mark(target_index) > 0 and not bool(RunState.combat.oath_flags.get(key, false)):
				RunState.combat.oath_flags[key] = true
				logs.append(_deal_oath_damage(companion, target_index, 3, "First Blood"))
		"rowan_spear_line":
			_add_mark(target_index, 1)
			logs.append("%s oath Spear Line: applied 1 Tactical Mark." % companion.get("name", "Rowan"))
	return logs


func _deal_oath_damage(companion: Dictionary, target_index: int, amount: int, oath_name: String) -> String:
	if target_index < 0 or target_index >= RunState.combat.enemies.size():
		return "%s oath %s found no target." % [companion.get("name", "Companion"), oath_name]
	var enemy: Dictionary = RunState.combat.enemies[target_index]
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
	var statuses: Dictionary = enemy.get("statuses", {})
	statuses["tactical_mark"] = int(statuses.get("tactical_mark", 0)) + amount
	enemy["statuses"] = statuses
	RunState.combat.enemies[target_index] = enemy
