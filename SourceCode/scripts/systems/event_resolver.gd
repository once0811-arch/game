class_name EventResolver
extends RefCounted

const CardDataScript := preload("res://scripts/data/card_data.gd")


func apply_effects(effects: Array) -> Array[String]:
	var logs: Array[String] = []
	for effect in effects:
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		var chance := int(effect.get("chance", 100))
		if chance < 100 and RngService.roll_int(1, 100) > chance:
			continue
		match String(effect.get("type", "")):
			"gain_gold":
				var gold_gain: int = int(effect.get("amount", 0))
				RunState.gold += gold_gain
				logs.append("Gained %d gold." % gold_gain)
			"lose_gold":
				var gold_loss: int = min(int(effect.get("amount", 0)), RunState.gold)
				RunState.gold -= gold_loss
				logs.append("Paid %d gold." % gold_loss)
			"lose_hp":
				var hp_loss: int = min(int(effect.get("amount", 0)), max(RunState.current_hp - 1, 0))
				RunState.current_hp = max(RunState.current_hp - hp_loss, 1)
				logs.append("Lost %d HP." % hp_loss)
			"heal_amount":
				_heal_amount(logs, int(effect.get("amount", 0)))
			"heal_percent":
				var heal_percent_amount: int = int(round(RunState.max_hp * int(effect.get("percent", 0)) / 100.0))
				_heal_amount(logs, heal_percent_amount)
			"gain_equipment":
				logs.append(_gain_random_equipment(effect))
			"upgrade_card":
				logs.append(_upgrade_card())
			"remove_card":
				logs.append(_remove_card())
			"transform_card":
				logs.append(_transform_card())
			"copy_card":
				logs.append(_copy_card())
			"bond_gain":
				logs.append_array(_gain_bond(int(effect.get("amount", 0))))
			"healing_down":
				RunState.combat.healing_reduction_percent = int(effect.get("percent", 50))
				RunState.combat.healing_reduction_turns = int(effect.get("turns", 2))
				logs.append("Healing Down prepared: %d%% for %d turns." % [
					RunState.combat.healing_reduction_percent,
					RunState.combat.healing_reduction_turns,
				])
			_:
				logs.append("No effect.")
	return logs


func can_pay_effects(effects: Array) -> bool:
	for effect in effects:
		if typeof(effect) == TYPE_DICTIONARY and String(effect.get("type", "")) == "lose_gold":
			if RunState.gold < int(effect.get("amount", 0)):
				return false
	return true


func _heal_amount(logs: Array[String], amount: int) -> void:
	var before := RunState.current_hp
	RunState.current_hp = min(RunState.current_hp + amount, RunState.max_hp)
	logs.append("Healed %d HP." % (RunState.current_hp - before))


func _gain_random_equipment(effect: Dictionary) -> String:
	var pool := _equipment_pool(effect.get("rarities", []))
	if pool.is_empty():
		return "No equipment found."
	var item: Dictionary = RngService.pick(pool, {})
	var instance := RunState.equipment.add_equipment(String(item.get("id", "")))
	if instance.is_empty():
		return "Could not gain equipment."
	return "Gained equipment: %s." % item.get("name", "Equipment")


func _equipment_pool(rarities: Variant) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for item in DataRegistry.get_all_equipment():
		if typeof(rarities) == TYPE_ARRAY and not rarities.is_empty() and not rarities.has(String(item.get("rarity", ""))):
			continue
		pool.append(item)
	return pool


func _upgrade_card() -> String:
	var card_id := RunState.deck.upgrade_first_unupgraded()
	if card_id.is_empty():
		return "No card to upgrade."
	return "Upgraded %s." % CardDataScript.card_name(DataRegistry.get_card(card_id))


func _remove_card() -> String:
	var card_id := RunState.deck.remove_first_matching(DataRegistry.get_starter_deck_ids())
	if card_id.is_empty():
		return "No starter card to remove."
	return "Removed %s." % CardDataScript.card_name(DataRegistry.get_card(card_id))


func _transform_card() -> String:
	var replacement := _random_reward_card_id()
	var removed := RunState.deck.transform_first_starter(replacement)
	if removed.is_empty():
		return "No starter card to transform."
	return "Transformed %s into %s." % [
		CardDataScript.card_name(DataRegistry.get_card(removed)),
		CardDataScript.card_name(DataRegistry.get_card(replacement)),
	]


func _copy_card() -> String:
	var copied := RunState.deck.copy_first_non_starter()
	if copied.is_empty():
		return "No card to copy."
	return "Copied %s." % CardDataScript.card_name(DataRegistry.get_card(copied))


func _random_reward_card_id() -> String:
	var pool: Array[Dictionary] = []
	for card in DataRegistry.get_all_cards():
		if CardDataScript.is_reward_eligible(card):
			pool.append(card)
	if pool.is_empty():
		return ""
	var card: Dictionary = RngService.pick(pool, {})
	return String(card.get("id", ""))


func _gain_bond(amount: int) -> Array[String]:
	var logs: Array[String] = []
	if RunState.party.companions.is_empty():
		logs.append("No companion bond to raise.")
		return logs
	for i in range(RunState.party.companions.size()):
		var companion: Dictionary = RunState.party.companions[i]
		var before := int(companion.get("bond_score", 0))
		var after = min(before + amount, 100)
		companion["bond_score"] = after
		RunState.party.companions[i] = companion
		logs.append("%s bond +%d (%d/100)." % [companion.get("name", "Companion"), after - before, after])
	return logs
