extends Control

const CardDataScript := preload("res://scripts/data/card_data.gd")
const CompanionRewardGeneratorScript := preload("res://scripts/rewards/companion_reward_generator.gd")

var generator = CompanionRewardGeneratorScript.new()
var status_label: Label
var option_box: HBoxContainer
var confirm_button: Button
var continue_button: Button
var card_options: Array[Dictionary] = []


func _ready() -> void:
	_build_ui()
	_populate_cards()
	_refresh()


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
	title.text = "Choose Companion Cards"
	title.add_theme_font_size_override("font_size", 34)
	layout.add_child(title)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(status_label)

	option_box = HBoxContainer.new()
	option_box.add_theme_constant_override("separation", 12)
	layout.add_child(option_box)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	layout.add_child(actions)

	confirm_button = Button.new()
	confirm_button.text = "Sign Contract"
	confirm_button.pressed.connect(_on_confirm_pressed)
	actions.add_child(confirm_button)

	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.visible = false
	continue_button.pressed.connect(Callable(SceneRouter, "go_to_map"))
	actions.add_child(continue_button)


func _populate_cards() -> void:
	card_options = generator.get_card_options(CompanionManager.selected_companion_id)
	for child in option_box.get_children():
		child.queue_free()
	for card in card_options:
		option_box.add_child(_make_card_button(card))


func _refresh() -> void:
	var companion := DataRegistry.get_companion(CompanionManager.selected_companion_id)
	var picks := int(DataRegistry.get_balance("rewards.companion_card_picks", 2))
	status_label.text = "%s joins with %d of these cards. Selected %d/%d." % [
		String(companion.get("name", "Companion")),
		picks,
		CompanionManager.selected_card_ids.size(),
		picks,
	]
	confirm_button.disabled = not CompanionManager.can_finalize()
	for child in option_box.get_children():
		if child is Button:
			var card_id := String(child.get_meta("card_id", ""))
			child.button_pressed = CompanionManager.selected_card_ids.has(card_id)


func _make_card_button(card: Dictionary) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(190, 132)
	button.set_meta("card_id", String(card.get("id", "")))
	button.text = "%s [%d]\n%s\n%s" % [
		CardDataScript.card_name(card),
		CardDataScript.card_cost(card),
		CardDataScript.card_type(card),
		CardDataScript.card_rules_text(card),
	]
	button.pressed.connect(_on_card_pressed.bind(String(card.get("id", ""))))
	return button


func _on_card_pressed(card_id: String) -> void:
	CompanionManager.toggle_card(card_id)
	_refresh()


func _on_confirm_pressed() -> void:
	if not CompanionManager.finalize_recruitment():
		status_label.text = "Contract could not be signed."
		return
	for child in option_box.get_children():
		child.queue_free()
	status_label.text = "Contract signed. Companion cards were added to discard."
	confirm_button.visible = false
	continue_button.visible = true
