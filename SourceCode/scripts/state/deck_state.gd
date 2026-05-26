class_name DeckState
extends RefCounted

const CardInstanceScript := preload("res://scripts/state/card_instance.gd")

var draw_pile: Array[Dictionary] = []
var hand: Array[Dictionary] = []
var discard_pile: Array[Dictionary] = []
var exhaust_pile: Array[Dictionary] = []
var next_instance_id := 1


func reset() -> void:
	draw_pile.clear()
	hand.clear()
	discard_pile.clear()
	exhaust_pile.clear()
	next_instance_id = 1


func build_starting_deck(starter_card_ids: Array) -> void:
	reset()
	for card_id in starter_card_ids:
		draw_pile.append(_create_instance(String(card_id)))
	shuffle_draw_pile()


func draw_cards(count: int) -> Array[Dictionary]:
	var drawn: Array[Dictionary] = []
	for _i in range(count):
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				break
			shuffle_discard_into_draw_pile()
		if draw_pile.is_empty():
			break
		var card: Dictionary = draw_pile.pop_back()
		hand.append(card)
		drawn.append(card)
	return drawn


func play_card(hand_index: int) -> Dictionary:
	if hand_index < 0 or hand_index >= hand.size():
		return {}
	var card: Dictionary = hand.pop_at(hand_index)
	discard_pile.append(card)
	return card


func discard_hand() -> int:
	var discarded := hand.size()
	while not hand.is_empty():
		discard_pile.append(hand.pop_back())
	return discarded


func add_card_to_discard(card_id: String) -> Dictionary:
	var card := _create_instance(card_id)
	discard_pile.append(card)
	return card


func remove_first_matching(card_ids: Array = []) -> String:
	var removed := _remove_from_pile(draw_pile, card_ids)
	if not removed.is_empty():
		return removed
	removed = _remove_from_pile(discard_pile, card_ids)
	if not removed.is_empty():
		return removed
	removed = _remove_from_pile(hand, card_ids)
	if not removed.is_empty():
		return removed
	return _remove_from_pile(exhaust_pile, card_ids)


func upgrade_first_unupgraded() -> String:
	var upgraded := _upgrade_in_pile(draw_pile)
	if not upgraded.is_empty():
		return upgraded
	upgraded = _upgrade_in_pile(discard_pile)
	if not upgraded.is_empty():
		return upgraded
	upgraded = _upgrade_in_pile(hand)
	if not upgraded.is_empty():
		return upgraded
	return _upgrade_in_pile(exhaust_pile)


func transform_first_starter(replacement_id: String) -> String:
	if replacement_id.is_empty():
		return ""
	var starter_ids := DataRegistry.get_starter_deck_ids()
	var transformed := _transform_in_pile(draw_pile, starter_ids, replacement_id)
	if not transformed.is_empty():
		return transformed
	transformed = _transform_in_pile(discard_pile, starter_ids, replacement_id)
	if not transformed.is_empty():
		return transformed
	transformed = _transform_in_pile(hand, starter_ids, replacement_id)
	if not transformed.is_empty():
		return transformed
	return _transform_in_pile(exhaust_pile, starter_ids, replacement_id)


func copy_first_non_starter() -> String:
	var starter_ids := DataRegistry.get_starter_deck_ids()
	var card_id := _find_first_not_in(draw_pile, starter_ids)
	if card_id.is_empty():
		card_id = _find_first_not_in(discard_pile, starter_ids)
	if card_id.is_empty():
		card_id = _find_first_not_in(hand, starter_ids)
	if card_id.is_empty():
		card_id = _find_first_not_in(exhaust_pile, starter_ids)
	if card_id.is_empty():
		card_id = String(starter_ids[0]) if starter_ids.size() > 0 else ""
	if not card_id.is_empty():
		add_card_to_discard(card_id)
	return card_id


func shuffle_discard_into_draw_pile() -> void:
	while not discard_pile.is_empty():
		draw_pile.append(discard_pile.pop_back())
	shuffle_draw_pile()


func shuffle_draw_pile() -> void:
	_shuffle_array(draw_pile)


func get_total_cards() -> int:
	return draw_pile.size() + hand.size() + discard_pile.size() + exhaust_pile.size()


func get_card_entries(include_exhaust: bool = false) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	_append_card_entries(entries, "draw", draw_pile)
	_append_card_entries(entries, "hand", hand)
	_append_card_entries(entries, "discard", discard_pile)
	if include_exhaust:
		_append_card_entries(entries, "exhaust", exhaust_pile)
	return entries


func remove_instance(instance_id: int) -> String:
	var location := _find_instance_location(instance_id)
	if location.is_empty():
		return ""
	var pile: Array[Dictionary] = location["pile"]
	var index := int(location["index"])
	var instance: Dictionary = pile[index]
	pile.remove_at(index)
	return CardInstanceScript.get_card_id(instance)


func upgrade_instance(instance_id: int) -> String:
	var location := _find_instance_location(instance_id)
	if location.is_empty():
		return ""
	var pile: Array[Dictionary] = location["pile"]
	var index := int(location["index"])
	var instance: Dictionary = pile[index]
	if bool(instance.get("upgraded", false)):
		return ""
	instance["upgraded"] = true
	pile[index] = instance
	return CardInstanceScript.get_card_id(instance)


