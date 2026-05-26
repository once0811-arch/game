class_name CardPlayRules
extends RefCounted

const CardDataScript := preload("res://scripts/data/card_data.gd")


static func requires_enemy_target(card: Dictionary) -> bool:
	for effect in card.get("effects", []):
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		if String(effect.get("type", "")) in ["damage", "tactical_mark"]:
			return true
	return false


static func validate_play(card: Dictionary, hand_index: int, target_index: int = -1) -> Dictionary:
	if RunState.combat.outcome != "active":
		return _failure("Combat is already over.")
	if hand_index < 0 or hand_index >= RunState.deck.hand.size():
		return _failure("That card is no longer in hand.")
	var cost := CardDataScript.card_cost(card)
	if cost > RunState.combat.energy:
		return _failure("Need %d energy." % cost)
	if requires_enemy_target(card):
		if first_live_enemy_index() < 0:
			return _failure("No living enemy.")
		if not is_live_enemy_index(target_index):
			return _failure("Choose a living enemy.")
	return {"ok": true, "message": ""}


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


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
