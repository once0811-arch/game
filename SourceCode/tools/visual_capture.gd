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
	await _perform_preview_action(scene, mode)
	for _i in range(4):
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
	if mode in ["combat_companion", "combat_card_preview", "combat_enemy_preview", "combat_wave_preview", "combat_wave_advance_preview"]:
		_recruit_demo_companion("rowan", "rowan_spear_line", ["c_rowan_pin", "c_rowan_banner"])
		if mode in ["combat_wave_preview", "combat_wave_advance_preview"]:
			_prepare_wave_preview()
	elif mode == "upgrade_companion_preview":
		_recruit_demo_companion("rowan", "rowan_spear_line", ["c_rowan_pin", "c_rowan_banner"])
		_prepare_upgrade_preview()
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


func _perform_preview_action(scene: Node, mode: String) -> void:
	match mode:
		"main_settings":
			await _preview_main_settings(scene)
		"combat_card_preview":
			await _preview_combat_card(scene)
		"combat_targeting_preview":
			await _preview_combat_targeting(scene)
		"combat_enemy_preview":
			await _preview_enemy_turn(scene)
		"combat_wave_advance_preview":
			await _preview_wave_advance(scene)
		"shop_purchase_preview":
			await _preview_shop_purchase(scene)
		"shop_service_preview":
			await _preview_shop_service(scene)
		"shop_service_apply_preview":
			await _preview_shop_service_apply(scene)
		"reward_claim_preview":
			await _preview_reward_claim(scene)
		"inn_room_preview":
			await _preview_inn_room(scene)


func _preview_combat_card(scene: Node) -> void:
	var run_state := root.get_node_or_null("/root/RunState")
	if run_state == null or not scene.has_method("_play_card_at_target"):
		return
	var hand = run_state.get("deck").hand
	for i in range(hand.size()):
		if scene.has_method("_is_card_playable") and not bool(scene.call("_is_card_playable", i)):
			continue
		if scene.has_method("_card_requires_target") and bool(scene.call("_card_requires_target", i)):
			scene.call("_play_card_at_target", i, 0)
			await create_timer(0.12).timeout
			return
	for i in range(hand.size()):
		if scene.has_method("_is_card_playable") and bool(scene.call("_is_card_playable", i)):
			scene.call("_play_card_at_target", i, -1)
			await create_timer(0.12).timeout
			return


func _preview_combat_targeting(scene: Node) -> void:
	var run_state := root.get_node_or_null("/root/RunState")
	if run_state == null or not scene.has_method("_on_card_pressed"):
		return
	var hand = run_state.get("deck").hand
	for i in range(hand.size()):
		if scene.has_method("_is_card_playable") and not bool(scene.call("_is_card_playable", i)):
			continue
		if scene.has_method("_card_requires_target") and bool(scene.call("_card_requires_target", i)):
			scene.call("_on_card_pressed", i)
			await create_timer(0.12).timeout
			return


func _preview_main_settings(scene: Node) -> void:
	if not scene.has_method("_on_settings_pressed"):
		return
	scene.call("_on_settings_pressed")
	await create_timer(0.10).timeout


func _preview_enemy_turn(scene: Node) -> void:
	if not scene.has_method("_on_end_turn_pressed"):
		return
	scene.call("_on_end_turn_pressed")
	await create_timer(0.10).timeout


func _preview_wave_advance(scene: Node) -> void:
	var run_state := root.get_node_or_null("/root/RunState")
	if run_state == null or not scene.has_method("_play_card_at_target"):
		return
	if run_state.get("combat").enemies.is_empty():
		return
	var enemy: Dictionary = run_state.get("combat").enemies[0]
	enemy["hp"] = 1
	run_state.get("combat").enemies[0] = enemy
	if scene.has_method("_refresh"):
		scene.call("_refresh")
	var hand = run_state.get("deck").hand
	for i in range(hand.size()):
		if scene.has_method("_is_card_playable") and not bool(scene.call("_is_card_playable", i)):
			continue
		if scene.has_method("_card_requires_target") and bool(scene.call("_card_requires_target", i)):
			scene.call("_play_card_at_target", i, 0)
			await create_timer(0.20).timeout
			return


func _preview_shop_purchase(scene: Node) -> void:
	if not scene.has_method("_on_product_pressed"):
		return
	var index := 0
	var products = scene.get("stock")
	var run_state := root.get_node_or_null("/root/RunState")
	if typeof(products) == TYPE_ARRAY and run_state != null:
		for i in range(products.size()):
			var product = products[i]
			if typeof(product) == TYPE_DICTIONARY and int(product.get("price", 0)) <= int(run_state.get("gold")):
				index = i
				break
	scene.call("_on_product_pressed", index)
	await create_timer(0.10).timeout


func _preview_shop_service(scene: Node) -> void:
	if not scene.has_method("_on_product_pressed"):
		return
	var run_state := root.get_node_or_null("/root/RunState")
	if run_state != null:
		run_state.set("gold", 300)
	var products = scene.get("stock")
	if typeof(products) == TYPE_ARRAY:
		for i in range(products.size()):
			var product = products[i]
			if typeof(product) == TYPE_DICTIONARY and String(product.get("type", "")) == "service":
				scene.call("_on_product_pressed", i)
				await create_timer(0.10).timeout
				return


func _preview_shop_service_apply(scene: Node) -> void:
	await _preview_shop_service(scene)
	var run_state := root.get_node_or_null("/root/RunState")
	if run_state == null or not scene.has_method("_on_service_card_pressed"):
		return
	var entries = run_state.get("deck").get_card_entries(false)
	if typeof(entries) == TYPE_ARRAY and not entries.is_empty():
		var entry: Dictionary = entries[0]
		scene.call("_on_service_card_pressed", int(entry.get("instance_id", 0)))
		await create_timer(0.12).timeout


func _preview_inn_room(scene: Node) -> void:
	if not scene.has_method("_on_room_pressed"):
		return
	var index := 0
	var rooms = scene.get("rooms")
	var run_state := root.get_node_or_null("/root/RunState")
	if typeof(rooms) == TYPE_ARRAY and run_state != null:
		for i in range(rooms.size()):
			var room = rooms[i]
			if typeof(room) == TYPE_DICTIONARY and int(room.get("price", 0)) <= int(run_state.get("gold")):
				index = i
				break
	scene.call("_on_room_pressed", index)
	await create_timer(0.10).timeout


func _preview_reward_claim(scene: Node) -> void:
	if not scene.has_method("_on_reward_pressed"):
		return
	scene.call("_on_reward_pressed", 0)
	await create_timer(0.10).timeout


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


func _prepare_upgrade_preview() -> void:
	var run_state := root.get_node_or_null("/root/RunState")
	var upgrade_state := root.get_node_or_null("/root/UpgradeState")
	if run_state == null:
		return
	var party = run_state.get("party")
	for i in range(party.companions.size()):
		var companion: Dictionary = party.companions[i]
		companion["bond_score"] = 60
		companion["attack_bonus"] = 1
		party.companions[i] = companion
	if upgrade_state != null:
		upgrade_state.call("begin_upgrade", "act2_boss")


func _prepare_wave_preview() -> void:
	var map_state := root.get_node_or_null("/root/MapState")
	if map_state == null:
		return
	map_state.set("selected_enemy_id", "enemy_act2_receipt_hound")
	map_state.set("selected_enemy_ids", ["enemy_act2_receipt_hound", "enemy_act2_heal_censor_scholar"])
	map_state.set("selected_enemy_waves", [
		["enemy_act2_receipt_hound"],
		["enemy_act2_heal_censor_scholar"],
	])


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
