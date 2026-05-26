class_name PartyState
extends RefCounted

var protagonist_id := "protagonist_mercenary"
var companions: Array[Dictionary] = []


func reset() -> void:
	companions.clear()


func get_companion_count() -> int:
	return companions.size()


func can_recruit(max_companions: int) -> bool:
	return companions.size() < max_companions


func to_dict() -> Dictionary:
	return {
		"protagonist_id": protagonist_id,
		"companions": companions.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	protagonist_id = String(data.get("protagonist_id", protagonist_id))
	companions = []
	for companion in data.get("companions", []):
		if typeof(companion) == TYPE_DICTIONARY:
			companions.append(companion)
