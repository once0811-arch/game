class_name EnemyAIResolver
extends RefCounted


func create_enemy(enemy_data: Dictionary) -> Dictionary:
	var enemy := {
		"id": String(enemy_data.get("id", "")),
		"name": String(enemy_data.get("name", "Enemy")),
		"max_hp": int(enemy_data.get("max_hp", 1)),
		"hp": int(enemy_data.get("max_hp", 1)),
		"block": 0,
		"asset_id": String(enemy_data.get("asset_id", "")),
		"intents": enemy_data.get("intents", []),
		"intent_index": 0,
		"intent": {},
		"statuses": {},
	}
	_set_next_intent(enemy)
	return enemy


func execute_enemy_turn() -> Array[String]:
	var logs: Array[String] = []
	for i in range(RunState.combat.enemies.size()):
		var enemy: Dictionary = RunState.combat.enemies[i]
		if int(enemy.get("hp", 0)) <= 0:
			continue
		var intent: Dictionary = enemy.get("intent", {})
		match String(intent.get("type", "attack")):
			"attack":
				var damage := int(intent.get("damage", 0))
				var blocked = min(RunState.combat.player_block, damage)
				RunState.combat.player_block -= blocked
				var final_damage = max(damage - blocked, 0)
				RunState.current_hp = max(RunState.current_hp - final_damage, 0)
				logs.append("%s used %s for %d damage." % [enemy.get("name", "Enemy"), intent.get("label", "Attack"), final_damage])
			"block":
				var block := int(intent.get("block", 0))
				enemy["block"] = int(enemy.get("block", 0)) + block
				logs.append("%s gained %d block." % [enemy.get("name", "Enemy"), block])
			_:
				logs.append("%s hesitated." % enemy.get("name", "Enemy"))
		enemy["intent_index"] = int(enemy.get("intent_index", 0)) + 1
		_set_next_intent(enemy)
		RunState.combat.enemies[i] = enemy
	return logs


func _set_next_intent(enemy: Dictionary) -> void:
	var intents: Array = enemy.get("intents", [])
	if intents.is_empty():
		enemy["intent"] = {"type": "attack", "damage": 5, "label": "Attack"}
		return
	var index := int(enemy.get("intent_index", 0)) % intents.size()
	enemy["intent"] = intents[index]
