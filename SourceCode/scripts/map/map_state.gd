extends Node

const MapGeneratorScript := preload("res://scripts/map/map_generator.gd")

var nodes: Array[Dictionary] = []
var map_act := 1
var current_depth := 0
var selected_node_id := ""
var selected_enemy_id := ""
var selected_enemy_ids: Array[String] = []
var selected_enemy_waves: Array = []


func start_act1() -> void:
	start_act(1)


func start_act(act_number: int) -> void:
	var generator = MapGeneratorScript.new()
	map_act = int(clamp(act_number, 1, 3))
	nodes = generator.generate_act(DataRegistry.get_encounters_for_act(map_act), map_act)
	current_depth = 0
	selected_node_id = ""
	selected_enemy_id = ""
	selected_enemy_ids.clear()
	selected_enemy_waves.clear()


func ensure_act1() -> void:
	if nodes.is_empty():
		start_act(RunState.act)


func ensure_current_act() -> void:
	if nodes.is_empty() or map_act != RunState.act:
		start_act(RunState.act)


func start_next_act() -> void:
	if RunState.act >= 3:
		return
	RunState.act += 1
	RunState.depth = 0
	RunState.phase_note = "Act %d begins. The castle bends further from the old world." % RunState.act
	start_act(RunState.act)
	RunTelemetry.record_act_reached(RunState.act)


func get_available_depth() -> int:
	return current_depth + 1


func get_node_state(node: Dictionary) -> String:
	if bool(node.get("completed", false)):
		return "completed"
	if int(node.get("depth", 0)) == get_available_depth():
		return "available" if _is_reachable(node) else "locked"
	return "locked"


func choose_node(node_id: String) -> bool:
	ensure_act1()
	for node in nodes:
		if String(node.get("id", "")) != node_id:
			continue
		if get_node_state(node) != "available":
			return false
		selected_node_id = node_id
		selected_enemy_waves = _read_enemy_waves(node)
		selected_enemy_ids = _flatten_enemy_waves(selected_enemy_waves)
		selected_enemy_id = selected_enemy_ids[0] if not selected_enemy_ids.is_empty() else String(node.get("enemy_id", ""))
		return true
	return false


func complete_selected_node() -> void:
	if selected_node_id.is_empty():
		return
	for i in range(nodes.size()):
		var node: Dictionary = nodes[i]
		if String(node.get("id", "")) == selected_node_id:
			node["completed"] = true
			nodes[i] = node
			current_depth = max(current_depth, int(node.get("depth", current_depth)))
			RunState.depth = current_depth
			break
	selected_node_id = ""
	selected_enemy_id = ""
	selected_enemy_ids.clear()
	selected_enemy_waves.clear()


func has_selected_node() -> bool:
	return not selected_node_id.is_empty()


func get_selected_enemy_id(default_enemy_id: String) -> String:
	if selected_enemy_id.is_empty():
		return default_enemy_id
	return selected_enemy_id


func get_selected_enemy_ids(default_enemy_id: String) -> Array[String]:
	if selected_enemy_ids.is_empty():
		var fallback := get_selected_enemy_id(default_enemy_id)
		var fallback_ids: Array[String] = []
		if not fallback.is_empty():
			fallback_ids.append(fallback)
		return fallback_ids
	return selected_enemy_ids.duplicate()


func get_selected_enemy_waves(default_enemy_id: String) -> Array:
	if selected_enemy_waves.is_empty():
		var ids := get_selected_enemy_ids(default_enemy_id)
		var fallback_waves: Array = []
		if not ids.is_empty():
			fallback_waves.append(ids)
		return fallback_waves
	return _duplicate_enemy_waves(selected_enemy_waves)


func get_selected_node_type() -> String:
	for node in nodes:
		if String(node.get("id", "")) == selected_node_id:
			return String(node.get("type", ""))
	return ""


func to_snapshot() -> Dictionary:
	return {
		"nodes": nodes.duplicate(true),
		"map_act": map_act,
		"current_depth": current_depth,
		"selected_node_id": selected_node_id,
		"selected_enemy_id": selected_enemy_id,
		"selected_enemy_ids": selected_enemy_ids.duplicate(),
		"selected_enemy_waves": selected_enemy_waves.duplicate(true),
	}


