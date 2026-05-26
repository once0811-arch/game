extends Control

const CompanionRewardGeneratorScript := preload("res://scripts/rewards/companion_reward_generator.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")

var generator = CompanionRewardGeneratorScript.new()
var status_label: Label
var option_box: HBoxContainer


func _ready() -> void:
	_build_ui()
	_populate_options()


func _build_ui() -> void:
	UIStyleScript.add_background(self, "bg_event_act1_generic", 0.74)
	var root := UIStyleScript.page_root(self, 38)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	root.add_child(layout)

	var title := UIStyleScript.label("Companion Contract", 34)
	layout.add_child(title)

	status_label = UIStyleScript.label("", 18, UIStyleScript.MUTED)
	status_label.text = "Choose one companion to sign the token."
	layout.add_child(status_label)

	option_box = HBoxContainer.new()
	option_box.add_theme_constant_override("separation", 14)
	option_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var option_panel := UIStyleScript.panel(option_box, Vector2(0, 330))
	layout.add_child(option_panel)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	layout.add_child(actions)

	var map_button := Button.new()
	map_button.text = "Map"
	map_button.custom_minimum_size = Vector2(120, 44)
	UIStyleScript.style_button(map_button)
	map_button.pressed.connect(Callable(SceneRouter, "go_to_map"))
	actions.add_child(map_button)


func _populate_options() -> void:
	for child in option_box.get_children():
		child.queue_free()
	var options := generator.generate_options(int(DataRegistry.get_balance("rewards.companion_options", 3)))
	if options.is_empty():
		status_label.text = "No companion can be recruited right now."
		var continue_button := Button.new()
		continue_button.text = "Continue"
		continue_button.custom_minimum_size = Vector2(180, 58)
		UIStyleScript.style_button(continue_button, "primary")
		continue_button.pressed.connect(_on_continue_without_recruitment)
		option_box.add_child(continue_button)
		return
	for companion in options:
		option_box.add_child(_make_companion_card(companion))


func _make_companion_card(companion: Dictionary) -> PanelContainer:
	var companion_id := String(companion.get("id", ""))
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 8)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(270, 300)
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UIStyleScript.style_asset_panel(panel, "primary", true, false)
	panel.gui_input.connect(_on_companion_card_input.bind(companion_id))
	panel.add_child(content)

	var portrait := TextureRect.new()
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.custom_minimum_size = Vector2(0, 124)
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = DataRegistry.get_temp_asset_texture(String(companion.get("portrait_asset_id", "")))
	content.add_child(portrait)

	var name := UIStyleScript.label(String(companion.get("name", "?")), 22, UIStyleScript.TEXT)
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(name)

	var role := UIStyleScript.label(String(companion.get("role", "")), 14, UIStyleScript.MUTED)
	role.mouse_filter = Control.MOUSE_FILTER_IGNORE
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(role)

	var stats := UIStyleScript.label("Basic attack %d  |  Oaths %d" % [
		int(companion.get("base_attack", 0)),
		Array(companion.get("oath_tactics", [])).size(),
	], 14, UIStyleScript.GOLD)
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(stats)

	var hint := UIStyleScript.label("Choose this contractor", 13, UIStyleScript.GREEN)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(hint)
	return panel


func _on_companion_card_input(event: InputEvent, companion_id: String) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_on_companion_pressed(companion_id)


func _on_companion_pressed(companion_id: String) -> void:
	CompanionManager.select_companion(companion_id)
	SceneRouter.open_oath_tactic_select()


func _on_continue_without_recruitment() -> void:
	CompanionManager.complete_without_recruitment()
	SceneRouter.go_to_map()


func _contract_panel_style(border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.060, 0.054, 0.045, 0.96)
	style.border_color = border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.shadow_color = Color(0, 0, 0, 0.48)
	style.shadow_size = 9
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = 14
	style.content_margin_top = 12
	style.content_margin_right = 14
	style.content_margin_bottom = 12
	return style
