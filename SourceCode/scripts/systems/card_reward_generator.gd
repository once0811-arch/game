class_name CardRewardGenerator
extends RefCounted

const CardDataScript := preload("res://scripts/data/card_data.gd")

var rarity_weights := {
	"common": 70,
	"uncommon": 25,
	"rare": 5,
}


func generate_options(count: int = 3) -> Array[Dictionary]:
	var cards := DataRegistry.get_all_cards()
	var eligible: Array[Dictionary] = []
	for card in cards:
		if CardDataScript.is_reward_eligible(card):
			eligible.append(card)

	var options: Array[Dictionary] = []
	var used := {}
	while options.size() < count and used.size() < eligible.size():
		var rarity := _roll_rarity()
		var pool := _cards_by_rarity(eligible, rarity)
		if pool.is_empty():
			pool = eligible
		var card: Dictionary = RngService.pick(pool, {})
		var card_id := String(card.get("id", ""))
		if card_id.is_empty() or used.has(card_id):
			continue
		used[card_id] = true
		options.append(card)
	return options


func get_skip_gold() -> int:
	return int(DataRegistry.get_balance("rewards.skip_gold", 15))


func _roll_rarity() -> String:
	var total := 0
	for weight in rarity_weights.values():
		total += int(weight)
	var roll := RngService.roll_int(1, max(total, 1))
	var cursor := 0
	for rarity in rarity_weights.keys():
		cursor += int(rarity_weights[rarity])
		if roll <= cursor:
			return rarity
	return "common"


func _cards_by_rarity(cards: Array[Dictionary], rarity: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for card in cards:
		if String(card.get("rarity", "")) == rarity:
			result.append(card)
	return result
