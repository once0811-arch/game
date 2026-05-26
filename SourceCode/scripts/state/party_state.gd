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


func has_companion(companion_id: String) -> bool:
	for companion in companions:
		if String(companion.get("id", "")) == companion_id:
			return true
	return false


func add_companion(companion: Dictionary) -> bool:
	if has_companion(String(companion.get("id", ""))):
		return false
	companions.append(companion.duplicate(true))
	return true


func get_companion_summary() -> String:
	if companions.is_empty():
		return "Companions: none"
	var names: Array[String] = []
	for companion in companions:
		names.append("%s / %s" % [String(companion.get("name", "?")), String(companion.get("oath_name", "No Oath"))])
	return "Companions: " + " | ".join(PackedStringArray(names))


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
