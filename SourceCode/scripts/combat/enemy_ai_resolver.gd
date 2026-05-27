class_name EnemyAIResolver
extends RefCounted


func create_enemy(enemy_data: Dictionary) -> Dictionary:
	var enemy := {
		"id": String(enemy_data.get("id", "")),
		"name": String(enemy_data.get("name", "Enemy")),
		"role": String(enemy_data.get("role", "")),
		"faction": String(enemy_data.get("faction", "")),
		"behavior_tags": enemy_data.get("behavior_tags", []),
		"counterplay_note": String(enemy_data.get("counterplay_note", "")),
		"max_hp": int(enemy_data.get("max_hp", 1)),
		"hp": int(enemy_data.get("max_hp", 1)),
		"block": 0,
		"attack_bonus": 0,
		"asset_id": String(enemy_data.get("asset_id", "")),
		"pattern": enemy_data.get("pattern", []),
		"intents": enemy_data.get("intents", []),
		"intent_index": 0,
		"intent": {},
		"statuses": {},
		"pattern_flags": {},
	}
	_set_next_intent(enemy)
	return enemy


func refresh_current_intents() -> void:
	for i in range(RunState.combat.enemies.size()):
		var enemy: Dictionary = RunState.combat.enemies[i]
		if int(enemy.get("hp", 0)) <= 0:
			continue
		_set_next_intent(enemy)
		RunState.combat.enemies[i] = enemy


func execute_enemy_turn() -> Array[String]:
	var logs: Array[String] = []
	for i in range(RunState.combat.enemies.size()):
		var enemy: Dictionary = RunState.combat.enemies[i]
		if int(enemy.get("hp", 0)) <= 0:
			continue
		var intent: Dictionary = enemy.get("intent", {})
		match String(intent.get("type", "attack")):
			"attack":
				logs.append(_apply_attack(enemy, intent))
			"attack_block":
				logs.append(_apply_attack(enemy, intent))
				var block := int(intent.get("block", 0))
				enemy["block"] = int(enemy.get("block", 0)) + block
				logs.append("%s guarded for %d block." % [enemy.get("name", "Enemy"), block])
			"attack_healing_down":
				logs.append(_apply_attack(enemy, intent))
				_apply_healing_down(intent)
				logs.append("%s soured healing by %d%% for %d turns." % [
					enemy.get("name", "Enemy"),
					RunState.combat.healing_reduction_percent,
					RunState.combat.healing_reduction_turns,
				])
			"attack_energy_down":
				logs.append(_apply_attack(enemy, intent))
				_apply_energy_down(intent)
				logs.append("%s disrupted next turn energy by %d." % [
					enemy.get("name", "Enemy"),
					int(intent.get("amount", 1)),
				])
			"block":
				var block := int(intent.get("block", 0))
				enemy["block"] = int(enemy.get("block", 0)) + block
				logs.append("%s gained %d block." % [enemy.get("name", "Enemy"), block])
			"guard_all":
				var block := int(intent.get("block", 0))
				for ally_index in range(RunState.combat.enemies.size()):
					var ally: Dictionary = RunState.combat.enemies[ally_index]
					if int(ally.get("hp", 0)) <= 0:
						continue
					ally["block"] = int(ally.get("block", 0)) + block
					RunState.combat.enemies[ally_index] = ally
				logs.append("%s guarded all enemies for %d block." % [enemy.get("name", "Enemy"), block])
			"healing_down":
				_apply_healing_down(intent)
				logs.append("%s applied Healing Down %d%% for %d turns." % [
					enemy.get("name", "Enemy"),
					RunState.combat.healing_reduction_percent,
					RunState.combat.healing_reduction_turns,
				])
			"energy_down":
				_apply_energy_down(intent)
				logs.append("%s disrupted next turn energy by %d." % [
					enemy.get("name", "Enemy"),
					int(intent.get("amount", 1)),
				])
			"buff_attack":
				var amount := int(intent.get("amount", 0))
				enemy["attack_bonus"] = int(enemy.get("attack_bonus", 0)) + amount
				logs.append("%s gained +%d attack." % [enemy.get("name", "Enemy"), amount])
			"steal_gold":
				var amount: int = mini(RunState.gold, int(intent.get("gold", 0)))
				RunState.gold = maxi(RunState.gold - amount, 0)
				logs.append("%s stole %d gold." % [enemy.get("name", "Enemy"), amount])
			_:
				logs.append("%s hesitated." % enemy.get("name", "Enemy"))
		_mark_intent_used(enemy, intent)
		enemy["intent_index"] = int(enemy.get("intent_index", 0)) + 1
		_set_next_intent(enemy)
		RunState.combat.enemies[i] = enemy
	return logs


func _apply_attack(enemy: Dictionary, intent: Dictionary) -> String:
	var damage: int = maxi(int(intent.get("damage", 0)) - RunState.combat.enemy_attack_reduction, 0)
	if RunState.combat.enemy_attack_reduction > 0:
		RunState.combat.enemy_attack_reduction = 0
	var blocked: int = mini(RunState.combat.player_block, damage)
	RunState.combat.player_block -= blocked
	var final_damage: int = maxi(damage - blocked, 0)
	RunState.current_hp = maxi(RunState.current_hp - final_damage, 0)
	return "%s used %s for %d damage." % [enemy.get("name", "Enemy"), intent.get("label", "Attack"), final_damage]


