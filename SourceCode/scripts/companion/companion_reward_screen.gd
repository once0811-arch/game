extends Control

const CompanionRewardGeneratorScript := preload("res://scripts/rewards/companion_reward_generator.gd")

var generator = CompanionRewardGeneratorScript.new()
var status_label: Label
var option_box: HBoxContainer


func _ready() -> void:
	_build_ui()
	_populate_options()


func _build_ui() -> void:
	var background := TextureRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var bg_path := DataRegistry.get_temp_asset_path("bg_event_act1_generic")
	if not bg_path.is_empty():
		background.texture = load(bg_path)
	add_child(background)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.035, 0.035, 0.04, 0.74)
	add_child(shade)

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 42)
	root.add_theme_constant_override("margin_top", 36)
	root.add_theme_constant_override("margin_right", 42)
	root.add_theme_constant_override("margin_bottom", 36)
	add_child(root)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	root.add_child(layout)

	var title := Label.new()
	title.text = "Companion Contract"
	title.add_theme_font_size_override("font_size", 34)
	layout.add_child(title)

	status_label = Label.new()
	status_label.text = "Choose one companion to sign the token."
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(status_label)

	option_box = HBoxContainer.new()
	option_box.add_theme_constant_override("separation", 12)
	layout.add_child(option_box)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	layout.add_child(actions)

	var map_button := Button.new()
	map_button.text = "Map"
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
		continue_button.pressed.connect(_on_continue_without_recruitment)
		option_box.add_child(continue_button)
		return
	for companion in options:
		option_box.add_child(_make_companion_button(companion))


func _make_companion_button(companion: Dictionary) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(210, 150)
	button.text = "%s\n%s\nOath tactics: %d" % [
		String(companion.get("name", "?")),
		String(companion.get("role", "")),
		Array(companion.get("oath_tactics", [])).size(),
	]
	button.pressed.connect(_on_companion_pressed.bind(String(companion.get("id", ""))))
	return button


func _on_companion_pressed(companion_id: String) -> void:
	CompanionManager.select_companion(companion_id)
	SceneRouter.open_oath_tactic_select()


func _on_continue_without_recruitment() -> void:
	CompanionManager.complete_without_recruitment()
	SceneRouter.go_to_map()
