class_name CardEffectResolver
extends RefCounted

const CardDataScript := preload("res://scripts/data/card_data.gd")


func resolve(card: Dictionary, target_index: int, card_instance: Dictionary = {}) -> Array[String]:
	var logs: Array[String] = []
	if target_index < 0 or target_index >= RunState.combat.enemies.size():
		return logs

	var target: Dictionary = RunState.combat.enemies[target_index]
	var upgraded := bool(card_instance.get("upgraded", false))
	for effect in card.get("effects", []):
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		match String(effect.get("type", "")):
			"damage":
				var attack_bonus := RunState.equipment.get_total_bonus("attack_damage", "protagonist")
				var upgrade_bonus := 2 if upgraded else 0
				logs.append(_deal_damage(card, target, int(effect.get("amount", 0)) + attack_bonus + upgrade_bonus))
			"block":
				var block := int(effect.get("amount", 0)) + RunState.equipment.get_total_bonus("block_card_bonus", "protagonist")
				if upgraded:
					block += 2
				RunState.combat.player_block += block
				logs.append("Gained %d block." % block)
			"draw":
				var drawn := RunState.deck.draw_cards(int(effect.get("amount", 0)))
				logs.append("Drew %d cards." % drawn.size())
			"tactical_mark":
				var amount: int = int(effect.get("amount", 0)) + RunState.combat.tactical_mark_bonus
				_add_status(target, "tactical_mark", amount)
				logs.append("Applied %d Tactical Mark." % amount)
			"gain_energy":
				var amount: int = int(effect.get("amount", 0))
				RunState.combat.energy += amount
				logs.append("Gained %d energy." % amount)
			"lose_hp":
				var amount: int = int(effect.get("amount", 0))
				RunState.current_hp = max(RunState.current_hp - amount, 0)
				logs.append("Lost %d HP." % amount)
			"heal":
				var amount: int = int(effect.get("amount", 0)) + (1 if upgraded else 0)
				var before: int = RunState.current_hp
				amount = _apply_healing_reduction(amount)
				RunState.current_hp = min(RunState.current_hp + amount, RunState.max_hp)
				logs.append("Healed %d HP." % (RunState.current_hp - before))
			"power_tactical_mark_bonus":
				var amount: int = int(effect.get("amount", 0))
				RunState.combat.tactical_mark_bonus += amount
				logs.append("Tactical Mark effects gain +%d this combat." % amount)
			_:
				logs.append("No effect.")

	if CardDataScript.card_type(card) == "attack" and int(target.get("hp", 0)) > 0:
		_add_status(target, "tactical_mark", 1 + RunState.combat.tactical_mark_bonus)
		logs.append("Attack added Tactical Mark.")

	RunState.combat.enemies[target_index] = target
	return logs


func _deal_damage(card: Dictionary, target: Dictionary, amount: int) -> String:
	var statuses: Dictionary = target.get("statuses", {})
	var mark_bonus: int = int(statuses.get("tactical_mark", 0))
	var total: int = amount + mark_bonus
	var blocked: int = min(int(target.get("block", 0)), total)
	target["block"] = int(target.get("block", 0)) - blocked
	var final_damage: int = max(total - blocked, 0)
	target["hp"] = max(int(target.get("hp", 0)) - final_damage, 0)
	return "%s dealt %d damage." % [CardDataScript.card_name(card), final_damage]


func _apply_healing_reduction(amount: int) -> int:
	if RunState.combat.healing_reduction_turns <= 0 or RunState.combat.healing_reduction_percent <= 0:
		return amount
	var reduced := int(round(amount * (100 - RunState.combat.healing_reduction_percent) / 100.0))
	return max(reduced, 0)


func _add_status(target: Dictionary, status_id: String, amount: int) -> void:
	var statuses: Dictionary = target.get("statuses", {})
	statuses[status_id] = int(statuses.get(status_id, 0)) + amount
	target["statuses"] = statuses
