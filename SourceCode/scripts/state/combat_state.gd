class_name CombatState
extends RefCounted

var in_combat := false
var turn_index := 0
var player_block := 0
var enemies: Array[Dictionary] = []


func reset() -> void:
	in_combat = false
	turn_index = 0
	player_block = 0
	enemies.clear()


func to_dict() -> Dictionary:
	return {
		"in_combat": in_combat,
		"turn_index": turn_index,
		"player_block": player_block,
		"enemies": enemies.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	in_combat = bool(data.get("in_combat", false))
	turn_index = int(data.get("turn_index", 0))
	player_block = int(data.get("player_block", 0))
	enemies = []
	for enemy in data.get("enemies", []):
		if typeof(enemy) == TYPE_DICTIONARY:
			enemies.append(enemy)
