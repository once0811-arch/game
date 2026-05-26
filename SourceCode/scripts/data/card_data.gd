class_name CardData
extends RefCounted


static func index_cards(card_set: Dictionary) -> Dictionary:
	var cards_by_id := {}
	for card in card_set.get("cards", []):
		if typeof(card) != TYPE_DICTIONARY:
			continue
		var card_id := String(card.get("id", ""))
		if not card_id.is_empty():
			cards_by_id[card_id] = card
	return cards_by_id


static func card_cost(card: Dictionary) -> int:
	return int(card.get("cost", 0))


static func card_name(card: Dictionary) -> String:
	return String(card.get("name", card.get("id", "Unknown Card")))


static func card_rules_text(card: Dictionary) -> String:
	return String(card.get("rules_text", ""))


static func card_type(card: Dictionary) -> String:
	return String(card.get("type", "card"))


static func card_rarity(card: Dictionary) -> String:
	return String(card.get("rarity", "common"))


static func is_reward_eligible(card: Dictionary) -> bool:
	return card_rarity(card) != "starter"
