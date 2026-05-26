extends Control

const InnRoomGeneratorScript := preload("res://scripts/systems/inn_room_generator.gd")
const EventResolverScript := preload("res://scripts/systems/event_resolver.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")

var room_generator = InnRoomGeneratorScript.new()
var event_resolver = EventResolverScript.new()
var inn_data: Dictionary = {}
var status_label: Label
var run_label: Label
var room_box: HBoxContainer
var continue_button: Button
var feedback_layer: Control


func _ready() -> void:
	if not RunState.is_run_active:
		RunState.start_new_run()
	inn_data = room_generator.generate_rooms()
	_build_ui()
	_refresh()


func _build_ui() -> void:
	var bg_asset := "bg_inn_act1_suspicious" if String(inn_data.get("type", "")) == "event" else "bg_inn_act1_warm_common"
	UIStyleScript.add_background(self, bg_asset, 0.68)
	var root := UIStyleScript.page_root(self, 36)
	feedback_layer = Control.new()
	feedback_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	feedback_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_layer.z_index = 80
	add_child(feedback_layer)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	root.add_child(layout)

	var title := UIStyleScript.label(String(inn_data.get("title", "Inn")), 34)
	layout.add_child(title)

	run_label = UIStyleScript.label("", 18, UIStyleScript.GOLD)
	layout.add_child(run_label)

	room_box = HBoxContainer.new()
	room_box.add_theme_constant_override("separation", 14)
	var room_panel := UIStyleScript.panel(room_box, Vector2(0, 170))
	layout.add_child(room_panel)

	status_label = UIStyleScript.label("", 16, UIStyleScript.MUTED)
	layout.add_child(status_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	layout.add_child(actions)

	var leave := Button.new()
	leave.text = "Leave"
	leave.custom_minimum_size = Vector2(120, 44)
	UIStyleScript.style_button(leave)
	leave.pressed.connect(_on_leave_pressed)
	actions.add_child(leave)

	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.visible = false
	continue_button.custom_minimum_size = Vector2(150, 44)
	UIStyleScript.style_button(continue_button, "primary")
	continue_button.pressed.connect(Callable(SceneRouter, "go_to_map"))
	actions.add_child(continue_button)


func _refresh() -> void:
	run_label.text = "HP %d/%d | Gold %d" % [RunState.current_hp, RunState.max_hp, RunState.gold]
	for child in room_box.get_children():
		child.queue_free()
	var rooms: Array = inn_data.get("rooms", [])
	for i in range(rooms.size()):
		room_box.add_child(_make_room_button(rooms[i], i))


func _make_room_button(room: Dictionary, index: int) -> Button:
	var button := Button.new()
	var price := int(room.get("price", 0))
	button.custom_minimum_size = Vector2(260, 132)
	button.text = "%s\n%d gold\n%s" % [
		room.get("name", "Room"),
		price,
		room.get("description", ""),
	]
	button.icon = _room_icon(room)
	button.disabled = RunState.gold < price
	UIStyleScript.style_card_button(button, "primary" if not button.disabled else "locked")
	button.pressed.connect(_on_room_pressed.bind(index))
	return button


func _room_icon(room: Dictionary) -> Texture2D:
	var description := String(room.get("description", "")).to_lower()
	if description.find("equipment") >= 0:
		return DataRegistry.get_temp_asset_texture("node_treasure")
	if description.find("recover") >= 0 or description.find("heal") >= 0:
		return DataRegistry.get_temp_asset_texture("icon_heal")
	return DataRegistry.get_temp_asset_texture("node_inn")


func _on_room_pressed(index: int) -> void:
	var rooms: Array = inn_data.get("rooms", [])
	if index < 0 or index >= rooms.size():
		return
	var room: Dictionary = rooms[index]
	var price := int(room.get("price", 0))
	var source_position := _room_center(index)
	if RunState.gold < price:
		status_label.text = "Not enough gold."
		_spawn_inn_feedback("Not enough gold", source_position, UIStyleScript.RED)
		return
	var hp_before: int = RunState.current_hp
	RunState.gold -= price
	var logs: Array[String] = ["Paid %d gold for %s." % [price, room.get("name", "Room")]]
	logs.append_array(event_resolver.apply_effects(room.get("effects", [])))
	var healed: int = max(RunState.current_hp - hp_before, 0)
	RunTelemetry.record_inn_room(String(inn_data.get("type", "")), String(room.get("id", "")), price)
	status_label.text = "\n".join(PackedStringArray(logs))
	_complete_node()
	for child in room_box.get_children():
		child.queue_free()
	continue_button.visible = true
	run_label.text = "HP %d/%d | Gold %d" % [RunState.current_hp, RunState.max_hp, RunState.gold]
	_spawn_room_feedback(String(room.get("name", "Room")), healed, source_position)


func _on_leave_pressed() -> void:
	_complete_node()
	SceneRouter.go_to_map()


func _complete_node() -> void:
	if MapState.has_selected_node() and MapState.get_selected_node_type() == "inn":
		MapState.complete_selected_node()


func _room_center(index: int) -> Vector2:
	if room_box != null and index >= 0 and index < room_box.get_child_count():
		var child := room_box.get_child(index) as Control
		if child != null:
			return child.global_position + child.size * 0.5
	return get_viewport_rect().size * 0.5


func _spawn_room_feedback(room_name: String, healed: int, source_position: Vector2) -> void:
	var message := "Rested\n%s" % room_name
	if healed > 0:
		message += "\n+%d HP" % healed
	_spawn_inn_feedback(message, source_position, UIStyleScript.GREEN)
	_spawn_fire_glow(source_position)


func _spawn_inn_feedback(text: String, source_position: Vector2, color: Color) -> void:
	if feedback_layer == null:
		return
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 90
	panel.custom_minimum_size = Vector2(260, 86)
	panel.size = panel.custom_minimum_size
	panel.add_theme_stylebox_override("panel", _feedback_style(color))
	feedback_layer.add_child(panel)
	var viewport_size := get_viewport_rect().size
	var start_position := Vector2((viewport_size.x - panel.custom_minimum_size.x) * 0.5, 94.0)
	panel.global_position = start_position
	var label := UIStyleScript.label(text, 16, Color.WHITE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.custom_minimum_size = Vector2(248, 76)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	panel.modulate.a = 0.0
	var lift_position := panel.global_position + Vector2(0, -12)
	var exit_position := panel.global_position + Vector2(0, -48)
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.08)
	tween.parallel().tween_property(panel, "global_position", lift_position, 0.16)
	tween.tween_interval(0.42)
	tween.tween_property(panel, "global_position", exit_position, 0.32)
	tween.parallel().tween_property(panel, "modulate:a", 0.0, 0.32)
	tween.finished.connect(panel.queue_free)


func _spawn_fire_glow(source_position: Vector2) -> void:
	if feedback_layer == null:
		return
	var glow := PanelContainer.new()
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.z_index = 84
	glow.custom_minimum_size = Vector2(90, 90)
	glow.size = glow.custom_minimum_size
	glow.add_theme_stylebox_override("panel", _glow_style())
	feedback_layer.add_child(glow)
	glow.global_position = source_position - glow.size * 0.5
	glow.scale = Vector2(0.3, 0.3)
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(glow, "scale", Vector2(1.4, 1.4), 0.34)
	tween.parallel().tween_property(glow, "modulate:a", 0.0, 0.42)
	tween.finished.connect(glow.queue_free)


func _feedback_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.040, 0.033, 0.026, 0.96)
	style.border_color = color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0, 0, 0, 0.52)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	return style


func _glow_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.42, 0.13, 0.24)
	style.border_color = Color(1.0, 0.72, 0.25, 0.62)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 48
	style.corner_radius_top_right = 48
	style.corner_radius_bottom_left = 48
	style.corner_radius_bottom_right = 48
	style.shadow_color = Color(1.0, 0.36, 0.10, 0.36)
	style.shadow_size = 20
	style.shadow_offset = Vector2.ZERO
	return style
