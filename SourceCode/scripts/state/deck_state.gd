class_name DeckState
extends RefCounted

var draw_pile: Array[Dictionary] = []
var hand: Array[Dictionary] = []
var discard_pile: Array[Dictionary] = []
var exhaust_pile: Array[Dictionary] = []


func reset() -> void:
	draw_pile.clear()
	hand.clear()
	discard_pile.clear()
	exhaust_pile.clear()


func get_total_cards() -> int:
	return draw_pile.size() + hand.size() + discard_pile.size() + exhaust_pile.size()


func to_dict() -> Dictionary:
	return {
		"draw_pile": draw_pile.duplicate(true),
		"hand": hand.duplicate(true),
		"discard_pile": discard_pile.duplicate(true),
		"exhaust_pile": exhaust_pile.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	draw_pile = _dictionary_array(data.get("draw_pile", []))
	hand = _dictionary_array(data.get("hand", []))
	discard_pile = _dictionary_array(data.get("discard_pile", []))
	exhaust_pile = _dictionary_array(data.get("exhaust_pile", []))


func _dictionary_array(values: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(values) != TYPE_ARRAY:
		return result
	for value in values:
		if typeof(value) == TYPE_DICTIONARY:
			result.append(value)
	return result
