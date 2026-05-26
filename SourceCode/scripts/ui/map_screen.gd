extends Control

const UIStyleScript := preload("res://scripts/ui/ui_style.gd")

var run_label: Label
var map_canvas: Control
var map_log_label: Label
var equipment_label: Label
var equipment_box: HBoxContainer
var equipment_status_label: Label
var node_buttons: Dictionary = {}
var dragging_node_id := ""


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

	map_canvas = Control.new()
	map_canvas.custom_minimum_size = Vector2(820, 430)
	map_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	route_layout.add_child(map_canvas)

	map_log_label = UIStyleScript.label("", 16, UIStyleScript.stat_text())
	route_layout.add_child(map_log_label)

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
	UIStyleScript.clear(map_canvas)
	node_buttons.clear()
	if not RunState.is_run_active:
		map_log_label.text = "Start a new run to generate the Act 1 route."
		return
	MapState.ensure_current_act()
	map_log_label.text = "Click or drag a lit contract token to choose the next route. Depth %d / 12 is open." % MapState.get_available_depth()
	_draw_route_lines()
	for node in MapState.nodes:
		var button := _make_node_button(node)
		button.position = _node_position(node)
		map_canvas.add_child(button)
		node_buttons[String(node.get("id", ""))] = {
			"button": button,
			"state": MapState.get_node_state(node),
		}


func _make_node_button(node: Dictionary) -> Button:
	var button := Button.new()
	var state := MapState.get_node_state(node)
	var prefix := "D%d" % int(node.get("depth", 0))
	var node_type := String(node.get("type", "?"))
	button.custom_minimum_size = Vector2(98, 72)
	button.text = "%s\n%s\n%s" % [prefix, _node_type_label(node_type), String(node.get("label", ""))]
	button.disabled = state != "available"
	if state == "completed":
		button.text = "%s\nCLEARED\n%s" % [prefix, String(node.get("label", ""))]
	elif state == "locked":
		button.text = "%s\nLOCKED\n%s" % [prefix, String(node.get("label", ""))]
	var variant := _node_variant(node_type, state)
	if state == "completed":
		variant = "success"
	UIStyleScript.style_card_button(button, variant)
	button.add_theme_font_size_override("font_size", 13)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.gui_input.connect(_on_node_button_gui_input.bind(String(node.get("id", "")), state))
	button.mouse_entered.connect(_on_node_hovered.bind(node))
	button.mouse_exited.connect(_on_node_unhovered)
	return button


func _input(event: InputEvent) -> void:
	if dragging_node_id.is_empty():
		return
	if event is InputEventMouseMotion:
		map_log_label.text = "Release over a lit contract token to travel."
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			var target_id := _node_id_at_position(get_global_mouse_position())
			if target_id.is_empty():
				target_id = dragging_node_id
			dragging_node_id = ""
			_on_node_pressed(target_id)


func _on_node_button_gui_input(event: InputEvent, node_id: String, state: String) -> void:
	if state != "available":
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			dragging_node_id = node_id
			map_log_label.text = "Holding contract token. Drag to another lit token or release to travel."


func _on_node_hovered(node: Dictionary) -> void:
	map_log_label.text = _describe_node(node)


func _on_node_unhovered() -> void:
	if dragging_node_id.is_empty():
		map_log_label.text = "Click or drag a lit contract token to choose the next route. Depth %d / 12 is open." % MapState.get_available_depth()


func _node_id_at_position(global_position: Vector2) -> String:
	for node_id in node_buttons.keys():
		var record: Dictionary = node_buttons[node_id]
		if String(record.get("state", "")) != "available":
			continue
		var button := record.get("button") as Button
		if button != null and button.get_global_rect().has_point(global_position):
			return String(node_id)
	return ""


