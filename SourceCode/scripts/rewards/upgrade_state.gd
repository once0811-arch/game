extends Node

var pending_source := ""


func begin_upgrade(source: String) -> void:
	pending_source = source


func complete_pending() -> void:
	if pending_source == "map_upgrade":
		MapState.complete_selected_node()
	elif pending_source == "act2_boss":
		MapState.complete_selected_node()
		MapState.start_next_act()
	pending_source = ""
