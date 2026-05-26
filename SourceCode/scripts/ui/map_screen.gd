extends Control

const UIStyleScript := preload("res://scripts/ui/ui_style.gd")

var run_label: Label
var map_canvas: Control
var map_log_label: Label
var legend_box: VBoxContainer
var equipment_label: Label
var equipment_box: HBoxContainer
var equipment_status_label: Label
var node_buttons: Dictionary = {}
var dragging_node_id := ""

const MAP_NODE_SIZE := Vector2(46, 46)


func _ready() -> void:
	if RunState.is_run_active:
		MapState.ensure_current_act()
	_build_ui()
	_refresh()


func _build_ui() -> void:
	UIStyleScript.add_background(self, "bg_map_act1_route", 0.46)

	var top_bar := PanelContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 58
	top_bar.add_theme_stylebox_override("panel", _map_top_style())
	add_child(top_bar)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	top_bar.add_child(header)

	var title := UIStyleScript.label("Act %d" % RunState.act, 24)
	title.custom_minimum_size = Vector2(110, 0)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title)

	run_label = UIStyleScript.label("", 16, UIStyleScript.TEXT)
	run_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	run_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(run_label)

	var save_button := Button.new()
	save_button.text = "Save"
	save_button.custom_minimum_size = Vector2(92, 42)
	save_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UIStyleScript.style_button(save_button, "primary")
	save_button.pressed.connect(_on_save_pressed)
	header.add_child(save_button)

	var main := Button.new()
	main.text = "Menu"
	main.custom_minimum_size = Vector2(92, 42)
	main.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UIStyleScript.style_button(main)
	main.pressed.connect(Callable(SceneRouter, "go_to_main"))
	header.add_child(main)

	var route_layout := VBoxContainer.new()
	route_layout.add_theme_constant_override("separation", 10)
	var map_area := UIStyleScript.panel(route_layout, Vector2(0, 0))
	_style_route_panel(map_area)
	map_area.anchor_left = 0.10
	map_area.anchor_top = 0.10
	map_area.anchor_right = 0.84
	map_area.anchor_bottom = 0.94
	map_area.offset_left = 0
	map_area.offset_top = 0
	map_area.offset_right = 0
	map_area.offset_bottom = 0
	add_child(map_area)

	map_canvas = Control.new()
	map_canvas.custom_minimum_size = Vector2(760, 520)
	map_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_canvas.clip_contents = true
	map_canvas.resized.connect(_on_map_canvas_resized)
	route_layout.add_child(map_canvas)

	map_log_label = UIStyleScript.label("", 14, UIStyleScript.stat_text())
	map_log_label.custom_minimum_size = Vector2(0, 28)
	map_log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	route_layout.add_child(map_log_label)

	legend_box = VBoxContainer.new()
	legend_box.add_theme_constant_override("separation", 7)
	var legend_panel := UIStyleScript.panel(legend_box, Vector2(206, 320), true)
	legend_panel.anchor_left = 1.0
	legend_panel.anchor_top = 0.18
	legend_panel.anchor_right = 1.0
	legend_panel.anchor_bottom = 0.18
	legend_panel.offset_left = -236
	legend_panel.offset_top = 0
	legend_panel.offset_right = -28
	legend_panel.offset_bottom = 320
	legend_panel.add_theme_stylebox_override("panel", _legend_scroll_style())
	add_child(legend_panel)
	_build_legend()

	equipment_label = Label.new()
	equipment_box = HBoxContainer.new()
	equipment_status_label = Label.new()


func _build_legend() -> void:
	if legend_box == null:
		return
	UIStyleScript.clear(legend_box)
	legend_box.add_child(UIStyleScript.label("Legend", 20, Color(0.08, 0.12, 0.12, 1.0)))
	for entry in [
		["combat", "Fight"],
		["elite", "Elite"],
		["midboss", "Midboss"],
		["boss", "Boss"],
		["event", "Unknown"],
		["inn", "Camp"],
		["shop", "Shop"],
		["companion_contract", "Ally Contract"],
		["upgrade", "Upgrade"],
	]:
		legend_box.add_child(_make_legend_row(String(entry[0]), String(entry[1])))


func _make_legend_row(node_type: String, label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)

	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon_path := DataRegistry.get_temp_asset_path(_node_icon_asset_id(node_type))
	if not icon_path.is_empty():
		icon.texture = load(icon_path)
	icon.modulate = _node_accent_color(node_type, "available")
	row.add_child(icon)

	var label := UIStyleScript.label(label_text, 14, Color(0.08, 0.10, 0.10, 1.0))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.custom_minimum_size = Vector2(170, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	row.add_child(label)
	return row


func _map_top_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.050, 0.070, 0.075, 0.78)
	style.border_color = Color(0.18, 0.24, 0.25, 0.92)
	style.border_width_bottom = 2
	style.shadow_color = Color(0, 0, 0, 0.42)
	style.shadow_size = 8
	style.content_margin_left = 18
	style.content_margin_top = 8
	style.content_margin_right = 18
	style.content_margin_bottom = 8
	return style


