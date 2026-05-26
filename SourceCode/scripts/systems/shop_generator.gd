class_name ShopGenerator
extends RefCounted

const CardDataScript := preload("res://scripts/data/card_data.gd")


func generate_stock() -> Array[Dictionary]:
	var stock: Array[Dictionary] = []
	stock.append_array(_card_products())
	stock.append_array(_companion_card_products())
	stock.append_array(_equipment_products())
	stock.append_array(_service_products())
	return stock


func price_after_discount(price: int) -> int:
	var discount := RunState.equipment.get_total_bonus("shop_discount_percent")
	return max(int(round(price * (100 - discount) / 100.0)), 0)


func _card_products() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var count := int(DataRegistry.get_balance("shop.protagonist_cards", 4))
	var pool: Array[Dictionary] = []
	for card in DataRegistry.get_all_cards():
		if CardDataScript.is_reward_eligible(card):
			pool.append(card)
	var used := {}
	while result.size() < count and used.size() < pool.size():
		var card: Dictionary = RngService.pick(pool, {})
		var card_id := String(card.get("id", ""))
		if card_id.is_empty() or used.has(card_id):
			continue
		used[card_id] = true
		var price := _card_price(card)
		result.append({
			"id": "card_%s" % card_id,
			"type": "card",
			"card_id": card_id,
			"title": CardDataScript.card_name(card),
			"price": price_after_discount(price),
			"description": "%s\n%s" % [CardDataScript.card_rarity(card), CardDataScript.card_rules_text(card)],
		})
	return result


func _companion_card_products() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var count := int(DataRegistry.get_balance("shop.companion_cards", 2))
	var pool: Array[Dictionary] = []
	for companion in RunState.party.companions:
		for card in DataRegistry.get_companion_cards(String(companion.get("id", ""))):
			var card_id := String(card.get("id", ""))
			if not card_id.is_empty() and not RunState.deck.has_card_id(card_id):
				pool.append(card)
	var used := {}
	while result.size() < count and used.size() < pool.size():
		var card: Dictionary = RngService.pick(pool, {})
		var card_id := String(card.get("id", ""))
		if card_id.is_empty() or used.has(card_id):
			continue
		used[card_id] = true
		var price := 85 + 15 * result.size()
		result.append({
			"id": "companion_card_%s" % card_id,
			"type": "card",
			"card_id": card_id,
			"title": CardDataScript.card_name(card),
			"price": price_after_discount(price),
			"description": "companion\n%s" % CardDataScript.card_rules_text(card),
		})
	return result


func _equipment_products() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var count := int(DataRegistry.get_balance("shop.equipment_items", 3))
	var pool := DataRegistry.get_all_equipment()
	var used := {}
	while result.size() < count and used.size() < pool.size():
		var item: Dictionary = RngService.pick(pool, {})
		var item_id := String(item.get("id", ""))
		if item_id.is_empty() or used.has(item_id):
			continue
		used[item_id] = true
		result.append({
			"id": "equipment_%s" % item_id,
			"type": "equipment",
			"equipment_id": item_id,
			"title": item.get("name", "Equipment"),
			"price": price_after_discount(int(item.get("price", 100))),
			"description": "%s / %s\n%s" % [item.get("rarity", "common"), item.get("slot", "?"), item.get("rules_text", "")],
		})
	return result


func _service_products() -> Array[Dictionary]:
	var remove_price: int = int(DataRegistry.get_balance("shop.remove_base_cost", 75)) + RunState.equipment.card_remove_count * int(DataRegistry.get_balance("shop.remove_cost_growth", 25))
	var upgrade_price := int(DataRegistry.get_balance("shop.service_upgrade_cost", 110))
	var transform_price := int(DataRegistry.get_balance("shop.service_transform_cost", 85))
	var copy_price := int(DataRegistry.get_balance("shop.service_copy_cost", 125))
	return [
		{"id": "service_remove", "type": "service", "service": "remove", "title": "Remove Card", "price": price_after_discount(remove_price), "description": "Remove the first starter card found."},
		{"id": "service_upgrade", "type": "service", "service": "upgrade", "title": "Upgrade Card", "price": price_after_discount(upgrade_price), "description": "Upgrade the first unupgraded card."},
		{"id": "service_transform", "type": "service", "service": "transform", "title": "Transform Card", "price": price_after_discount(transform_price), "description": "Transform the first starter card into a reward card."},
		{"id": "service_copy", "type": "service", "service": "copy", "title": "Copy Card", "price": price_after_discount(copy_price), "description": "Copy the first non-starter card."},
	]


func _card_price(card: Dictionary) -> int:
	match CardDataScript.card_rarity(card):
		"rare":
			return RngService.roll_int(135, 175)
		"uncommon":
			return RngService.roll_int(70, 95)
		_:
			return RngService.roll_int(45, 60)
