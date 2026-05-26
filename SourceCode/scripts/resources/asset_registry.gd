class_name AssetRegistry
extends RefCounted

const MANIFEST_PATH := "res://data/assets/asset_manifest.json"
const TEMP_MANIFEST_PATH := "res://data/assets/temp_asset_manifest.json"

var manifest: Dictionary = {}
var assets_by_id: Dictionary = {}
var assets_by_category: Dictionary = {}


func load_temp_manifest(path: String = MANIFEST_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		file = FileAccess.open(TEMP_MANIFEST_PATH, FileAccess.READ)
		if file == null:
			push_error("Asset manifest not found: %s" % path)
			return false

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Asset manifest is not a JSON object: %s" % path)
		return false

	manifest = parsed
	assets_by_id.clear()
	assets_by_category.clear()

	for asset in manifest.get("assets", []):
		if typeof(asset) != TYPE_DICTIONARY:
			continue
		var asset_id := String(asset.get("id", ""))
		var category := String(asset.get("category", "uncategorized"))
		if asset_id.is_empty():
			continue
		assets_by_id[asset_id] = asset
		if not assets_by_category.has(category):
			assets_by_category[category] = []
		assets_by_category[category].append(asset)

	return true


func get_asset(asset_id: String) -> Dictionary:
	return assets_by_id.get(asset_id, {})


func get_categories() -> Array:
	var categories := assets_by_category.keys()
	categories.sort()
	return categories


func get_assets_for_category(category: String) -> Array:
	return assets_by_category.get(category, [])
