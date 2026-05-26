class_name CardPlayRules
extends RefCounted


static func requires_enemy_target(card: Dictionary) -> bool:
	for effect in card.get("effects", []):
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		if String(effect.get("type", "")) in ["damage", "tactical_mark"]:
			return true
	return false


static func first_live_enemy_index() -> int:
	for i in range(RunState.combat.enemies.size()):
		var enemy: Dictionary = RunState.combat.enemies[i]
		if int(enemy.get("hp", 0)) > 0:
			return i
	return -1


static func is_live_enemy_index(enemy_index: int) -> bool:
	if enemy_index < 0 or enemy_index >= RunState.combat.enemies.size():
		return false
	var enemy: Dictionary = RunState.combat.enemies[enemy_index]
	return int(enemy.get("hp", 0)) > 0
