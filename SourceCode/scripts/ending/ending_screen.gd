extends Control


func _ready() -> void:
	RunState.run_complete = true
	RunState.phase_note = "The core is broken. The road back is finally real."
	RunTelemetry.record_run_complete()
	_build_ui()


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.018, 0.020, 0.024, 1.0)
	add_child(shade)

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 48)
	root.add_theme_constant_override("margin_top", 42)
	root.add_theme_constant_override("margin_right", 48)
	root.add_theme_constant_override("margin_bottom", 42)
	add_child(root)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	root.add_child(layout)

	var title := Label.new()
	title.text = "The Core Breaks"
	title.add_theme_font_size_override("font_size", 38)
	layout.add_child(title)

	var summary := Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_font_size_override("font_size", 20)
	summary.text = "HP %d/%d | Gold %d | Companions %d\n%s" % [
		RunState.current_hp,
		RunState.max_hp,
		RunState.gold,
		RunState.party.get_companion_count(),
		RunState.party.get_companion_summary(),
	]
	layout.add_child(summary)

	var main := Button.new()
	main.text = "Main Menu"
	main.custom_minimum_size = Vector2(220, 44)
	main.pressed.connect(Callable(SceneRouter, "go_to_main"))
	layout.add_child(main)
