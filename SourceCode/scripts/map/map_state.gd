extends Node

const MapGeneratorScript := preload("res://scripts/map/map_generator.gd")

var nodes: Array[Dictionary] = []
var map_act := 1
var current_depth := 0
var selected_node_id := ""
var selected_enemy_id := ""


func start_act1() -> void:
	start_act(1)


func start_act(act_number: int) -> void:
	var generator = MapGeneratorScript.new()
	map_act = int(clamp(act_number, 1, 3))
	nodes = generator.generate_act(DataRegistry.get_encounters_for_act(map_act), map_act)
	current_depth = 0
	selected_node_id = ""
	selected_enemy_id = ""


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
		return "available"
	return "locked"


func choose_node(node_id: String) -> bool:
	ensure_act1()
	for node in nodes:
		if String(node.get("id", "")) != node_id:
			continue
		if get_node_state(node) != "available":
			return false
		selected_node_id = node_id
		selected_enemy_id = String(node.get("enemy_id", ""))
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


func has_selected_node() -> bool:
	return not selected_node_id.is_empty()


func get_selected_enemy_id(default_enemy_id: String) -> String:
	if selected_enemy_id.is_empty():
		return default_enemy_id
	return selected_enemy_id


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
	if nodes.is_empty():
		start_act(RunState.act)
