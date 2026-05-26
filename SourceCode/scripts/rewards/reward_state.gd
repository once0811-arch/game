extends Node

var pending_source := ""


func begin_card_reward(source: String) -> void:
	pending_source = source


func claim_card(card_id: String) -> void:
	if not card_id.is_empty():
		RunState.deck.add_card_to_discard(card_id)
		RunTelemetry.record_card_reward("pick", card_id, 0)
		_complete_pending()


func skip_card_reward() -> int:
	var gold := int(DataRegistry.get_balance("rewards.skip_gold", 15))
	RunState.gold += gold
	RunTelemetry.record_card_reward("skip", "", gold)
	_complete_pending()
	return gold


func _complete_pending() -> void:
	if pending_source == "map_combat":
		MapState.complete_selected_node()
	pending_source = ""
