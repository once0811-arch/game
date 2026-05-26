class_name BondSystem
extends RefCounted

const MAX_BOND := 100

var gains_by_node_type := {
	"combat": 4,
	"elite": 7,
	"midboss": 8,
	"boss": 12,
	"combat_fallback": 3,
}


func award_for_victory(node_type: String) -> Array[String]:
	var logs: Array[String] = []
	if RunState.party.companions.is_empty():
		return logs
	var default_gain := int(gains_by_node_type.get(node_type, gains_by_node_type["combat"]))
	var gain := int(DataRegistry.get_balance("bond.gain_by_node_type.%s" % node_type, default_gain))
	for i in range(RunState.party.companions.size()):
		var companion: Dictionary = RunState.party.companions[i]
		var before := int(companion.get("bond_score", 0))
		var after = min(before + gain, MAX_BOND)
		companion["bond_score"] = after
		RunState.party.companions[i] = companion
		logs.append("%s bond +%d (%d/%d)." % [companion.get("name", "Companion"), after - before, after, MAX_BOND])
		logs.append_array(_award_kyle_wager(i))
	return logs


func get_damage_bonus(companion: Dictionary) -> int:
	var score := int(companion.get("bond_score", 0))
	if score >= 100:
		return 2
	if score >= 30:
		return 1
	return 0


func get_start_block_bonus(companion: Dictionary) -> int:
	return 2 if int(companion.get("bond_score", 0)) >= 60 else 0


func get_mark_bonus(companion: Dictionary) -> int:
	return 1 if int(companion.get("bond_score", 0)) >= 100 else 0


func describe_bonuses(companion: Dictionary) -> String:
	var score := int(companion.get("bond_score", 0))
	var active := get_active_bonus_lines(companion)
	if active.is_empty():
		return "bond %d/100" % score
	return "bond %d/100 (%s)" % [score, ", ".join(PackedStringArray(active))]


func get_active_bonus_lines(companion: Dictionary) -> Array[String]:
	var score := int(companion.get("bond_score", 0))
	var active: Array[String] = []
	if int(companion.get("attack_bonus", 0)) > 0:
		active.append("training +%d attack" % int(companion.get("attack_bonus", 0)))
	if score >= 30:
		active.append("bond 30: +1 companion attack")
	if score >= 60:
		active.append("bond 60: +2 start block")
	if score >= 100:
		active.append("bond 100: +1 Tactical Mark")
	return active


func get_next_threshold_text(companion: Dictionary) -> String:
	var score := int(companion.get("bond_score", 0))
	if score < 30:
		return "%d to bond 30" % (30 - score)
	if score < 60:
		return "%d to bond 60" % (60 - score)
	if score < 100:
		return "%d to bond 100" % (100 - score)
	return "max bond"


func _award_kyle_wager(companion_index: int) -> Array[String]:
	var logs: Array[String] = []
	var companion: Dictionary = RunState.party.companions[companion_index]
	if String(companion.get("id", "")) != "kyle":
		return logs
	var oath_id := String(companion.get("oath_id", ""))
	if not oath_id.begins_with("kyle_"):
		return logs
	var steps := 1
	if oath_id == "kyle_clean_exit" and RunState.current_hp * 100 >= RunState.max_hp * 70:
		steps = 2
	var progress := int(companion.get("wager_wins", 0)) + steps
	logs.append("Kyle wager +%d (%d/5)." % [steps, min(progress, 5)])
	while progress >= 5:
		progress -= 5
		logs.append(_pay_kyle_wager(oath_id))
	companion["wager_wins"] = progress
	RunState.party.companions[companion_index] = companion
	return logs


func _pay_kyle_wager(oath_id: String) -> String:
	var roll := RngService.roll_int(1, 100)
	if oath_id == "kyle_loaded_coin":
		if roll <= 55:
			RunState.gold += 8
			return "Kyle wager paid small: gained 8 gold."
		if roll <= 80:
			var healed := _heal(4)
			return "Kyle wager paid medicine: healed %d HP." % healed
		if roll <= 97:
			RunState.gold += 35
			return "Kyle wager paid well: gained 35 gold."
		RunState.gold += 130
		return "Kyle wager jackpot: gained 130 gold."
	if roll <= 45:
		RunState.gold += 18
		return "Kyle wager paid coin: gained 18 gold."
	if roll <= 70:
		var healed := _heal(5)
		return "Kyle wager paid supplies: healed %d HP." % healed
	if roll <= 92:
		var card_id := RunState.deck.upgrade_first_unupgraded()
		if card_id.is_empty():
			RunState.gold += 20
			return "Kyle wager found no upgrade target: gained 20 gold."
		return "Kyle wager paid craftwork: upgraded a card."
	RunState.gold += 70
	return "Kyle wager jackpot: gained 70 gold."


func _heal(amount: int) -> int:
	var before := RunState.current_hp
	RunState.current_hp = min(RunState.current_hp + amount, RunState.max_hp)
	return RunState.current_hp - before
