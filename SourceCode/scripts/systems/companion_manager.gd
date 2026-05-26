extends Node

var pending_source := ""
var selected_companion_id := ""
var selected_oath_id := ""
var selected_card_ids: Array[String] = []


func begin_recruitment(source: String) -> void:
	pending_source = source
	selected_companion_id = ""
	selected_oath_id = ""
	selected_card_ids.clear()


func select_companion(companion_id: String) -> void:
	selected_companion_id = companion_id
	selected_oath_id = ""
	selected_card_ids.clear()


func select_oath(oath_id: String) -> void:
	selected_oath_id = oath_id


func toggle_card(card_id: String) -> void:
	if selected_card_ids.has(card_id):
		selected_card_ids.erase(card_id)
		return
	var max_picks := int(DataRegistry.get_balance("rewards.companion_card_picks", 2))
	if selected_card_ids.size() < max_picks:
		selected_card_ids.append(card_id)


func can_finalize() -> bool:
	return not selected_companion_id.is_empty() and not selected_oath_id.is_empty() and selected_card_ids.size() == int(DataRegistry.get_balance("rewards.companion_card_picks", 2))


func finalize_recruitment() -> bool:
	if not can_finalize():
		return false
	var companion_data := DataRegistry.get_companion(selected_companion_id)
	if companion_data.is_empty():
		return false
	var oath := _get_selected_oath(companion_data)
	var recruited := {
		"id": selected_companion_id,
		"name": String(companion_data.get("name", selected_companion_id)),
		"role": String(companion_data.get("role", "")),
		"portrait_asset_id": String(companion_data.get("portrait_asset_id", "")),
		"sprite_asset_id": String(companion_data.get("sprite_asset_id", "")),
		"oath_id": selected_oath_id,
		"oath_name": String(oath.get("name", selected_oath_id)),
		"oath_rules_text": String(oath.get("rules_text", "")),
		"bond_score": 0,
		"card_ids": selected_card_ids.duplicate(),
	}
	if not RunState.party.add_companion(recruited):
		return false
	for card_id in selected_card_ids:
		RunState.deck.add_card_to_discard(card_id)
	_complete_pending()
	return true


func complete_without_recruitment() -> void:
	_complete_pending()


func _get_selected_oath(companion_data: Dictionary) -> Dictionary:
	for oath in companion_data.get("oath_tactics", []):
		if typeof(oath) == TYPE_DICTIONARY and String(oath.get("id", "")) == selected_oath_id:
			return oath
	return {}


func _complete_pending() -> void:
	if pending_source in ["map_contract", "map_boss"]:
		MapState.complete_selected_node()
	pending_source = ""
	selected_companion_id = ""
	selected_oath_id = ""
	selected_card_ids.clear()
