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
	var option_panel := UIStyleScript.panel(option_box, Vector2(0, 190))
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
		option_box.add_child(_make_companion_button(companion))


func _make_companion_button(companion: Dictionary) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(250, 160)
	button.text = "%s\n%s\nOath tactics: %d" % [
		String(companion.get("name", "?")),
		String(companion.get("role", "")),
		Array(companion.get("oath_tactics", [])).size(),
	]
	UIStyleScript.style_card_button(button, "primary")
	button.pressed.connect(_on_companion_pressed.bind(String(companion.get("id", ""))))
	return button


func _on_companion_pressed(companion_id: String) -> void:
	CompanionManager.select_companion(companion_id)
	SceneRouter.open_oath_tactic_select()


func _on_continue_without_recruitment() -> void:
	CompanionManager.complete_without_recruitment()
	SceneRouter.go_to_map()