func from_snapshot(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		start_act1()
		return
	nodes = []
	for node in snapshot.get("nodes", []):
		if typeof(node) == TYPE_DICTIONARY:
			nodes.append(node)
	map_act = int(snapshot.get("map_act", RunState.act))
	current_depth = int(snapshot.get("current_depth", 0))
	selected_node_id = String(snapshot.get("selected_node_id", ""))
	selected_enemy_id = String(snapshot.get("selected_enemy_id", ""))
	selected_enemy_ids.clear()
	for enemy_id in snapshot.get("selected_enemy_ids", []):
		var id_text := String(enemy_id)
		if not id_text.is_empty():
			selected_enemy_ids.append(id_text)
	selected_enemy_waves.clear()
	for wave in snapshot.get("selected_enemy_waves", []):
		if typeof(wave) != TYPE_ARRAY:
			continue
		var ids: Array[String] = []
		for enemy_id in wave:
			var id_text := String(enemy_id)
			if not id_text.is_empty():
				ids.append(id_text)
		if not ids.is_empty():
			selected_enemy_waves.append(ids)
	if selected_enemy_ids.is_empty() and not selected_enemy_id.is_empty():
		selected_enemy_ids.append(selected_enemy_id)
	if selected_enemy_waves.is_empty() and not selected_enemy_ids.is_empty():
		selected_enemy_waves.append(selected_enemy_ids.duplicate())
	if nodes.is_empty():
		start_act(RunState.act)


func _read_enemy_waves(node: Dictionary) -> Array:
	var waves: Array = []
	if node.has("waves"):
		for raw_wave in node.get("waves", []):
			var ids := _read_wave_enemy_ids(raw_wave)
			if not ids.is_empty():
				waves.append(ids)
	if waves.is_empty():
		var ids := _read_enemy_ids(node)
		if not ids.is_empty():
			waves.append(ids)
	return waves


func _read_wave_enemy_ids(raw_wave: Variant) -> Array[String]:
	var ids: Array[String] = []
	if typeof(raw_wave) == TYPE_DICTIONARY:
		for enemy_id in raw_wave.get("enemy_ids", []):
			var id_text := String(enemy_id)
			if not id_text.is_empty():
				ids.append(id_text)
		if ids.is_empty():
			var single_id := String(raw_wave.get("enemy_id", ""))
			if not single_id.is_empty():
				ids.append(single_id)
	elif typeof(raw_wave) == TYPE_ARRAY:
		for enemy_id in raw_wave:
			var id_text := String(enemy_id)
			if not id_text.is_empty():
				ids.append(id_text)
	return ids


func _flatten_enemy_waves(waves: Array) -> Array[String]:
	var ids: Array[String] = []
	for wave in waves:
		if typeof(wave) != TYPE_ARRAY:
			continue
		for enemy_id in wave:
			var id_text := String(enemy_id)
			if not id_text.is_empty():
				ids.append(id_text)
	return ids


func _duplicate_enemy_waves(waves: Array) -> Array:
	var duplicate: Array = []
	for wave in waves:
		if typeof(wave) != TYPE_ARRAY:
			continue
		var ids: Array[String] = []
		for enemy_id in wave:
			var id_text := String(enemy_id)
			if not id_text.is_empty():
				ids.append(id_text)
		if not ids.is_empty():
			duplicate.append(ids)
	return duplicate


func _read_enemy_ids(node: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for enemy_id in node.get("enemy_ids", []):
		var id_text := String(enemy_id)
		if not id_text.is_empty():
			ids.append(id_text)
	if ids.is_empty():
		var single_id := String(node.get("enemy_id", ""))
		if not single_id.is_empty():
			ids.append(single_id)
	return ids


func _is_reachable(node: Dictionary) -> bool:
	var depth := int(node.get("depth", 0))
	if depth <= 1:
		return true
	var previous_completed := _completed_nodes_at_depth(depth - 1)
	if previous_completed.is_empty():
		return true
	var node_id := String(node.get("id", ""))
	for previous in previous_completed:
		for next_id in previous.get("next_ids", []):
			if String(next_id) == node_id:
				return true
	return false


func _completed_nodes_at_depth(depth: int) -> Array[Dictionary]:
	var completed_nodes: Array[Dictionary] = []
	for node in nodes:
		if int(node.get("depth", 0)) == depth and bool(node.get("completed", false)):
			completed_nodes.append(node)
	return completed_nodes
