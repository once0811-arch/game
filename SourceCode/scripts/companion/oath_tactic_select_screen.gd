extends Control

const UIStyleScript := preload("res://scripts/ui/ui_style.gd")

var status_label: Label
var companion_header: HBoxContainer
var option_box: VBoxContainer


func _ready() -> void:
	_build_ui()
	_populate_options()


func _build_ui() -> void:
	UIStyleScript.add_background(self, "bg_event_act1_generic", 0.78)
	var root := UIStyleScript.page_root(self, 38)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	root.add_child(layout)

	var title := UIStyleScript.label("Choose Oath Tactic", 34)
	layout.add_child(title)

	status_label = UIStyleScript.label("", 18, UIStyleScript.MUTED)
	layout.add_child(status_label)

	var content_layout := VBoxContainer.new()
	content_layout.add_theme_constant_override("separation", 12)
	var content_panel := UIStyleScript.panel(content_layout, Vector2(0, 420), true)
	content_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	layout.add_child(content_panel)

	companion_header = HBoxContainer.new()
	companion_header.custom_minimum_size = Vector2(0, 102)
	companion_header.add_theme_constant_override("separation", 12)
	content_layout.add_child(companion_header)

	option_box = VBoxContainer.new()
	option_box.add_theme_constant_override("separation", 12)
	option_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	content_layout.add_child(option_box)


func _populate_options() -> void:
	var companion := DataRegistry.get_companion(CompanionManager.selected_companion_id)
	if companion.is_empty():
		status_label.text = "No companion selected."
		return
	status_label.text = "Choose one fixed contract clause. It will not upgrade or reroll."
	_populate_companion_header(companion)
	for oath in companion.get("oath_tactics", []):
		if typeof(oath) == TYPE_DICTIONARY:
			option_box.add_child(_make_oath_card(oath))


func _populate_companion_header(companion: Dictionary) -> void:
	UIStyleScript.clear(companion_header)
	var portrait := TextureRect.new()
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.custom_minimum_size = Vector2(82, 82)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = DataRegistry.get_temp_asset_texture(String(companion.get("portrait_asset_id", "")))
	companion_header.add_child(portrait)

	var text_box := VBoxContainer.new()
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 3)
	companion_header.add_child(text_box)

	var name := UIStyleScript.label("%s signs by blood." % String(companion.get("name", "Companion")), 22)
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(name)

	var role := UIStyleScript.label(String(companion.get("role", "")), 15, UIStyleScript.MUTED)
	role.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(role)

	var stat := UIStyleScript.label("Basic attack %d. Pick exactly one oath tactic for this run." % int(companion.get("base_attack", 0)), 14, UIStyleScript.GOLD)
	stat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(stat)


func _make_oath_card(oath: Dictionary) -> PanelContainer:
	var oath_id := String(oath.get("id", ""))
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 5)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 92)
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.add_theme_stylebox_override("panel", _oath_panel_style())
	panel.gui_input.connect(_on_oath_card_input.bind(oath_id))
	panel.add_child(content)

	var title := UIStyleScript.label(String(oath.get("name", "?")), 20, UIStyleScript.GOLD)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title)

	var rules := UIStyleScript.label(String(oath.get("rules_text", "")), 15, UIStyleScript.TEXT)
	rules.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(rules)
	return panel


func _on_oath_card_input(event: InputEvent, oath_id: String) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_on_oath_pressed(oath_id)


func _on_oath_pressed(oath_id: String) -> void:
	CompanionManager.select_oath(oath_id)
	SceneRouter.open_companion_card_select()


func _oath_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.068, 0.058, 0.046, 0.96)
	style.border_color = UIStyleScript.BORDER_BRIGHT
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0, 0, 0, 0.42)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 14
	style.content_margin_top = 10
	style.content_margin_right = 14
	style.content_margin_bottom = 10
	return style
