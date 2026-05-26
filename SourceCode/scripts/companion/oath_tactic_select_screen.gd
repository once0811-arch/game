extends Control

var status_label: Label
var option_box: VBoxContainer


func _ready() -> void:
	_build_ui()
	_populate_options()


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.035, 0.035, 0.04, 1.0)
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
	title.text = "Choose Oath Tactic"
	title.add_theme_font_size_override("font_size", 34)
	layout.add_child(title)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(status_label)

	option_box = VBoxContainer.new()
	option_box.add_theme_constant_override("separation", 10)
	layout.add_child(option_box)


func _populate_options() -> void:
	var companion := DataRegistry.get_companion(CompanionManager.selected_companion_id)
	if companion.is_empty():
		status_label.text = "No companion selected."
		return
	status_label.text = "%s offers three oath tactics. Choose one; it will not upgrade." % String(companion.get("name", "Companion"))
	for oath in companion.get("oath_tactics", []):
		if typeof(oath) == TYPE_DICTIONARY:
			option_box.add_child(_make_oath_button(oath))


func _make_oath_button(oath: Dictionary) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 76)
	button.text = "%s\n%s" % [String(oath.get("name", "?")), String(oath.get("rules_text", ""))]
	button.pressed.connect(_on_oath_pressed.bind(String(oath.get("id", ""))))
	return button


func _on_oath_pressed(oath_id: String) -> void:
	CompanionManager.select_oath(oath_id)
	SceneRouter.open_companion_card_select()
