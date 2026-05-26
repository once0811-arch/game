extends Node

const MAIN_SCENE := "res://scenes/main/main.tscn"
const MAP_SCENE := "res://scenes/map/map_screen.tscn"
const COMBAT_SCENE := "res://scenes/combat/combat_screen.tscn"
const CARD_REWARD_SCENE := "res://scenes/reward/card_reward_screen.tscn"
const COMPANION_REWARD_SCENE := "res://scenes/companion/companion_reward_screen.tscn"
const OATH_TACTIC_SELECT_SCENE := "res://scenes/companion/oath_tactic_select_screen.tscn"
const COMPANION_CARD_SELECT_SCENE := "res://scenes/companion/companion_card_select_screen.tscn"
const SHOP_SCENE := "res://scenes/shop/shop_screen.tscn"
const INN_SCENE := "res://scenes/inn/inn_screen.tscn"
const EVENT_SCENE := "res://scenes/event/event_screen.tscn"
const UPGRADE_SELECT_SCENE := "res://scenes/upgrade/upgrade_select_screen.tscn"
const ENDING_SCENE := "res://scenes/ending/ending_screen.tscn"


func go_to_main() -> void:
	_change_to(MAIN_SCENE)


func go_to_map() -> void:
	_change_to(MAP_SCENE)


func open_combat() -> void:
	_change_to(COMBAT_SCENE)


func open_card_reward() -> void:
	_change_to(CARD_REWARD_SCENE)


func open_companion_reward() -> void:
	_change_to(COMPANION_REWARD_SCENE)


func open_oath_tactic_select() -> void:
	_change_to(OATH_TACTIC_SELECT_SCENE)


func open_companion_card_select() -> void:
	_change_to(COMPANION_CARD_SELECT_SCENE)


func open_shop() -> void:
	_change_to(SHOP_SCENE)


func open_inn() -> void:
	_change_to(INN_SCENE)


func open_event() -> void:
	_change_to(EVENT_SCENE)


func open_upgrade_select() -> void:
	_change_to(UPGRADE_SELECT_SCENE)


func open_ending() -> void:
	_change_to(ENDING_SCENE)


func start_new_run() -> void:
	RunState.start_new_run()
	MapState.start_act1()
	go_to_map()


func _change_to(scene_path: String) -> void:
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Scene change failed %s: %s" % [scene_path, error])
