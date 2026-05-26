extends Node

const BALANCE_CONSTANTS_PATH := "res://data/balance_constants.json"
const TEMP_ASSET_MANIFEST_PATH := "res://data/assets/temp_asset_manifest.json"
const PROTAGONIST_CARDS_PATH := "res://data/cards/protagonist_cards.json"
const ENEMIES_ACT1_PATH := "res://data/enemies/enemies_act1.json"
const ACT1_ENCOUNTERS_PATH := "res://data/encounters/act1_encounters.json"

var balance_constants: Dictionary = {}
var temp_asset_manifest: Dictionary = {}
var temp_assets_by_id: Dictionary = {}
var protagonist_cards: Dictionary = {}
var cards_by_id: Dictionary = {}
var enemies_act1: Dictionary = {}
var enemies_by_id: Dictionary = {}
var act1_encounters: Dictionary = {}
var load_errors: Array[String] = []


func _ready() -> void:
	load_all()


func load_all() -> bool:
	load_errors.clear()
	balance_constants = _load_dictionary(BALANCE_CONSTANTS_PATH)
	temp_asset_manifest = _load_dictionary(TEMP_ASSET_MANIFEST_PATH)
	protagonist_cards = _load_dictionary(PROTAGONIST_CARDS_PATH)
	enemies_act1 = _load_dictionary(ENEMIES_ACT1_PATH)
	act1_encounters = _load_dictionary(ACT1_ENCOUNTERS_PATH)
	_index_temp_assets()
	_index_cards()
	_index_enemies()
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


func get_starter_deck_ids() -> Array:
	return protagonist_cards.get("starting_deck", [])


func get_card(card_id: String) -> Dictionary:
	return cards_by_id.get(card_id, {})


func get_all_cards() -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	for card in cards_by_id.values():
		if typeof(card) == TYPE_DICTIONARY:
			cards.append(card)
	return cards


func get_card_count() -> int:
	return cards_by_id.size()


func get_enemy(enemy_id: String) -> Dictionary:
	return enemies_by_id.get(enemy_id, {})


func get_enemy_count() -> int:
	return enemies_by_id.size()


func get_act1_encounters() -> Dictionary:
	return act1_encounters


func is_ready_for_phase_1() -> bool:
	return load_errors.is_empty() and not balance_constants.is_empty() and get_temp_asset_count() > 0


func is_ready_for_phase_2() -> bool:
	return is_ready_for_phase_1() and get_starter_deck_ids().size() == 10 and get_card_count() > 0


func is_ready_for_phase_3() -> bool:
	return is_ready_for_phase_2() and get_enemy_count() > 0


func is_ready_for_phase_4() -> bool:
	return is_ready_for_phase_3() and not act1_encounters.is_empty()


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


func _index_cards() -> void:
	cards_by_id.clear()
	for card in protagonist_cards.get("cards", []):
		if typeof(card) != TYPE_DICTIONARY:
			continue
		var card_id := String(card.get("id", ""))
		if not card_id.is_empty():
			cards_by_id[card_id] = card


func _index_enemies() -> void:
	enemies_by_id.clear()
	for enemy in enemies_act1.get("enemies", []):
		if typeof(enemy) != TYPE_DICTIONARY:
			continue
		var enemy_id := String(enemy.get("id", ""))
		if not enemy_id.is_empty():
			enemies_by_id[enemy_id] = enemy
