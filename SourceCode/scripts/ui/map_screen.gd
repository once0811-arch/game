extends Control

var run_label: Label


func _ready() -> void:
	_build_ui()
	_refresh_run_info()


func _build_ui() -> void:
	var background := TextureRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var bg_path := DataRegistry.get_temp_asset_path("bg_map_act1_route")
	if not bg_path.is_empty():
		background.texture = load(bg_path)
	add_child(background)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.03, 0.035, 0.035, 0.50)
	add_child(shade)

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 42)
	root.add_theme_constant_override("margin_top", 34)
	root.add_theme_constant_override("margin_right", 42)
	root.add_theme_constant_override("margin_bottom", 32)
	add_child(root)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	root.add_child(layout)

	var title := Label.new()
	title.text = "Act 1 Route"
	title.add_theme_font_size_override("font_size", 34)
	layout.add_child(title)

	run_label = Label.new()
	run_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	run_label.modulate = Color(0.86, 0.88, 0.83)
	layout.add_child(run_label)

	var map_area := PanelContainer.new()
	map_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(map_area)

	var map_box := VBoxContainer.new()
	map_box.add_theme_constant_override("separation", 10)
	map_area.add_child(map_box)

	var hint := Label.new()
	hint.text = "The route ahead is still obscured. Only the first camp is reachable."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	map_box.add_child(hint)

	var route := HBoxContainer.new()
	route.alignment = BoxContainer.ALIGNMENT_CENTER
	route.add_theme_constant_override("separation", 16)
	map_box.add_child(route)

	for label_text in ["Start", "Road", "Mid Boss", "Boss"]:
		var node := Button.new()
		node.text = label_text
		node.custom_minimum_size = Vector2(112, 48)
		node.disabled = label_text != "Start"
		route.add_child(node)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	layout.add_child(actions)

	var save_button := Button.new()
	save_button.text = "Save Snapshot"
	save_button.pressed.connect(_on_save_pressed)
	actions.add_child(save_button)

	var gallery := Button.new()
	gallery.text = "Asset Gallery"
	gallery.pressed.connect(Callable(SceneRouter, "open_asset_gallery"))
	actions.add_child(gallery)

	var main := Button.new()
	main.text = "Main Menu"
	main.pressed.connect(Callable(SceneRouter, "go_to_main"))
	actions.add_child(main)


func _refresh_run_info() -> void:
	if not RunState.is_run_active:
		run_label.text = "No active run. Return to Main Menu and start a new run."
		return
	run_label.text = "Seed %d | Act %d | Depth %d | HP %d/%d | Gold %d\n%s" % [
		RunState.run_seed,
		RunState.act,
		RunState.depth,
		RunState.current_hp,
		RunState.max_hp,
		RunState.gold,
		RunState.phase_note,
	]


func _on_save_pressed() -> void:
	SaveService.write_run_snapshot(RunState.to_snapshot())
	_refresh_run_info()
