extends Control

const UIStyleScript := preload("res://scripts/ui/ui_style.gd")

var status_label: Label
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

	option_box = VBoxContainer.new()
	option_box.add_theme_constant_override("separation", 12)
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
	button.custom_minimum_size = Vector2(0, 86)
	button.text = "%s\n%s" % [String(oath.get("name", "?")), String(oath.get("rules_text", ""))]
	UIStyleScript.style_card_button(button, "primary")
	button.pressed.connect(_on_oath_pressed.bind(String(oath.get("id", ""))))
	return button


func _on_oath_pressed(oath_id: String) -> void:
	CompanionManager.select_oath(oath_id)
	SceneRouter.open_companion_card_select()