func transform_instance(instance_id: int, replacement_id: String) -> String:
	if replacement_id.is_empty():
		return ""
	var location := _find_instance_location(instance_id)
	if location.is_empty():
		return ""
	var pile: Array[Dictionary] = location["pile"]
	var index := int(location["index"])
	var instance: Dictionary = pile[index]
	var removed_id := CardInstanceScript.get_card_id(instance)
	instance["card_id"] = replacement_id
	instance["upgraded"] = false
	pile[index] = instance
	return removed_id


func copy_instance_to_discard(instance_id: int) -> String:
	var location := _find_instance_location(instance_id)
	if location.is_empty():
		return ""
	var pile: Array[Dictionary] = location["pile"]
	var source: Dictionary = pile[int(location["index"])]
	var copy := _create_instance(CardInstanceScript.get_card_id(source))
	copy["upgraded"] = bool(source.get("upgraded", false))
	discard_pile.append(copy)
	return CardInstanceScript.get_card_id(source)


func has_card_id(card_id: String) -> bool:
	return _pile_has_card(draw_pile, card_id) or _pile_has_card(hand, card_id) or _pile_has_card(discard_pile, card_id) or _pile_has_card(exhaust_pile, card_id)


func to_dict() -> Dictionary:
	return {
		"draw_pile": draw_pile.duplicate(true),
		"hand": hand.duplicate(true),
		"discard_pile": discard_pile.duplicate(true),
		"exhaust_pile": exhaust_pile.duplicate(true),
		"next_instance_id": next_instance_id,
	}


func from_dict(data: Dictionary) -> void:
	draw_pile = _dictionary_array(data.get("draw_pile", []))
	hand = _dictionary_array(data.get("hand", []))
	discard_pile = _dictionary_array(data.get("discard_pile", []))
	exhaust_pile = _dictionary_array(data.get("exhaust_pile", []))
	next_instance_id = int(data.get("next_instance_id", get_total_cards() + 1))


func _dictionary_array(values: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(values) != TYPE_ARRAY:
		return result
	for value in values:
		if typeof(value) == TYPE_DICTIONARY:
			result.append(value)
	return result


func _create_instance(card_id: String) -> Dictionary:
	var instance := CardInstanceScript.create(next_instance_id, card_id)
	next_instance_id += 1
	return instance


func _shuffle_array(values: Array[Dictionary]) -> void:
	if values.size() <= 1:
		return
	for i in range(values.size() - 1, 0, -1):
		var j := RngService.roll_int(0, i)
		var temp := values[i]
		values[i] = values[j]
		values[j] = temp


func _append_card_entries(entries: Array[Dictionary], pile_name: String, pile: Array[Dictionary]) -> void:
	for i in range(pile.size()):
		var instance: Dictionary = pile[i]
		entries.append({
			"pile": pile_name,
			"index": i,
			"instance_id": CardInstanceScript.get_card_instance_id(instance),
			"card_id": CardInstanceScript.get_card_id(instance),
			"upgraded": bool(instance.get("upgraded", false)),
		})


func _find_instance_location(instance_id: int) -> Dictionary:
	var location := _find_instance_in_pile(draw_pile, instance_id)
	if not location.is_empty():
		return location
	location = _find_instance_in_pile(hand, instance_id)
	if not location.is_empty():
		return location
	location = _find_instance_in_pile(discard_pile, instance_id)
	if not location.is_empty():
		return location
	return _find_instance_in_pile(exhaust_pile, instance_id)


func _find_instance_in_pile(pile: Array[Dictionary], instance_id: int) -> Dictionary:
	for i in range(pile.size()):
		if CardInstanceScript.get_card_instance_id(pile[i]) == instance_id:
			return {"pile": pile, "index": i}
	return {}


func _remove_from_pile(pile: Array[Dictionary], card_ids: Array) -> String:
	for i in range(pile.size()):
		var card_id := CardInstanceScript.get_card_id(pile[i])
		if card_ids.is_empty() or card_ids.has(card_id):
			pile.remove_at(i)
			return card_id
	return ""


func _upgrade_in_pile(pile: Array[Dictionary]) -> String:
	for i in range(pile.size()):
		var instance: Dictionary = pile[i]
		if bool(instance.get("upgraded", false)):
			continue
		instance["upgraded"] = true
		pile[i] = instance
		return CardInstanceScript.get_card_id(instance)
	return ""


func _transform_in_pile(pile: Array[Dictionary], source_ids: Array, replacement_id: String) -> String:
	for i in range(pile.size()):
		var instance: Dictionary = pile[i]
		var card_id := CardInstanceScript.get_card_id(instance)
		if source_ids.has(card_id):
			instance["card_id"] = replacement_id
			instance["upgraded"] = false
			pile[i] = instance
			return card_id
	return ""


func _find_first_not_in(pile: Array[Dictionary], excluded_ids: Array) -> String:
	for instance in pile:
		var card_id := CardInstanceScript.get_card_id(instance)
		if not excluded_ids.has(card_id):
			return card_id
	return ""


func _pile_has_card(pile: Array[Dictionary], card_id: String) -> bool:
	for instance in pile:
		if CardInstanceScript.get_card_id(instance) == card_id:
			return true
	return false
