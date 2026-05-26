extends Node

const BALANCE_CONSTANTS_PATH := "res://data/balance_constants.json"
const TEMP_ASSET_MANIFEST_PATH := "res://data/assets/temp_asset_manifest.json"

var balance_constants: Dictionary = {}
var temp_asset_manifest: Dictionary = {}
var temp_assets_by_id: Dictionary = {}
var load_errors: Array[String] = []


func _ready() -> void:
	load_all()


func load_all() -> bool:
	load_errors.clear()
	balance_constants = _load_dictionary(BALANCE_CONSTANTS_PATH)
	temp_asset_manifest = _load_dictionary(TEMP_ASSET_MANIFEST_PATH)
	_index_temp_assets()
	return load_errors.is_empty()


func get_balance(path: String, default_value: Variant = null) -> Variant:
	var cursor: Variant = balance_constants
	for key in path.split("."):
		if typeof(cursor) != TYPE_DICTIONARY or not cursor.has(key):
			return default_value
		cursor = cursor[key]
	return cursor


func get_temp_asset(asset_id: String) -> Dictionary:
	return temp_assets_by_id.get(asset_id, {})


func get_temp_asset_path(asset_id: String, default_path: String = "") -> String:
	var asset := get_temp_asset(asset_id)
	return String(asset.get("path", default_path))


func get_temp_asset_count() -> int:
	return temp_assets_by_id.size()


func is_ready_for_phase_1() -> bool:
	return load_errors.is_empty() and not balance_constants.is_empty() and get_temp_asset_count() > 0


func _load_dictionary(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		load_errors.append("Missing JSON: %s" % path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		load_errors.append("Invalid JSON object: %s" % path)
		return {}

	return parsed


func _index_temp_assets() -> void:
	temp_assets_by_id.clear()
	for asset in temp_asset_manifest.get("assets", []):
		if typeof(asset) != TYPE_DICTIONARY:
			continue
		var asset_id := String(asset.get("id", ""))
		if not asset_id.is_empty():
			temp_assets_by_id[asset_id] = asset
