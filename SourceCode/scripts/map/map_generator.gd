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
	return nodes


func _sort_by_depth(a: Dictionary, b: Dictionary) -> bool:
	var a_depth := int(a.get("depth", 0))
	var b_depth := int(b.get("depth", 0))
	if a_depth == b_depth:
		return int(a.get("lane", 0)) < int(b.get("lane", 0))
	return a_depth < b_depth
