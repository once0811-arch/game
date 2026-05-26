extends Control

var status_label: Label
var continue_button: Button


func _ready() -> void:
	_build_ui()
	_refresh_status()


func _build_ui() -> void:
	var background := TextureRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var bg_path := DataRegistry.get_temp_asset_path("bg_battle_act1_road_ruin")
	if not bg_path.is_empty():
		background.texture = load(bg_path)
	add_child(background)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.04, 0.05, 0.06, 0.68)
	add_child(shade)

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 48)
	root.add_theme_constant_override("margin_top", 38)
	root.add_theme_constant_override("margin_right", 48)
	root.add_theme_constant_override("margin_bottom", 34)
	add_child(root)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 28)
	root.add_child(columns)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(430, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 14)
	columns.add_child(left)

	var title := Label.new()
	title.text = "Deckbuilder Prototype"
	title.add_theme_font_size_override("font_size", 42)
	left.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "A road through a collapsing fantasy world"
	subtitle.modulate = Color(0.82, 0.86, 0.84)
	subtitle.add_theme_font_size_override("font_size", 16)
	left.add_child(subtitle)

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

	var new_run := _make_menu_button("New Run")
	new_run.pressed.connect(_on_new_run_pressed)
	menu.add_child(new_run)

	continue_button = _make_menu_button("Continue")
	continue_button.pressed.connect(_on_continue_pressed)
	menu.add_child(continue_button)

	var gallery := _make_menu_button("Asset Gallery")
	gallery.pressed.connect(Callable(SceneRouter, "open_asset_gallery"))
	menu.add_child(gallery)

	var deck_debug := _make_menu_button("Deck Debug")
	deck_debug.pressed.connect(Callable(SceneRouter, "open_deck_debug"))
	menu.add_child(deck_debug)

	var combat_test := _make_menu_button("Combat Test")
	combat_test.pressed.connect(Callable(SceneRouter, "open_combat_test"))
	menu.add_child(combat_test)

	var quit := _make_menu_button("Quit")
	quit.pressed.connect(_on_quit_pressed)
	menu.add_child(quit)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.modulate = Color(0.73, 0.78, 0.76)
	left.add_child(status_label)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	columns.add_child(right)

	var build_label := Label.new()
	build_label.text = "The Ruined Road"
	build_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	build_label.add_theme_font_size_override("font_size", 24)
	right.add_child(build_label)

	var summary := Label.new()
	summary.text = "The first contract begins at the camp. The keep waits beyond the broken route."
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.modulate = Color(0.80, 0.84, 0.82)
	right.add_child(summary)

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


func _make_menu_button(label_text: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(260, 42)
	button.focus_mode = Control.FOCUS_NONE
	return button


func _refresh_status() -> void:
	continue_button.disabled = not SaveService.has_save()
	var data_state := "ready" if DataRegistry.is_ready_for_phase_7() else "missing"
	status_label.text = "Data: %s | Cards: %d | Companions: %d | Enemies: %d | Equipment: %d | Temp assets: %d | Save: %s" % [
		data_state,
		DataRegistry.get_card_count(),
		DataRegistry.get_companion_count(),
		DataRegistry.get_enemy_count(),
		DataRegistry.get_equipment_count(),
		DataRegistry.get_temp_asset_count(),
		"found" if SaveService.has_save() else "none",
	]
	if not DataRegistry.load_errors.is_empty():
		for error in DataRegistry.load_errors:
			status_label.text += "\n" + error


func _on_new_run_pressed() -> void:
	SceneRouter.start_new_run()


func _on_continue_pressed() -> void:
	var snapshot := SaveService.read_run_snapshot()
	if not RunState.load_snapshot(snapshot):
		_refresh_status()
		status_label.text += "\nCould not load save snapshot."
		return
	var map_snapshot: Dictionary = snapshot.get("map", {})
	MapState.from_snapshot(map_snapshot)
	SceneRouter.go_to_map()


func _on_quit_pressed() -> void:
	get_tree().quit()
