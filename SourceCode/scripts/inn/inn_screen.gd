extends Control

const InnRoomGeneratorScript := preload("res://scripts/systems/inn_room_generator.gd")
const EventResolverScript := preload("res://scripts/systems/event_resolver.gd")

var room_generator = InnRoomGeneratorScript.new()
var event_resolver = EventResolverScript.new()
var inn_data: Dictionary = {}
var status_label: Label
var run_label: Label
var room_box: HBoxContainer
var continue_button: Button


func _ready() -> void:
	if not RunState.is_run_active:
		RunState.start_new_run()
	inn_data = room_generator.generate_rooms()
	_build_ui()
	_refresh()


func _build_ui() -> void:
	var background := TextureRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var bg_asset := "bg_inn_act1_suspicious" if String(inn_data.get("type", "")) == "event" else "bg_inn_act1_warm_common"
	var bg_path := DataRegistry.get_temp_asset_path(bg_asset)
	if not bg_path.is_empty():
		background.texture = load(bg_path)
	add_child(background)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.03, 0.026, 0.022, 0.62)
	add_child(shade)

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 40)
	root.add_theme_constant_override("margin_top", 34)
	root.add_theme_constant_override("margin_right", 40)
	root.add_theme_constant_override("margin_bottom", 34)
	add_child(root)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	root.add_child(layout)

	var title := Label.new()
	title.text = String(inn_data.get("title", "Inn"))
	title.add_theme_font_size_override("font_size", 34)
	layout.add_child(title)

	run_label = Label.new()
	run_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(run_label)

	room_box = HBoxContainer.new()
	room_box.add_theme_constant_override("separation", 12)
	layout.add_child(room_box)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.modulate = Color(0.86, 0.88, 0.80)
	layout.add_child(status_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	layout.add_child(actions)

	var leave := Button.new()
	leave.text = "Leave"
	leave.pressed.connect(_on_leave_pressed)
	actions.add_child(leave)

	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.visible = false
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
	button.custom_minimum_size = Vector2(230, 132)
	button.text = "%s\n%d Gold\n%s" % [
		room.get("name", "Room"),
		price,
		room.get("description", ""),
	]
	button.disabled = RunState.gold < price
	button.pressed.connect(_on_room_pressed.bind(index))
	return button


func _on_room_pressed(index: int) -> void:
	var rooms: Array = inn_data.get("rooms", [])
	if index < 0 or index >= rooms.size():
		return
	var room: Dictionary = rooms[index]
	var price := int(room.get("price", 0))
	if RunState.gold < price:
		status_label.text = "Not enough gold."
		return
	RunState.gold -= price
	var logs := ["Paid %d gold for %s." % [price, room.get("name", "Room")]]
	logs.append_array(event_resolver.apply_effects(room.get("effects", [])))
	RunTelemetry.record_inn_room(String(inn_data.get("type", "")), String(room.get("id", "")), price)
	status_label.text = "\n".join(PackedStringArray(logs))
	_complete_node()
	for child in room_box.get_children():
		child.queue_free()
	continue_button.visible = true
	run_label.text = "HP %d/%d | Gold %d" % [RunState.current_hp, RunState.max_hp, RunState.gold]


func _on_leave_pressed() -> void:
	_complete_node()
	SceneRouter.go_to_map()


func _complete_node() -> void:
	if MapState.has_selected_node() and MapState.get_selected_node_type() == "inn":
		MapState.complete_selected_node()