func _legend_scroll_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.78, 0.84, 0.82, 0.92)
	style.border_color = Color(0.38, 0.48, 0.48, 0.96)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
	style.content_margin_left = 14
	style.content_margin_top = 12
	style.content_margin_right = 14
	style.content_margin_bottom = 12
	return style


func _style_route_panel(panel_node: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.66, 0.64, 0.52, 0.91)
	style.border_color = Color(0.30, 0.24, 0.15, 0.98)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0, 0, 0, 0.48)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
	style.content_margin_left = 24
	style.content_margin_top = 18
	style.content_margin_right = 24
	style.content_margin_bottom = 18
	panel_node.add_theme_stylebox_override("panel", style)


func _refresh_run_info() -> void:
	if not RunState.is_run_active:
		run_label.text = "No active run. Return to Main Menu and start a new run."
		return
	run_label.text = "Floor %d/12    HP %d/%d    Gold %d" % [
		MapState.current_depth,
		RunState.current_hp,
		RunState.max_hp,
		RunState.gold,
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
	map_log_label.text = "Choose the next contract."
	_draw_route_lines()
	for node in MapState.nodes:
		var button := _make_node_button(node)
		button.position = _node_position(node)
		map_canvas.add_child(button)
		node_buttons[String(node.get("id", ""))] = {
			"button": button,
			"state": MapState.get_node_state(node),
		}


func _on_map_canvas_resized() -> void:
	if map_canvas == null or map_canvas.get_child_count() == 0:
		return
	_refresh_nodes.call_deferred()


func _make_node_button(node: Dictionary) -> Button:
	var button := Button.new()
	var state := MapState.get_node_state(node)
	var node_type := String(node.get("type", "?"))
	button.custom_minimum_size = MAP_NODE_SIZE
	button.size = MAP_NODE_SIZE
	button.text = ""
	button.tooltip_text = _describe_node(node)
	var icon_path := DataRegistry.get_temp_asset_path(_node_icon_asset_id(node_type))
	if not icon_path.is_empty():
		button.icon = load(icon_path)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.disabled = state != "available"
	_style_map_node_button(button, node_type, state)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.gui_input.connect(_on_node_button_gui_input.bind(String(node.get("id", "")), state))
	button.mouse_entered.connect(_on_node_hovered.bind(node))
	button.mouse_exited.connect(_on_node_unhovered)
	return button


func _input(event: InputEvent) -> void:
	if dragging_node_id.is_empty():
		return
	if event is InputEventMouseMotion:
		map_log_label.text = "Release on a lit token."
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
			map_log_label.text = "Holding contract token."


func _on_node_hovered(node: Dictionary) -> void:
	map_log_label.text = _describe_node(node)


func _on_node_unhovered() -> void:
	if dragging_node_id.is_empty():
		map_log_label.text = "Choose the next contract."


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
	var by_id: Dictionary = {}
	for node in MapState.nodes:
		by_id[String(node.get("id", ""))] = node
	for from_node in MapState.nodes:
		for next_id in _node_next_ids(from_node):
			if not by_id.has(next_id):
				continue
			var to_node: Dictionary = by_id[next_id]
			_add_dashed_line(
				_node_position(from_node) + MAP_NODE_SIZE * 0.5,
				_node_position(to_node) + MAP_NODE_SIZE * 0.5,
				_line_color(from_node, to_node)
			)


func _node_position(node: Dictionary) -> Vector2:
	var depth := int(node.get("depth", 1))
	var lane := int(node.get("lane", 1))
	var canvas_size := Vector2(840, 472)
	if map_canvas != null:
		canvas_size = Vector2(
			maxf(map_canvas.size.x, map_canvas.custom_minimum_size.x),
			maxf(map_canvas.size.y, map_canvas.custom_minimum_size.y)
		)
	var side_margin: float = maxf(110.0, canvas_size.x * 0.14)
	var x_positions := [
		side_margin,
		canvas_size.x * 0.5,
		canvas_size.x - side_margin,
	]
	var x := float(x_positions[clampi(lane, 0, 2)])
	var jitter := sin(float(depth) * 1.73 + float(lane) * 2.31) * canvas_size.x * 0.038
	if lane == 1:
		jitter *= 0.52
	x += jitter
	var y_margin := 30.0
	var usable_height := maxf(420.0, canvas_size.y - 92.0)
	var depth_count := 12.0
	var climb_index := depth_count - float(depth)
	var y := y_margin + climb_index * (usable_height / maxf(depth_count - 1.0, 1.0))
	return Vector2(x, y)


func _node_next_ids(node: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for next_id in node.get("next_ids", []):
		var id_text := String(next_id)
		if not id_text.is_empty():
			ids.append(id_text)
	return ids


func _add_dashed_line(start: Vector2, end: Vector2, color: Color) -> void:
	var delta := end - start
	var distance := delta.length()
	if distance <= 1.0:
		return
	var direction := delta / distance
	var dash := 8.0
	var gap := 7.0
	var cursor := 0.0
	while cursor < distance:
		var segment_end := minf(cursor + dash, distance)
		var line := Line2D.new()
		line.width = 3.0 if color.a >= 0.78 else 1.5
		line.default_color = color
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.add_point(start + direction * cursor)
		line.add_point(start + direction * segment_end)
		map_canvas.add_child(line)
		cursor += dash + gap


func _line_color(from_node: Dictionary, to_node: Dictionary) -> Color:
	var from_state := MapState.get_node_state(from_node)
	var to_state := MapState.get_node_state(to_node)
	if from_state == "completed" and to_state == "available":
		return Color(0.96, 0.62, 0.24, 0.90)
	if from_state == "completed":
		return Color(0.48, 0.54, 0.46, 0.60)
	return Color(0.10, 0.12, 0.12, 0.34)


func _style_map_node_button(button: Button, node_type: String, state: String) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 31)
	button.add_theme_color_override("icon_normal_color", _node_accent_color(node_type, state))
	button.add_theme_color_override("icon_hover_color", Color.WHITE)
	button.add_theme_color_override("icon_pressed_color", Color.WHITE)
	button.add_theme_color_override("icon_disabled_color", _node_accent_color(node_type, state))
	button.add_theme_stylebox_override("normal", _node_button_style(node_type, state, false))
	button.add_theme_stylebox_override("hover", _node_button_style(node_type, state, true))
	button.add_theme_stylebox_override("pressed", _node_button_style(node_type, state, true))
	button.add_theme_stylebox_override("disabled", _node_button_style(node_type, state, false))


func _node_button_style(node_type: String, state: String, hover: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var accent := _node_accent_color(node_type, state)
	var bg := Color(0.055, 0.052, 0.046, 0.94)
	var border := Color(0.14, 0.14, 0.13, 0.90)
	var shadow := 5
	if state == "available":
		bg = accent.darkened(0.52)
		border = accent.lightened(0.25)
		shadow = 9
	elif state == "completed":
		bg = Color(0.10, 0.18, 0.13, 0.94)
		border = UIStyleScript.GREEN
	else:
		bg = Color(0.045, 0.045, 0.042, 0.70)
		border = Color(0.12, 0.12, 0.11, 0.72)
	if hover and state == "available":
		bg = accent.darkened(0.34)
		border = Color.WHITE
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 21
	style.corner_radius_top_right = 21
	style.corner_radius_bottom_left = 21
	style.corner_radius_bottom_right = 21
	style.shadow_color = Color(0, 0, 0, 0.52)
	style.shadow_size = shadow
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 6
	style.content_margin_top = 6
	style.content_margin_right = 6
	style.content_margin_bottom = 6
	return style


func _node_accent_color(node_type: String, state: String = "available") -> Color:
	var color := UIStyleScript.BLUE
	match node_type:
		"combat":
			color = Color(0.52, 0.66, 0.72, 1.0)
		"elite":
			color = Color(0.88, 0.25, 0.19, 1.0)
		"midboss":
			color = Color(0.82, 0.43, 0.17, 1.0)
		"boss":
			color = Color(0.92, 0.66, 0.20, 1.0)
		"inn":
			color = Color(0.49, 0.78, 0.55, 1.0)
		"shop":
			color = Color(0.92, 0.70, 0.26, 1.0)
		"event":
			color = Color(0.56, 0.64, 0.76, 1.0)
		"upgrade":
			color = Color(0.48, 0.76, 0.70, 1.0)
		"companion_contract":
			color = Color(0.76, 0.50, 0.90, 1.0)
	if state == "locked":
		return Color(0.45, 0.45, 0.42, 0.58)
	if state == "completed":
		return UIStyleScript.GREEN
	return color


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


func _node_icon_asset_id(node_type: String) -> String:
	match node_type:
		"combat":
			return "node_combat"
		"elite":
			return "node_elite"
		"midboss":
			return "node_mid_boss"
		"boss":
			return "node_boss"
		"inn":
			return "node_inn"
		"shop":
			return "node_shop"
		"event":
			return "node_event"
		"upgrade":
			return "node_upgrade"
		"companion_contract":
			return "node_companion_contract"
		_:
			return "node_event"


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
