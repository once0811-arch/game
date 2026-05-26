class_name CompanionRewardGenerator
extends RefCounted


func generate_options(count: int = 3) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var max_companions := int(DataRegistry.get_balance("run.max_companions", 2))
	if not RunState.party.can_recruit(max_companions):
		return result
	for companion in DataRegistry.get_all_companions():
		var companion_id := String(companion.get("id", ""))
		if companion_id.is_empty() or RunState.party.has_companion(companion_id):
			continue
		result.append(companion)
		if result.size() >= count:
			break
	return result


func get_card_options(companion_id: String) -> Array[Dictionary]:
	var cards := DataRegistry.get_companion_cards(companion_id)
	var count := int(DataRegistry.get_balance("rewards.companion_card_choices", 3))
	return cards.slice(0, count)
