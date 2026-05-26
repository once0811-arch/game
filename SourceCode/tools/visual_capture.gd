extends SceneTree

var _capture_started := false


func _init() -> void:
	call_deferred("_begin_capture")


func _initialize() -> void:
	call_deferred("_begin_capture")


func _process(_delta: float) -> bool:
	if not _capture_started:
		_begin_capture()
	return false


func _begin_capture() -> void:
	if _capture_started:
		return
	_capture_started = true
	_capture.call_deferred()


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path := "res://scenes/main/main.tscn"
	var output_path := OS.get_user_data_dir().path_join("visual_capture.png")
	var mode := "default"
	var dump_tree := false
	for i in range(args.size()):
		match args[i]:
			"--scene":
				if i + 1 < args.size():
					scene_path = args[i + 1]
			"--out":
				if i + 1 < args.size():
					output_path = args[i + 1]
			"--mode":
				if i + 1 < args.size():
					mode = args[i + 1]
			"--dump-tree":
				dump_tree = true

	_prepare_state(mode)
	var packed := load(scene_path) as PackedScene
	if packed == null:
		printerr("Could not load scene: " + scene_path)
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	for _i in range(8):
		await process_frame
	if dump_tree:
		_dump_control_tree(scene, 0)
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		printerr("Could not capture viewport texture. Run visual_capture without --headless so Godot has a real display driver.")
		quit(1)
		return
	var image := viewport_texture.get_image()
	if image == null:
		printerr("Could not capture viewport image. Run visual_capture without --headless so Godot has a real display driver.")
		quit(1)
		return
	var error := image.save_png(output_path)
	if error != OK:
		printerr("Could not save screenshot: " + output_path)
		quit(1)
		return
	print("Saved visual capture: " + output_path)
	quit()


func _prepare_state(mode: String) -> void:
	var run_state := root.get_node_or_null("/root/RunState")
	var map_state := root.get_node_or_null("/root/MapState")
	if run_state == null or map_state == null:
		return
	if not bool(run_state.get("is_run_active")):
		run_state.call("start_new_run")
	map_state.call("ensure_current_act")
	if mode == "combat_companion":
		_recruit_demo_companion("rowan", "rowan_spear_line", ["c_rowan_pin", "c_rowan_banner"])
	elif mode == "oath_rowan":
		_prepare_companion_selection("rowan")
	elif mode == "companion_cards_rowan":
		_prepare_companion_card_selection("rowan", "rowan_spear_line")
	elif mode == "map_after_first":
		map_state.call("choose_node", "act1_depth_01_lane_0")
		map_state.call("complete_selected_node")
	elif mode == "map_after_midboss":
		map_state.set("current_depth", 7)
	elif mode == "map_act1":
		map_state.set("current_depth", 0)


func _recruit_demo_companion(companion_id: String, oath_id: String, card_ids: Array[String]) -> void:
	var run_state := root.get_node_or_null("/root/RunState")
	var data_registry := root.get_node_or_null("/root/DataRegistry")
	if run_state == null or data_registry == null:
		return
	var party = run_state.get("party")
	if party.has_companion(companion_id):
		return
	var companion_data: Dictionary = data_registry.call("get_companion", companion_id)
	if companion_data.is_empty():
		return
	var oath := {}
	for candidate in companion_data.get("oath_tactics", []):
		if typeof(candidate) == TYPE_DICTIONARY and String(candidate.get("id", "")) == oath_id:
			oath = candidate
	var recruited := {
		"id": companion_id,
		"name": String(companion_data.get("name", companion_id)),
		"role": String(companion_data.get("role", "")),
		"portrait_asset_id": String(companion_data.get("portrait_asset_id", "")),
		"sprite_asset_id": String(companion_data.get("sprite_asset_id", "")),
		"oath_id": oath_id,
		"oath_name": String(oath.get("name", oath_id)),
		"oath_rules_text": String(oath.get("rules_text", "")),
		"bond_score": 30,
		"card_ids": card_ids.duplicate(),
	}
	party.add_companion(recruited)


func _prepare_companion_selection(companion_id: String) -> void:
	var manager := root.get_node_or_null("/root/CompanionManager")
	if manager == null:
		return
	manager.call("begin_recruitment", "visual_capture")
	manager.call("select_companion", companion_id)


func _prepare_companion_card_selection(companion_id: String, oath_id: String) -> void:
	var manager := root.get_node_or_null("/root/CompanionManager")
	if manager == null:
		return
	manager.call("begin_recruitment", "visual_capture")
	manager.call("select_companion", companion_id)
	manager.call("select_oath", oath_id)


func _dump_control_tree(node: Node, depth: int) -> void:
	var indent := ""
	for _i in range(depth):
		indent += "  "
	var line := "%s%s" % [indent, node.name]
	if node is Control:
		var control := node as Control
		line += " %s pos=%s size=%s min=%s visible=%s" % [
			node.get_class(),
			str(control.position),
			str(control.size),
			str(control.custom_minimum_size),
			str(control.visible),
		]
	if node is Label:
		line += " text=\"%s\"" % String((node as Label).text).left(80)
	if node is Button:
		line += " text=\"%s\"" % String((node as Button).text).replace("\n", " | ").left(80)
	print(line)
	for child in node.get_children():
		_dump_control_tree(child, depth + 1)
