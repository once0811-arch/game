extends Control

const UIStyleScript := preload("res://scripts/ui/ui_style.gd")

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
	UIStyleScript.add_background(self, "bg_map_act1_route", 0.70)
	var root := UIStyleScript.page_root(self, 28)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	root.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	layout.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 2)
	header.add_child(title_box)

	var title := UIStyleScript.label("Act %d Route" % RunState.act, 34)
	title_box.add_child(title)

	run_label = UIStyleScript.label("", 15, UIStyleScript.MUTED)
	title_box.add_child(run_label)

	var save_button := Button.new()
	save_button.text = "Save"
	save_button.custom_minimum_size = Vector2(92, 42)
	UIStyleScript.style_button(save_button, "primary")
	save_button.pressed.connect(_on_save_pressed)
	header.add_child(save_button)

	var main := Button.new()
	main.text = "Menu"
	main.custom_minimum_size = Vector2(92, 42)
	UIStyleScript.style_button(main)
	main.pressed.connect(Callable(SceneRouter, "go_to_main"))
	header.add_child(main)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	layout.add_child(body)

	var route_layout := VBoxContainer.new()
	route_layout.add_theme_constant_override("separation", 10)
	var map_area := UIStyleScript.panel(route_layout, Vector2(0, 0))
	map_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(map_area)

	map_log_label = UIStyleScript.label("", 16, UIStyleScript.stat_text())
	route_layout.add_child(map_log_label)

	node_grid = GridContainer.new()
	node_grid.columns = 4
	node_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	node_grid.add_theme_constant_override("h_separation", 12)
	node_grid.add_theme_constant_override("v_separation", 12)
	route_layout.add_child(node_grid)

	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(305, 0)
	side.add_theme_constant_override("separation", 12)
	body.add_child(side)

	var party_panel_layout := VBoxContainer.new()
	party_panel_layout.add_theme_constant_override("separation", 8)
	var party_panel := UIStyleScript.panel(party_panel_layout, Vector2(0, 150), true)
	side.add_child(party_panel)

	party_panel_layout.add_child(UIStyleScript.label("Party", 20))
	equipment_label = UIStyleScript.label("", 14, UIStyleScript.MUTED)
	party_panel_layout.add_child(equipment_label)

	var equipment_panel_layout := VBoxContainer.new()
	equipment_panel_layout.add_theme_constant_override("separation", 8)
	var equipment_panel := UIStyleScript.panel(equipment_panel_layout, Vector2(0, 190), true)
	equipment_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(equipment_panel)

	equipment_panel_layout.add_child(UIStyleScript.label("Equipment", 20))
	equipment_box = HBoxContainer.new()
	equipment_box.add_theme_constant_override("separation", 8)
	equipment_panel_layout.add_child(equipment_box)

	equipment_status_label = UIStyleScript.label("", 14, UIStyleScript.MUTED)
	equipment_panel_layout.add_child(equipment_status_label)


func _refresh_run_info() -> void:
	if not RunState.is_run_active:
		run_label.text = "No active run. Return to Main Menu and start a new run."
		return
	run_label.text = "Seed %d  |  Depth %d/12  |  HP %d/%d  |  Gold %d\n%s" % [
		RunState.run_seed,
		MapState.current_depth,
		RunState.current_hp,
		RunState.max_hp,
		RunState.gold,
		RunState.phase_note,
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
	map_log_label.text = "Next contract depth: %d / 12" % MapState.get_available_depth()
	for node in MapState.nodes:
		node_grid.add_child(_make_node_button(node))


func _make_node_button(node: Dictionary) -> Button:
	var button := Button.new()
	var state := MapState.get_node_state(node)
	var prefix := "D%d" % int(node.get("depth", 0))
	var node_type := String(node.get("type", "?"))
	button.custom_minimum_size = Vector2(176, 82)
	button.text = "%s  %s\n%s" % [prefix, node_type.to_upper(), String(node.get("label", ""))]
	button.disabled = state != "available"
	if state == "completed":
		button.text += "\nCLEARED"
	elif state == "locked":
		button.text += "\nLOCKED"
	var variant := "primary" if state == "available" else "locked"
	if state == "completed":
		variant = "success"
	UIStyleScript.style_card_button(button, variant)
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
		equipment_label.text = RunState.party.get_companion_summary()
	else:
		equipment_label.text = "%s\n\n%s" % [RunState.party.get_companion_summary(), "\n".join(PackedStringArray(equipped_lines))]
	for child in equipment_box.get_children():
		child.queue_free()
	if RunState.equipment.owned_items.is_empty():
		equipment_status_label.text = "No equipment carried."
		return
	equipment_status_label.text = "Inventory"
	for instance in RunState.equipment.owned_items:
		var data := RunState.equipment.get_data_for_instance(instance)
		var button := Button.new()
		button.custom_minimum_size = Vector2(132, 62)
		button.text = "%s\n%s" % [
			data.get("name", "Equipment"),
			data.get("slot", "?"),
		]
		UIStyleScript.style_card_button(button)
		button.pressed.connect(_on_equipment_pressed.bind(int(instance.get("instance_id", 0))))
		equipment_box.add_child(button)


func _on_equipment_pressed(instance_id: int) -> void:
	equipment_status_label.text = RunState.equipment.equip_cycle(instance_id)
	_refresh_equipment()
