class_name CombatCardView
extends PanelContainer

const CardDataScript := preload("res://scripts/data/card_data.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")

signal card_pressed(hand_index: int)
signal card_drag_started(hand_index: int, card_name: String)

const CARD_SIZE := Vector2(154, 190)

var hand_index := -1
var card_name := ""
var playable := true
var selected := false
var hovered := false
var pressing := false
var dragging := false
var press_origin := Vector2.ZERO


func setup(card: Dictionary, instance: Dictionary, index: int, can_play: bool, is_selected: bool) -> void:
	hand_index = index
	card_name = CardDataScript.card_name(card)
	playable = can_play
	selected = is_selected
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	pivot_offset = CARD_SIZE * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_rebuild(card, instance)


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _gui_input(event: InputEvent) -> void:
	if not playable:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			pressing = true
			dragging = false
			press_origin = get_global_mouse_position()
		elif mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			if pressing and not dragging:
				card_pressed.emit(hand_index)
			pressing = false
			dragging = false
	elif event is InputEventMouseMotion and pressing and not dragging:
		if press_origin.distance_to(get_global_mouse_position()) >= 10.0:
			dragging = true
			card_drag_started.emit(hand_index, card_name)


func _rebuild(card: Dictionary, instance: Dictionary) -> void:
	UIStyleScript.clear(self)
	var card_type := CardDataScript.card_type(card)
	add_theme_stylebox_override("panel", _frame_style(card_type))

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_theme_constant_override("separation", 6)
	margin.add_child(layout)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override("separation", 7)
	layout.add_child(top)

	var cost := UIStyleScript.label(str(CardDataScript.card_cost(card)), 21, Color.WHITE if playable else UIStyleScript.MUTED)
	cost.custom_minimum_size = Vector2(32, 32)
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var cost_wrap := PanelContainer.new()
	cost_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_wrap.custom_minimum_size = Vector2(34, 34)
	cost_wrap.add_theme_stylebox_override("panel", _cost_style(playable))
	cost_wrap.add_child(cost)
	top.add_child(cost_wrap)

	var name_label := UIStyleScript.label("%s%s" % [card_name, "+" if bool(instance.get("upgraded", false)) else ""], 15)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	top.add_child(name_label)

	var art := PanelContainer.new()
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.custom_minimum_size = Vector2(0, 56)
	art.add_theme_stylebox_override("panel", _art_style(card_type))
	layout.add_child(art)

	var art_path := DataRegistry.get_temp_asset_path(String(card.get("asset_id", "")))
	if art_path.is_empty():
		var art_mark := UIStyleScript.label(_type_mark(card_type), 18, Color(1, 1, 1, 0.76))
		art_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		art_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		art.add_child(art_mark)
	else:
		var art_texture := TextureRect.new()
		art_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art_texture.texture = load(art_path)
		art_texture.custom_minimum_size = Vector2(0, 56)
		art_texture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		art_texture.size_flags_vertical = Control.SIZE_EXPAND_FILL
		art_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.add_child(art_texture)

	var type_label := UIStyleScript.label(card_type.to_upper(), 12, UIStyleScript.GOLD)
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(type_label)

	var text := UIStyleScript.label(CardDataScript.card_rules_text(card), 13, UIStyleScript.stat_text() if playable else UIStyleScript.MUTED)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	layout.add_child(text)


func _on_mouse_entered() -> void:
	if hovered or not playable:
		return
	hovered = true
	z_index = 10
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.07, 1.07), 0.12)
	tween.parallel().tween_property(self, "position:y", position.y - 14.0, 0.12)


func _on_mouse_exited() -> void:
	if not hovered:
		return
	hovered = false
	z_index = 0
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)
	tween.parallel().tween_property(self, "position:y", position.y + 14.0, 0.12)


func _frame_style(card_type: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _type_color(card_type)
	style.border_color = UIStyleScript.BORDER_BRIGHT if selected else Color(0.22, 0.18, 0.13, 1.0)
	if not playable:
		style.bg_color = Color(0.055, 0.055, 0.052, 0.92)
		style.border_color = Color(0.18, 0.18, 0.17, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0, 0, 0, 0.58)
	style.shadow_size = 9
	style.shadow_offset = Vector2(0, 4)
	return style


func _cost_style(can_play: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.23, 0.28, 0.96) if can_play else Color(0.09, 0.09, 0.09, 0.94)
	style.border_color = UIStyleScript.BLUE if can_play else Color(0.20, 0.20, 0.19, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 17
	style.corner_radius_top_right = 17
	style.corner_radius_bottom_left = 17
	style.corner_radius_bottom_right = 17
	return style


func _art_style(card_type: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _type_color(card_type).lightened(0.13)
	style.border_color = Color(0.74, 0.58, 0.36, 0.72)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	return style


func _type_color(card_type: String) -> Color:
	match card_type.to_lower():
		"attack":
			return Color(0.34, 0.12, 0.09, 0.98)
		"skill":
			return Color(0.12, 0.24, 0.23, 0.98)
		"power":
			return Color(0.28, 0.20, 0.09, 0.98)
		_:
			return Color(0.14, 0.12, 0.10, 0.98)


func _type_mark(card_type: String) -> String:
	match card_type.to_lower():
		"attack":
			return "BLADE"
		"skill":
			return "WARD"
		"power":
			return "OATH"
		_:
			return "CARD"
