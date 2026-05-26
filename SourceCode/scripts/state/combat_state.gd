class_name CombatState
extends RefCounted

var in_combat := false
var turn_index := 0
var player_block := 0
var energy := 0
var max_energy := 0
var tactical_mark_bonus := 0
var outcome := "inactive"
var cards_played_this_turn := 0
var enemy_attack_reduction := 0
var healing_reduction_percent := 0
var healing_reduction_turns := 0
var oath_flags: Dictionary = {}
var enemies: Array[Dictionary] = []


func reset() -> void:
	in_combat = false
	turn_index = 0
	player_block = 0
	energy = 0
	max_energy = 0
	tactical_mark_bonus = 0
	outcome = "inactive"
	cards_played_this_turn = 0
	enemy_attack_reduction = 0
	healing_reduction_percent = 0
	healing_reduction_turns = 0
	oath_flags.clear()
	enemies.clear()


func to_dict() -> Dictionary:
	return {
		"in_combat": in_combat,
		"turn_index": turn_index,
		"player_block": player_block,
		"energy": energy,
		"max_energy": max_energy,
		"tactical_mark_bonus": tactical_mark_bonus,
		"outcome": outcome,
		"cards_played_this_turn": cards_played_this_turn,
		"enemy_attack_reduction": enemy_attack_reduction,
		"healing_reduction_percent": healing_reduction_percent,
		"healing_reduction_turns": healing_reduction_turns,
		"oath_flags": oath_flags.duplicate(true),
		"enemies": enemies.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	in_combat = bool(data.get("in_combat", false))
	turn_index = int(data.get("turn_index", 0))
	player_block = int(data.get("player_block", 0))
	energy = int(data.get("energy", 0))
	max_energy = int(data.get("max_energy", 0))
	tactical_mark_bonus = int(data.get("tactical_mark_bonus", 0))
	outcome = String(data.get("outcome", "inactive"))
	cards_played_this_turn = int(data.get("cards_played_this_turn", 0))
	enemy_attack_reduction = int(data.get("enemy_attack_reduction", 0))
	healing_reduction_percent = int(data.get("healing_reduction_percent", 0))
	healing_reduction_turns = int(data.get("healing_reduction_turns", 0))
	var restored_flags: Variant = data.get("oath_flags", {})
	oath_flags = restored_flags if typeof(restored_flags) == TYPE_DICTIONARY else {}
	enemies = []
	for enemy in data.get("enemies", []):
		if typeof(enemy) == TYPE_DICTIONARY:
			enemies.append(enemy)
