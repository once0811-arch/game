extends Control

const UIStyleScript := preload("res://scripts/ui/ui_style.gd")

var status_label: Label
var continue_button: Button


func _ready() -> void:
	_build_ui()
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

	var title := UIStyleScript.label("The Ruined Road", 44)
	left.add_child(title)

	var subtitle := UIStyleScript.label("Survival deckbuilding through a dying fantasy world", 17, UIStyleScript.MUTED)
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

	var quit := _make_menu_button("Quit")
	quit.pressed.connect(_on_quit_pressed)
	menu.add_child(quit)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", UIStyleScript.MUTED)
	left.add_child(status_label)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	columns.add_child(right)

	var build_label := UIStyleScript.label("Blood Tags. Broken Roads. One Contract Left.", 24)
	build_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(build_label)

	var summary := UIStyleScript.label("", 16, UIStyleScript.MUTED)
	summary.text = "The first contract begins at the camp. The keep waits beyond the broken route."
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
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
	button.custom_minimum_size = Vector2(280, 46)
	UIStyleScript.style_button(button, "primary" if label_text in ["New Run", "Continue"] else "default")
	return button


func _refresh_status() -> void:
	continue_button.disabled = not SaveService.has_save()
	var data_state := "Ready" if DataRegistry.is_ready_for_phase_8() else "Missing data"
	status_label.text = "%s | Cards %d | Companions %d | Enemies %d | Equipment %d | Assets %d | Save %s" % [
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
