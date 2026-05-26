extends Control

const UIStyleScript := preload("res://scripts/ui/ui_style.gd")

var status_label: Label
var continue_button: Button
var title_label: Label
var subtitle_label: Label
var hook_label: Label
var summary_label: Label
var new_run_button: Button
var settings_button: Button
var quit_button: Button
var settings_overlay: ColorRect
var settings_title_label: Label
var settings_language_label: Label
var settings_hint_label: Label
var korean_button: Button
var english_button: Button
var settings_back_button: Button


func _ready() -> void:
	_build_ui()
	if not SettingsState.language_changed.is_connected(_on_language_changed):
		SettingsState.language_changed.connect(_on_language_changed)
	_refresh_texts()
	_refresh_status()


func _build_ui() -> void:
	UIStyleScript.add_background(self, "bg_battle_act1_road_ruin", 0.70)
	var root := UIStyleScript.page_root(self, 42)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 28)
	root.add_child(columns)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(430, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 14)
	columns.add_child(left)

	title_label = UIStyleScript.label("", 44)
	left.add_child(title_label)

	subtitle_label = UIStyleScript.label("", 17, UIStyleScript.MUTED)
	left.add_child(subtitle_label)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(144, 144)
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var portrait_path := DataRegistry.get_temp_asset_path("protagonist_portrait")
	if not portrait_path.is_empty():
		portrait.texture = load(portrait_path)
	left.add_child(portrait)

	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 8)
	left.add_child(menu)

	new_run_button = _make_menu_button("primary")
	new_run_button.pressed.connect(_on_new_run_pressed)
	menu.add_child(new_run_button)

	continue_button = _make_menu_button("primary")
	continue_button.pressed.connect(_on_continue_pressed)
	menu.add_child(continue_button)

	settings_button = _make_menu_button("blue")
	settings_button.pressed.connect(_on_settings_pressed)
	menu.add_child(settings_button)

	quit_button = _make_menu_button("default")
	quit_button.pressed.connect(_on_quit_pressed)
	menu.add_child(quit_button)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", UIStyleScript.MUTED)
	left.add_child(status_label)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	columns.add_child(right)

	hook_label = UIStyleScript.label("", 24)
	hook_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(hook_label)

	summary_label = UIStyleScript.label("", 16, UIStyleScript.MUTED)
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(summary_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(spacer)

	var token := TextureRect.new()
	token.custom_minimum_size = Vector2(96, 96)
	token.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	token.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var token_path := DataRegistry.get_temp_asset_path("companion_rowan_oath_1")
	if not token_path.is_empty():
		token.texture = load(token_path)
	right.add_child(token)

	_build_settings_overlay()


func _build_settings_overlay() -> void:
	settings_overlay = ColorRect.new()
	settings_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_overlay.color = Color(0.0, 0.0, 0.0, 0.48)
	settings_overlay.visible = false
	settings_overlay.z_index = 20
	add_child(settings_overlay)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	var panel := UIStyleScript.panel(content, Vector2(520, 268), true)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -260
	panel.offset_top = -134
	panel.offset_right = 260
	panel.offset_bottom = 134
	settings_overlay.add_child(panel)

	settings_title_label = UIStyleScript.label("", 30)
	content.add_child(settings_title_label)

	settings_language_label = UIStyleScript.label("", 18, UIStyleScript.GOLD)
	content.add_child(settings_language_label)

	var language_row := HBoxContainer.new()
	language_row.add_theme_constant_override("separation", 10)
	content.add_child(language_row)

	korean_button = Button.new()
	korean_button.custom_minimum_size = Vector2(150, 46)
	korean_button.pressed.connect(_on_language_pressed.bind(SettingsState.LANGUAGE_KO))
	language_row.add_child(korean_button)

	english_button = Button.new()
	english_button.custom_minimum_size = Vector2(150, 46)
	english_button.pressed.connect(_on_language_pressed.bind(SettingsState.LANGUAGE_EN))
	language_row.add_child(english_button)

	settings_hint_label = UIStyleScript.label("", 14, UIStyleScript.MUTED)
	settings_hint_label.custom_minimum_size = Vector2(460, 0)
	content.add_child(settings_hint_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	content.add_child(spacer)

	settings_back_button = Button.new()
	settings_back_button.custom_minimum_size = Vector2(150, 44)
	settings_back_button.pressed.connect(_on_settings_back_pressed)
	UIStyleScript.style_button(settings_back_button, "primary")
	content.add_child(settings_back_button)


func _make_menu_button(variant: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(280, 46)
	UIStyleScript.style_button(button, variant)
	return button


func _refresh_texts() -> void:
	title_label.text = SettingsState.text("main_title")
	subtitle_label.text = SettingsState.text("main_subtitle")
	hook_label.text = SettingsState.text("main_hook")
	summary_label.text = SettingsState.text("main_summary")
	new_run_button.text = SettingsState.text("main_new_run")
	continue_button.text = SettingsState.text("main_continue")
	settings_button.text = SettingsState.text("main_settings")
	quit_button.text = SettingsState.text("main_quit")
	settings_title_label.text = SettingsState.text("settings_title")
	settings_language_label.text = SettingsState.text("settings_language")
	settings_hint_label.text = SettingsState.text("settings_language_hint")
	settings_back_button.text = SettingsState.text("settings_back")
	_refresh_language_buttons()


func _refresh_language_buttons() -> void:
	korean_button.text = SettingsState.language_name(SettingsState.LANGUAGE_KO)
	english_button.text = SettingsState.language_name(SettingsState.LANGUAGE_EN)
	UIStyleScript.style_button(korean_button, "primary" if SettingsState.language_code == SettingsState.LANGUAGE_KO else "default")
	UIStyleScript.style_button(english_button, "primary" if SettingsState.language_code == SettingsState.LANGUAGE_EN else "default")


func _refresh_status() -> void:
	continue_button.disabled = not SaveService.has_save()
	if not DataRegistry.load_errors.is_empty():
		for error in DataRegistry.load_errors:
			push_warning(error)
		status_label.text = SettingsState.text("main_records_missing")
		return
	status_label.text = SettingsState.text("main_saved_contract") if SaveService.has_save() else SettingsState.text("main_no_contract")


func _on_new_run_pressed() -> void:
	SceneRouter.start_new_run()


func _on_continue_pressed() -> void:
	var snapshot := SaveService.read_run_snapshot()
	if not RunState.load_snapshot(snapshot):
		_refresh_status()
		status_label.text += "\n" + SettingsState.text("main_save_load_failed")
		return
	var map_snapshot: Dictionary = snapshot.get("map", {})
	MapState.from_snapshot(map_snapshot)
	SceneRouter.go_to_map()


func _on_settings_pressed() -> void:
	settings_overlay.visible = true
	_refresh_language_buttons()


func _on_settings_back_pressed() -> void:
	settings_overlay.visible = false


func _on_language_pressed(language_code: String) -> void:
	SettingsState.set_language(language_code)


func _on_language_changed(_language_code: String) -> void:
	_refresh_texts()
	_refresh_status()


func _on_quit_pressed() -> void:
	get_tree().quit()
