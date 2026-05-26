class_name MapGenerator
extends RefCounted


func generate_act1(encounter_data: Dictionary) -> Array[Dictionary]:
	return generate_act(encounter_data, 1)


func generate_act(encounter_data: Dictionary, act_number: int) -> Array[Dictionary]:
	var nodes: Array[Dictionary] = []
	var lane_counts_by_depth: Dictionary = {}
	for node_data in encounter_data.get("nodes", []):
		if typeof(node_data) != TYPE_DICTIONARY:
			continue
		var node: Dictionary = node_data.duplicate(true)
		var depth := int(node.get("depth", nodes.size() + 1))
		var lane_count := int(lane_counts_by_depth.get(depth, 0))
		lane_counts_by_depth[depth] = lane_count + 1
		var lane := int(node.get("lane", lane_count))
		node["depth"] = depth
		node["lane"] = lane
		node["id"] = "act%d_depth_%02d_lane_%d" % [act_number, depth, lane]
		node["act"] = act_number
		node["completed"] = false
		nodes.append(node)
	nodes.sort_custom(_sort_by_depth)
	_add_connections(nodes)
	return nodes


func _sort_by_depth(a: Dictionary, b: Dictionary) -> bool:
	var a_depth := int(a.get("depth", 0))
	var b_depth := int(b.get("depth", 0))
	if a_depth == b_depth:
		return int(a.get("lane", 0)) < int(b.get("lane", 0))
	return a_depth < b_depth


func _add_connections(nodes: Array[Dictionary]) -> void:
	var by_depth: Dictionary = {}
	for node in nodes:
		var depth := int(node.get("depth", 0))
		if not by_depth.has(depth):
			by_depth[depth] = []
		by_depth[depth].append(node)
	for depth in by_depth.keys():
		var current_nodes: Array = by_depth[depth]
		for node in current_nodes:
			node["next_ids"] = []
	for depth in range(1, 12):
		if not by_depth.has(depth) or not by_depth.has(depth + 1):
			continue
		var current_nodes: Array = by_depth[depth]
		var next_nodes: Array = by_depth[depth + 1]
		for node in current_nodes:
			var next_ids: Array[String] = _pick_next_ids(node, next_nodes)
			node["next_ids"] = next_ids


func _pick_next_ids(node: Dictionary, next_nodes: Array) -> Array[String]:
	var next_ids: Array[String] = []
	var lane := int(node.get("lane", 1))
	if next_nodes.size() <= 1:
		for candidate in next_nodes:
			next_ids.append(String(candidate.get("id", "")))
		return next_ids
	_add_next_if_lane_exists(next_ids, next_nodes, lane)
	var branch_lane := lane + (1 if (int(node.get("depth", 0)) + lane) % 2 == 0 else -1)
	if not _add_next_if_lane_exists(next_ids, next_nodes, branch_lane):
		if not _add_next_if_lane_exists(next_ids, next_nodes, lane + 1):
			_add_next_if_lane_exists(next_ids, next_nodes, lane - 1)
	return next_ids


func _add_next_if_lane_exists(next_ids: Array[String], next_nodes: Array, lane: int) -> bool:
	for candidate in next_nodes:
		if int(candidate.get("lane", 0)) != lane:
			continue
		var id_text := String(candidate.get("id", ""))
		if not id_text.is_empty() and not next_ids.has(id_text):
			next_ids.append(id_text)
		return true
	return false
