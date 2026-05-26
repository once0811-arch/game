class_name BondSystem
extends RefCounted

const MAX_BOND := 100

var gains_by_node_type := {
	"combat": 8,
	"elite": 12,
	"midboss": 12,
	"boss": 20,
	"combat_fallback": 6,
}


func award_for_victory(node_type: String) -> Array[String]:
	var logs: Array[String] = []
	if RunState.party.companions.is_empty():
		return logs
	var gain := int(gains_by_node_type.get(node_type, gains_by_node_type["combat"]))
	for i in range(RunState.party.companions.size()):
		var companion: Dictionary = RunState.party.companions[i]
		var before := int(companion.get("bond_score", 0))
		var after = min(before + gain, MAX_BOND)
		companion["bond_score"] = after
		RunState.party.companions[i] = companion
		logs.append("%s bond +%d (%d/%d)." % [companion.get("name", "Companion"), after - before, after, MAX_BOND])
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
	var active: Array[String] = []
	if score >= 30:
		active.append("+damage")
	if score >= 60:
		active.append("+start block")
	if score >= 100:
		active.append("+mark")
	if active.is_empty():
		return "bond %d/100" % score
	return "bond %d/100 (%s)" % [score, ", ".join(PackedStringArray(active))]
