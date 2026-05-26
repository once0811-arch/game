class_name MapGenerator
extends RefCounted


func generate_act1(encounter_data: Dictionary) -> Array[Dictionary]:
	var nodes: Array[Dictionary] = []
	for node_data in encounter_data.get("nodes", []):
		if typeof(node_data) != TYPE_DICTIONARY:
			continue
		var node: Dictionary = node_data.duplicate(true)
		node["id"] = "act1_depth_%02d" % int(node.get("depth", nodes.size() + 1))
		node["completed"] = false
		nodes.append(node)
	nodes.sort_custom(_sort_by_depth)
	return nodes


func _sort_by_depth(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("depth", 0)) < int(b.get("depth", 0))
