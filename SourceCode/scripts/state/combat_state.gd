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
var energy_reduction_next_turn := 0
var oath_flags: Dictionary = {}
var enemies: Array[Dictionary] = []
var enemy_waves: Array = []
var wave_index := 0
var wave_count := 1
var wave_hp_lost: Array[int] = []
var wave_turns: Array[int] = []
var wave_start_hp := 0
var wave_start_turn := 1


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
	energy_reduction_next_turn = 0
	oath_flags.clear()
	enemies.clear()
	enemy_waves.clear()
	wave_index = 0
	wave_count = 1
	wave_hp_lost.clear()
	wave_turns.clear()
	wave_start_hp = 0
	wave_start_turn = 1


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
		"energy_reduction_next_turn": energy_reduction_next_turn,
		"oath_flags": oath_flags.duplicate(true),
		"enemies": enemies.duplicate(true),
		"enemy_waves": enemy_waves.duplicate(true),
		"wave_index": wave_index,
		"wave_count": wave_count,
		"wave_hp_lost": wave_hp_lost.duplicate(),
		"wave_turns": wave_turns.duplicate(),
		"wave_start_hp": wave_start_hp,
		"wave_start_turn": wave_start_turn,
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
	energy_reduction_next_turn = int(data.get("energy_reduction_next_turn", 0))
	var restored_flags: Variant = data.get("oath_flags", {})
	oath_flags = restored_flags if typeof(restored_flags) == TYPE_DICTIONARY else {}
	enemies = []
	for enemy in data.get("enemies", []):
		if typeof(enemy) == TYPE_DICTIONARY:
			enemies.append(enemy)
	enemy_waves = []
	for wave in data.get("enemy_waves", []):
		if typeof(wave) == TYPE_ARRAY:
			var ids: Array[String] = []
			for enemy_id in wave:
				var id_text := String(enemy_id)
				if not id_text.is_empty():
					ids.append(id_text)
			if not ids.is_empty():
				enemy_waves.append(ids)
	wave_index = int(data.get("wave_index", 0))
	wave_count = maxi(1, int(data.get("wave_count", maxi(enemy_waves.size(), 1))))
	wave_hp_lost.clear()
	for value in data.get("wave_hp_lost", []):
		wave_hp_lost.append(int(value))
	wave_turns.clear()
	for value in data.get("wave_turns", []):
		wave_turns.append(int(value))
	wave_start_hp = int(data.get("wave_start_hp", 0))
	wave_start_turn = int(data.get("wave_start_turn", 1))