func _draw_route_lines() -> void:
	var by_depth: Dictionary = {}
	for node in MapState.nodes:
		var depth := int(node.get("depth", 0))
		if not by_depth.has(depth):
			by_depth[depth] = []
		by_depth[depth].append(node)
	for depth in range(1, 12):
		if not by_depth.has(depth) or not by_depth.has(depth + 1):
			continue
		for from_node in by_depth[depth]:
			for to_node in by_depth[depth + 1]:
				if abs(int(from_node.get("lane", 1)) - int(to_node.get("lane", 1))) > 1:
					continue
				var line := Line2D.new()
				line.width = 3.0
				line.default_color = _line_color(from_node, to_node)
				line.add_point(_node_position(from_node) + Vector2(49, 36))
				line.add_point(_node_position(to_node) + Vector2(49, 36))
				map_canvas.add_child(line)


func _node_position(node: Dictionary) -> Vector2:
	var depth := int(node.get("depth", 1))
	var lane := int(node.get("lane", 1))
	return Vector2(12 + (depth - 1) * 62, 42 + lane * 112)


func _line_color(from_node: Dictionary, to_node: Dictionary) -> Color:
	var from_state := MapState.get_node_state(from_node)
	var to_state := MapState.get_node_state(to_node)
	if from_state == "completed" and to_state == "available":
		return Color(0.90, 0.58, 0.24, 0.82)
	if from_state == "completed":
		return Color(0.48, 0.54, 0.46, 0.60)
	return Color(0.22, 0.22, 0.20, 0.60)


func _node_type_label(node_type: String) -> String:
	match node_type:
		"combat":
			return "FIGHT"
		"elite":
			return "ELITE"
		"midboss":
			return "MID"
		"boss":
			return "BOSS"
		"inn":
			return "REST"
		"shop":
			return "SHOP"
		"event":
			return "EVENT"
		"upgrade":
			return "FORGE"
		"companion_contract":
			return "ALLY"
		_:
			return node_type.to_upper()


func _describe_node(node: Dictionary) -> String:
	var node_type := String(node.get("type", ""))
	var state := MapState.get_node_state(node)
	var parts: Array[String] = [
		"Depth %d %s: %s" % [int(node.get("depth", 0)), _node_type_label(node_type), String(node.get("label", ""))],
		state.to_upper(),
	]
	var enemy_names := _node_enemy_names(node)
	if not enemy_names.is_empty():
		parts.append("Enemies: %s" % ", ".join(PackedStringArray(enemy_names)))
	if node_type in ["elite", "midboss", "boss"]:
		parts.append("High risk, better gold and bond gain.")
	elif node_type == "inn":
		parts.append("Recover and stabilize the run.")
	elif node_type == "shop":
		parts.append("Spend gold on cards, gear, or card removal.")
	elif node_type == "event":
		parts.append("Uncertain contract outcome.")
	elif node_type == "companion_contract":
		parts.append("Recruit a companion and choose one oath tactic.")
	elif node_type == "upgrade":
		parts.append("Strengthen the protagonist or a companion.")
	return "  |  ".join(PackedStringArray(parts))


func _node_enemy_names(node: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for enemy_id in node.get("enemy_ids", []):
		var id_text := String(enemy_id)
		if not id_text.is_empty():
			ids.append(id_text)
	if ids.is_empty():
		var single_id := String(node.get("enemy_id", ""))
		if not single_id.is_empty():
			ids.append(single_id)
	var names: Array[String] = []
	for enemy_id in ids:
		var enemy := DataRegistry.get_enemy(enemy_id)
		names.append(String(enemy.get("name", enemy_id)))
	return names


func _node_variant(node_type: String, state: String) -> String:
	if state == "locked":
		return "locked"
	if node_type in ["elite", "midboss", "boss"]:
		return "danger"
	if node_type in ["inn", "companion_contract", "upgrade"]:
		return "success"
	if node_type == "shop":
		return "primary"
	return "default"


func _on_node_pressed(node_id: String) -> void:
	if not MapState.choose_node(node_id):
		return
	var node_type := MapState.get_selected_node_type()
	if node_type in ["combat", "elite", "midboss", "boss"]:
		SceneRouter.open_combat()
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
