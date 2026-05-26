extends Control

var run_label: Label
var node_grid: GridContainer
var map_log_label: Label
var equipment_label: Label
var equipment_box: HBoxContainer
var equipment_status_label: Label


func _ready() -> void:
	if RunState.is_run_active:
		MapState.ensure_current_act()
	_build_ui()
	_refresh()


func _build_ui() -> void:
	var background := TextureRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var bg_path := DataRegistry.get_temp_asset_path("bg_map_act1_route")
	if not bg_path.is_empty():
		background.texture = load(bg_path)
	add_child(background)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.03, 0.035, 0.035, 0.50)
	add_child(shade)

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 42)
	root.add_theme_constant_override("margin_top", 34)
	root.add_theme_constant_override("margin_right", 42)
	root.add_theme_constant_override("margin_bottom", 32)
	add_child(root)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	root.add_child(layout)

	var title := Label.new()
	title.text = "Act %d Route" % RunState.act
	title.add_theme_font_size_override("font_size", 34)
	layout.add_child(title)

	run_label = Label.new()
	run_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	run_label.modulate = Color(0.86, 0.88, 0.83)
	layout.add_child(run_label)

	var map_area := PanelContainer.new()
	map_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(map_area)

	var map_box := VBoxContainer.new()
	map_box.add_theme_constant_override("separation", 10)
	map_area.add_child(map_box)

	var hint := Label.new()
	hint.text = "The road opens one contract at a time."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	map_box.add_child(hint)

	node_grid = GridContainer.new()
	node_grid.columns = 4
	node_grid.add_theme_constant_override("h_separation", 10)
	node_grid.add_theme_constant_override("v_separation", 10)
	map_box.add_child(node_grid)

	map_log_label = Label.new()
	map_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	map_log_label.modulate = Color(0.82, 0.84, 0.78)
	map_box.add_child(map_log_label)

	var equipment_panel := PanelContainer.new()
	layout.add_child(equipment_panel)

	var equipment_layout := VBoxContainer.new()
	equipment_layout.add_theme_constant_override("separation", 8)
	equipment_panel.add_child(equipment_layout)

	equipment_label = Label.new()
	equipment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	equipment_layout.add_child(equipment_label)

	equipment_box = HBoxContainer.new()
	equipment_box.add_theme_constant_override("separation", 8)
	equipment_layout.add_child(equipment_box)

	equipment_status_label = Label.new()
	equipment_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	equipment_status_label.modulate = Color(0.82, 0.88, 0.80)
	equipment_layout.add_child(equipment_status_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	layout.add_child(actions)

	var save_button := Button.new()
	save_button.text = "Save Snapshot"
	save_button.pressed.connect(_on_save_pressed)
	actions.add_child(save_button)

	var gallery := Button.new()
	gallery.text = "Asset Gallery"
	gallery.pressed.connect(Callable(SceneRouter, "open_asset_gallery"))
	actions.add_child(gallery)

	var deck_debug := Button.new()
	deck_debug.text = "Deck Debug"
	deck_debug.pressed.connect(Callable(SceneRouter, "open_deck_debug"))
	actions.add_child(deck_debug)

	var combat_test := Button.new()
	combat_test.text = "Combat Test"
	combat_test.pressed.connect(Callable(SceneRouter, "open_combat_test"))
	actions.add_child(combat_test)

	var shop_test := Button.new()
	shop_test.text = "Shop"
	shop_test.pressed.connect(Callable(SceneRouter, "open_shop"))
	actions.add_child(shop_test)

	var inn_test := Button.new()
	inn_test.text = "Inn"
	inn_test.pressed.connect(Callable(SceneRouter, "open_inn"))
	actions.add_child(inn_test)

	var event_test := Button.new()
	event_test.text = "Event"
	event_test.pressed.connect(Callable(SceneRouter, "open_event"))
	actions.add_child(event_test)

	var main := Button.new()
	main.text = "Main Menu"
	main.pressed.connect(Callable(SceneRouter, "go_to_main"))
	actions.add_child(main)


func _refresh_run_info() -> void:
	if not RunState.is_run_active:
		run_label.text = "No active run. Return to Main Menu and start a new run."
		return
	run_label.text = "Seed %d | Act %d | Map Depth %d | HP %d/%d | Gold %d\n%s\n%s" % [
		RunState.run_seed,
		RunState.act,
		MapState.current_depth,
		RunState.current_hp,
		RunState.max_hp,
		RunState.gold,
		RunState.phase_note,
		RunState.party.get_companion_summary(),
	]


func _refresh() -> void:
	_refresh_run_info()
	_refresh_nodes()
	_refresh_equipment()


func _refresh_nodes() -> void:
	for child in node_grid.get_children():
		child.queue_free()
	if not RunState.is_run_active:
		map_log_label.text = "Start a new run to generate the Act 1 route."
		return
	MapState.ensure_current_act()
	map_log_label.text = "Reachable depth: %d / 12" % MapState.get_available_depth()
	for node in MapState.nodes:
		node_grid.add_child(_make_node_button(node))


func _make_node_button(node: Dictionary) -> Button:
	var button := Button.new()
	var state := MapState.get_node_state(node)
	var prefix := "D%d" % int(node.get("depth", 0))
	button.custom_minimum_size = Vector2(170, 66)
	button.text = "%s %s\n%s" % [prefix, String(node.get("type", "?")), String(node.get("label", ""))]
	button.disabled = state != "available"
	if state == "completed":
		button.text += "\nDone"
	elif state == "locked":
		button.text += "\nLocked"
	button.pressed.connect(_on_node_pressed.bind(String(node.get("id", ""))))
	return button


func _on_node_pressed(node_id: String) -> void:
	if not MapState.choose_node(node_id):
		return
	var node_type := MapState.get_selected_node_type()
	if node_type in ["combat", "elite", "midboss", "boss"]:
		SceneRouter.open_combat_test()
	elif node_type == "companion_contract":
		CompanionManager.begin_recruitment("map_contract")
		SceneRouter.open_companion_reward()
	elif node_type == "shop":
		SceneRouter.open_shop()
	elif node_type == "inn":
		SceneRouter.open_inn()
	elif node_type == "event":
		SceneRouter.open_event()
	elif node_type == "upgrade":
		UpgradeState.begin_upgrade("map_upgrade")
		SceneRouter.open_upgrade_select()
	else:
		MapState.complete_selected_node()
		_refresh()


func _on_save_pressed() -> void:
	var snapshot := RunState.to_snapshot()
	snapshot["map"] = MapState.to_snapshot()
	SaveService.write_run_snapshot(snapshot)
	RunTelemetry.write_last_run_log()
	_refresh()


func _refresh_equipment() -> void:
	if equipment_label == null:
		return
	var equipped_lines := RunState.equipment.get_equipped_lines()
	if equipped_lines.is_empty():
		equipment_label.text = "Equipment: none"
	else:
		equipment_label.text = "Equipment\n" + "\n".join(PackedStringArray(equipped_lines))
	for child in equipment_box.get_children():
		child.queue_free()
	if RunState.equipment.owned_items.is_empty():
		equipment_status_label.text = "No equipment in inventory."
		return
	equipment_status_label.text = "Inventory"
	for instance in RunState.equipment.owned_items:
		var data := RunState.equipment.get_data_for_instance(instance)
		var button := Button.new()
		button.custom_minimum_size = Vector2(170, 58)
		button.text = "#%d %s\n%s" % [
			int(instance.get("instance_id", 0)),
			data.get("name", "Equipment"),
			data.get("slot", "?"),
		]
		button.pressed.connect(_on_equipment_pressed.bind(int(instance.get("instance_id", 0))))
		equipment_box.add_child(button)


func _on_equipment_pressed(instance_id: int) -> void:
	equipment_status_label.text = RunState.equipment.equip_cycle(instance_id)
	_refresh_equipment()
