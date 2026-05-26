extends Node

const SAVE_PATH := "user://run_save.json"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func write_run_snapshot(snapshot: Dictionary) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file for write: %s" % SAVE_PATH)
		return false
	file.store_string(JSON.stringify(snapshot, "\t"))
	return true


func read_run_snapshot() -> Dictionary:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed
