extends Node

const LAST_RUN_LOG_PATH := "user://telemetry_last_run.json"

var run_id := ""
var events: Array[Dictionary] = []
var counters: Dictionary = {}
var active_combat: Dictionary = {}


func reset_for_new_run(seed: int) -> void:
	run_id = "%s_%d" % [Time.get_datetime_string_from_system(false, true), seed]
	events.clear()
	active_combat.clear()
	counters = {
		"combats_started": 0,
		"combats_won": 0,
		"combats_lost": 0,
		"combat_waves_started": 0,
		"combat_multi_wave_nodes": 0,
		"cards_played": 0,
		"card_rewards_picked": 0,
		"card_rewards_skipped": 0,
		"companions_recruited": 0,
		"oath_triggers": 0,
		"healing_down_applied": 0,
		"shop_purchases": 0,
		"inn_rooms_used": 0,
		"event_choices": 0,
		"upgrades_taken": 0,
		"act_2_reached": 0,
		"act_3_reached": 0,
		"run_completed": 0,
	}
	record_event("run_start", {"seed": seed})


func _ensure_started() -> void:
	if run_id.is_empty():
		reset_for_new_run(RunState.run_seed)


func record_event(event_type: String, payload: Dictionary = {}) -> void:
	if run_id.is_empty() and event_type != "run_start":
		reset_for_new_run(RunState.run_seed)
	var entry := payload.duplicate(true)
	entry["type"] = event_type
	entry["act"] = RunState.act if RunState != null else 0
	entry["depth"] = RunState.depth if RunState != null else 0
	entry["gold"] = RunState.gold if RunState != null else 0
	entry["hp"] = RunState.current_hp if RunState != null else 0
	entry["max_hp"] = RunState.max_hp if RunState != null else 0
	entry["time"] = Time.get_unix_time_from_system()
	events.append(entry)


func begin_combat(enemy_id: String, node_type: String, wave_count: int = 1, enemy_ids: Array = []) -> void:
	_ensure_started()
	active_combat = {
		"enemy_id": enemy_id,
		"enemy_ids": enemy_ids.duplicate(),
		"node_type": node_type,
		"act": RunState.act,
		"depth": RunState.depth,
		"start_hp": RunState.current_hp,
		"cards_played": 0,
		"wave_count": maxi(wave_count, 1),
		"wave_hp_lost": [],
		"wave_turns": [],
	}
	counters["combats_started"] = int(counters.get("combats_started", 0)) + 1
	if wave_count > 1:
		counters["combat_multi_wave_nodes"] = int(counters.get("combat_multi_wave_nodes", 0)) + 1
	record_event("combat_start", active_combat)


func record_combat_wave(wave_index: int, wave_count: int, enemy_ids: Array) -> void:
	_ensure_started()
	counters["combat_waves_started"] = int(counters.get("combat_waves_started", 0)) + 1
	record_event("combat_wave", {
		"combat_wave_index": wave_index,
		"combat_wave_count": maxi(wave_count, 1),
		"enemy_ids": enemy_ids.duplicate(),
	})


func record_card_play(card_id: String) -> void:
	_ensure_started()
	counters["cards_played"] = int(counters.get("cards_played", 0)) + 1
	if not active_combat.is_empty():
		active_combat["cards_played"] = int(active_combat.get("cards_played", 0)) + 1
	record_event("card_played", {"card_id": card_id})


func end_combat(outcome: String, turns: int) -> void:
	_ensure_started()
	if active_combat.is_empty():
		return
	var start_hp: int = int(active_combat.get("start_hp", RunState.current_hp))
	var hp_lost: int = maxi(start_hp - RunState.current_hp, 0)
	var payload: Dictionary = active_combat.duplicate(true)
	payload["outcome"] = outcome
	payload["turns"] = turns
	payload["hp_lost"] = hp_lost
	payload["end_hp"] = RunState.current_hp
	payload["average_bond"] = get_average_bond()
	payload["wave_count"] = RunState.combat.wave_count
	payload["wave_hp_lost"] = RunState.combat.wave_hp_lost.duplicate()
	payload["wave_turns"] = RunState.combat.wave_turns.duplicate()
	if outcome == "victory":
		counters["combats_won"] = int(counters.get("combats_won", 0)) + 1
	else:
		counters["combats_lost"] = int(counters.get("combats_lost", 0)) + 1
	record_event("combat_end", payload)
	active_combat.clear()


func record_card_reward(action: String, card_id: String = "", gold: int = 0) -> void:
	_ensure_started()
	if action == "pick":
		counters["card_rewards_picked"] = int(counters.get("card_rewards_picked", 0)) + 1
	else:
		counters["card_rewards_skipped"] = int(counters.get("card_rewards_skipped", 0)) + 1
	record_event("card_reward", {"action": action, "card_id": card_id, "gold": gold})


func record_companion_recruited(companion_id: String, oath_id: String) -> void:
	_ensure_started()
	counters["companions_recruited"] = int(counters.get("companions_recruited", 0)) + 1
	record_event("companion_recruited", {"companion_id": companion_id, "oath_id": oath_id})


func record_oath_trigger(oath_id: String) -> void:
	_ensure_started()
	counters["oath_triggers"] = int(counters.get("oath_triggers", 0)) + 1
	record_event("oath_trigger", {"oath_id": oath_id})


func record_healing_down(percent: int, turns: int) -> void:
	_ensure_started()
	counters["healing_down_applied"] = int(counters.get("healing_down_applied", 0)) + 1
	record_event("healing_down", {"percent": percent, "turns": turns})


func record_shop_purchase(product_type: String, product_id: String, price: int) -> void:
	_ensure_started()
	counters["shop_purchases"] = int(counters.get("shop_purchases", 0)) + 1
	record_event("shop_purchase", {"product_type": product_type, "product_id": product_id, "price": price})


func record_inn_room(inn_type: String, room_id: String, price: int) -> void:
	_ensure_started()
	counters["inn_rooms_used"] = int(counters.get("inn_rooms_used", 0)) + 1
	record_event("inn_room", {"inn_type": inn_type, "room_id": room_id, "price": price})


func record_event_choice(event_id: String, choice_label: String) -> void:
	_ensure_started()
	counters["event_choices"] = int(counters.get("event_choices", 0)) + 1
	record_event("event_choice", {"event_id": event_id, "choice": choice_label})


func record_upgrade(source: String, option_id: String) -> void:
	_ensure_started()
	counters["upgrades_taken"] = int(counters.get("upgrades_taken", 0)) + 1
	record_event("upgrade", {"source": source, "option_id": option_id})


func record_act_reached(act_number: int) -> void:
	_ensure_started()
	if act_number == 2:
		counters["act_2_reached"] = 1
	elif act_number == 3:
		counters["act_3_reached"] = 1
	record_event("act_reached", {"act": act_number})


func record_run_complete() -> void:
	_ensure_started()
	counters["run_completed"] = 1
	record_event("run_complete", {"average_bond": get_average_bond()})
	write_last_run_log()


func get_average_bond() -> float:
	if RunState.party.companions.is_empty():
		return 0.0
	var total := 0
	for companion in RunState.party.companions:
		total += int(companion.get("bond_score", 0))
	return float(total) / float(RunState.party.companions.size())


func build_snapshot() -> Dictionary:
	return {
		"run_id": run_id,
		"seed": RunState.run_seed,
		"act": RunState.act,
		"depth": RunState.depth,
		"complete": RunState.run_complete,
		"counters": counters.duplicate(true),
		"average_bond": get_average_bond(),
		"events": events.duplicate(true),
	}


func write_last_run_log() -> bool:
	var file := FileAccess.open(LAST_RUN_LOG_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write telemetry log: %s" % LAST_RUN_LOG_PATH)
		return false
	file.store_string(JSON.stringify(build_snapshot(), "\t"))
	return true
