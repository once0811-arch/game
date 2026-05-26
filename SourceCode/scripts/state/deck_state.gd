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


func shuffle_discard_into_draw_pile() -> void:
	while not discard_pile.is_empty():
		draw_pile.append(discard_pile.pop_back())
	shuffle_draw_pile()


func shuffle_draw_pile() -> void:
	_shuffle_array(draw_pile)


func get_total_cards() -> int:
	return draw_pile.size() + hand.size() + discard_pile.size() + exhaust_pile.size()


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