func _apply_healing_down(intent: Dictionary) -> void:
	RunState.combat.healing_reduction_percent = int(intent.get("percent", 50))
	RunState.combat.healing_reduction_turns = int(intent.get("turns", 2))
	RunTelemetry.record_healing_down(RunState.combat.healing_reduction_percent, RunState.combat.healing_reduction_turns)


func _apply_energy_down(intent: Dictionary) -> void:
	RunState.combat.energy_reduction_next_turn = maxi(
		RunState.combat.energy_reduction_next_turn,
		int(intent.get("amount", 1))
	)


func _set_next_intent(enemy: Dictionary) -> void:
	var intents: Array = _select_intent_pool(enemy)
	if intents.is_empty():
		enemy["intent"] = {"type": "attack", "damage": 5, "label": "Attack"}
		return
	var selected := _select_pattern_intent(enemy, intents)
	enemy["intent"] = _prepared_intent(enemy, selected)


func _select_intent_pool(enemy: Dictionary) -> Array:
	var pattern: Array = enemy.get("pattern", [])
	if not pattern.is_empty():
		return pattern
	return enemy.get("intents", [])


func _select_pattern_intent(enemy: Dictionary, intents: Array) -> Dictionary:
	var conditional: Array[Dictionary] = []
	var fallback: Array[Dictionary] = []
	for raw_intent in intents:
		if typeof(raw_intent) != TYPE_DICTIONARY:
			continue
		var intent: Dictionary = raw_intent
		if intent.has("condition") or intent.has("conditions"):
			if _matches_condition(enemy, intent.get("condition", intent.get("conditions", {}))):
				conditional.append(intent)
		else:
			fallback.append(intent)
	if not conditional.is_empty():
		return conditional[0]
	var default_pool := fallback if not fallback.is_empty() else intents
	var valid_pool: Array[Dictionary] = []
	for raw_intent in default_pool:
		if typeof(raw_intent) == TYPE_DICTIONARY:
			valid_pool.append(raw_intent)
	if valid_pool.is_empty():
		return {"type": "attack", "damage": 5, "label": "Attack"}
	var index := int(enemy.get("intent_index", 0)) % valid_pool.size()
	return valid_pool[index]


func _matches_condition(enemy: Dictionary, condition: Variant) -> bool:
	if typeof(condition) != TYPE_DICTIONARY:
		return true
	var rules: Dictionary = condition
	var turn := int(enemy.get("intent_index", 0)) + 1
	if rules.has("turn") and turn != int(rules.get("turn", 0)):
		return false
	if rules.has("turn_min") and turn < int(rules.get("turn_min", 0)):
		return false
	if rules.has("turn_mod"):
		var mod: int = maxi(int(rules.get("turn_mod", 1)), 1)
		var expected := int(rules.get("turn_mod_equals", 0))
		if turn % mod != expected:
			return false
	if rules.has("hp_below_percent") and _hp_percent(enemy) >= int(rules.get("hp_below_percent", 0)):
		return false
	if rules.has("hp_above_percent") and _hp_percent(enemy) <= int(rules.get("hp_above_percent", 0)):
		return false
	if rules.has("mark_at_least") and _mark(enemy) < int(rules.get("mark_at_least", 0)):
		return false
	var once_key := String(rules.get("once_key", ""))
	if not once_key.is_empty():
		var flags: Dictionary = enemy.get("pattern_flags", {})
		if bool(flags.get(once_key, false)):
			return false
	return true


func _prepared_intent(enemy: Dictionary, intent: Dictionary) -> Dictionary:
	var prepared := intent.duplicate(true)
	var intent_type := String(prepared.get("type", "attack"))
	if intent_type in ["attack", "attack_block", "attack_healing_down", "attack_energy_down"]:
		var damage := int(prepared.get("damage", 0)) + int(enemy.get("attack_bonus", 0))
		var per_mark := int(prepared.get("per_mark_damage", 0))
		if per_mark > 0:
			var mark_bonus := _mark(enemy) * per_mark
			var cap := int(prepared.get("per_mark_cap", 0))
			if cap > 0:
				mark_bonus = mini(mark_bonus, cap)
			damage += mark_bonus
		prepared["damage"] = maxi(damage, 0)
	return prepared


func _mark_intent_used(enemy: Dictionary, intent: Dictionary) -> void:
	var condition: Variant = intent.get("condition", intent.get("conditions", {}))
	if typeof(condition) != TYPE_DICTIONARY:
		return
	var rules: Dictionary = condition
	var once_key := String(rules.get("once_key", ""))
	if once_key.is_empty():
		return
	var flags: Dictionary = enemy.get("pattern_flags", {})
	flags[once_key] = true
	enemy["pattern_flags"] = flags


func _hp_percent(enemy: Dictionary) -> int:
	var max_hp: int = maxi(int(enemy.get("max_hp", 1)), 1)
	return int(round(float(int(enemy.get("hp", 0))) * 100.0 / float(max_hp)))


func _mark(enemy: Dictionary) -> int:
	var statuses: Dictionary = enemy.get("statuses", {})
	return int(statuses.get("tactical_mark", 0))
