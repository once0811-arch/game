extends Node

const BALANCE_CONSTANTS_PATH := "res://data/balance_constants.json"
const TEMP_ASSET_MANIFEST_PATH := "res://data/assets/temp_asset_manifest.json"
const PROTAGONIST_CARDS_PATH := "res://data/cards/protagonist_cards.json"
const COMPANION_CARDS_PATH := "res://data/cards/companion_cards.json"
const COMPANIONS_PATH := "res://data/companions/companions.json"
const ENEMIES_ACT1_PATH := "res://data/enemies/enemies_act1.json"
const ACT1_ENCOUNTERS_PATH := "res://data/encounters/act1_encounters.json"
const EQUIPMENT_PATH := "res://data/equipment/equipment.json"
const EVENTS_ACT1_PATH := "res://data/events/events_act1.json"

var balance_constants: Dictionary = {}
var temp_asset_manifest: Dictionary = {}
var temp_assets_by_id: Dictionary = {}
var protagonist_cards: Dictionary = {}
var companion_cards: Dictionary = {}
var cards_by_id: Dictionary = {}
var companions: Dictionary = {}
var companions_by_id: Dictionary = {}
var enemies_act1: Dictionary = {}
var enemies_by_id: Dictionary = {}
var act1_encounters: Dictionary = {}
var equipment: Dictionary = {}
var equipment_by_id: Dictionary = {}
var events_act1: Dictionary = {}
var load_errors: Array[String] = []


func _ready() -> void:
	load_all()


func load_all() -> bool:
	load_errors.clear()
	balance_constants = _load_dictionary(BALANCE_CONSTANTS_PATH)
	temp_asset_manifest = _load_dictionary(TEMP_ASSET_MANIFEST_PATH)
	protagonist_cards = _load_dictionary(PROTAGONIST_CARDS_PATH)
	companion_cards = _load_dictionary(COMPANION_CARDS_PATH)
	companions = _load_dictionary(COMPANIONS_PATH)
	enemies_act1 = _load_dictionary(ENEMIES_ACT1_PATH)
	act1_encounters = _load_dictionary(ACT1_ENCOUNTERS_PATH)
	equipment = _load_dictionary(EQUIPMENT_PATH)
	events_act1 = _load_dictionary(EVENTS_ACT1_PATH)
	_index_temp_assets()
	_index_cards()
	_index_companions()
	_index_enemies()
	_index_equipment()
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


func get_companion(companion_id: String) -> Dictionary:
	return companions_by_id.get(companion_id, {})


func get_all_companions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for companion in companions_by_id.values():
		if typeof(companion) == TYPE_DICTIONARY:
			result.append(companion)
	return result


func get_companion_cards(companion_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for card in companion_cards.get("cards", []):
		if typeof(card) == TYPE_DICTIONARY and String(card.get("owner", "")) == companion_id:
			result.append(card)
	return result


func get_companion_count() -> int:
	return companions_by_id.size()


func get_enemy(enemy_id: String) -> Dictionary:
	return enemies_by_id.get(enemy_id, {})


func get_enemy_count() -> int:
	return enemies_by_id.size()


func get_act1_encounters() -> Dictionary:
	return act1_encounters


func get_equipment(equipment_id: String) -> Dictionary:
	return equipment_by_id.get(equipment_id, {})


func get_all_equipment() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in equipment_by_id.values():
		if typeof(item) == TYPE_DICTIONARY:
			result.append(item)
	return result


func get_equipment_count() -> int:
	return equipment_by_id.size()


func get_act1_events() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event in events_act1.get("events", []):
		if typeof(event) == TYPE_DICTIONARY:
			result.append(event)
	return result


func is_ready_for_phase_1() -> bool:
	return load_errors.is_empty() and not balance_constants.is_empty() and get_temp_asset_count() > 0


func is_ready_for_phase_2() -> bool:
	return is_ready_for_phase_1() and get_starter_deck_ids().size() == 10 and get_card_count() > 0


func is_ready_for_phase_3() -> bool:
	return is_ready_for_phase_2() and get_enemy_count() > 0


func is_ready_for_phase_4() -> bool:
	return is_ready_for_phase_3() and not act1_encounters.is_empty()


func is_ready_for_phase_5() -> bool:
	return is_ready_for_phase_4() and get_companion_count() >= 3


func is_ready_for_phase_6() -> bool:
	return is_ready_for_phase_5()


func is_ready_for_phase_7() -> bool:
	return is_ready_for_phase_6() and get_equipment_count() > 0 and get_act1_events().size() > 0


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
	for card in companion_cards.get("cards", []):
		if typeof(card) != TYPE_DICTIONARY:
			continue
		var card_id := String(card.get("id", ""))
		if not card_id.is_empty():
			cards_by_id[card_id] = card


func _index_companions() -> void:
	companions_by_id.clear()
	for companion in companions.get("companions", []):
		if typeof(companion) != TYPE_DICTIONARY:
			continue
		var companion_id := String(companion.get("id", ""))
		if not companion_id.is_empty():
			companions_by_id[companion_id] = companion


func _index_enemies() -> void:
	enemies_by_id.clear()
	for enemy in enemies_act1.get("enemies", []):
		if typeof(enemy) != TYPE_DICTIONARY:
			continue
		var enemy_id := String(enemy.get("id", ""))
		if not enemy_id.is_empty():
			enemies_by_id[enemy_id] = enemy


func _index_equipment() -> void:
	equipment_by_id.clear()
	for item in equipment.get("equipment", []):
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var item_id := String(item.get("id", ""))
		if not item_id.is_empty():
			equipment_by_id[item_id] = item
