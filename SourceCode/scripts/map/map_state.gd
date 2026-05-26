extends Node

const MapGeneratorScript := preload("res://scripts/map/map_generator.gd")

var nodes: Array[Dictionary] = []
var current_depth := 0
var selected_node_id := ""
var selected_enemy_id := ""


func start_act1() -> void:
	var generator = MapGeneratorScript.new()
	nodes = generator.generate_act1(DataRegistry.get_act1_encounters())
	current_depth = 0
	selected_node_id = ""
	selected_enemy_id = ""


func ensure_act1() -> void:
	if nodes.is_empty():
		start_act1()


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
	current_depth = int(snapshot.get("current_depth", 0))
	selected_node_id = String(snapshot.get("selected_node_id", ""))
	selected_enemy_id = String(snapshot.get("selected_enemy_id", ""))
	if nodes.is_empty():
		start_act1()
