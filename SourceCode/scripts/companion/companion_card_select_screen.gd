extends Control

const CompanionRewardGeneratorScript := preload("res://scripts/rewards/companion_reward_generator.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
const CombatCardViewScript := preload("res://scripts/ui/combat_card_view.gd")

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
	UIStyleScript.add_background(self, "bg_event_act1_generic", 0.78)
	var root := UIStyleScript.page_root(self, 38)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	root.add_child(layout)

	var title := UIStyleScript.label("Choose Companion Cards", 34)
	layout.add_child(title)

	status_label = UIStyleScript.label("", 18, UIStyleScript.MUTED)
	layout.add_child(status_label)

	option_box = HBoxContainer.new()
	option_box.add_theme_constant_override("separation", 14)
	option_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var option_panel := UIStyleScript.panel(option_box, Vector2(0, 260))
	layout.add_child(option_panel)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	layout.add_child(actions)

	confirm_button = Button.new()
	confirm_button.text = "Sign Contract"
	confirm_button.custom_minimum_size = Vector2(160, 44)
	UIStyleScript.style_button(confirm_button, "primary")
	confirm_button.pressed.connect(_on_confirm_pressed)
	actions.add_child(confirm_button)

	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.visible = false
	continue_button.custom_minimum_size = Vector2(150, 44)
	UIStyleScript.style_button(continue_button, "primary")
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
		var card_id := String(child.get_meta("card_id", ""))
		if not card_id.is_empty() and child.has_method("setup"):
			var card := DataRegistry.get_card(card_id)
			child.setup(card, {}, int(child.get("hand_index")), true, CompanionManager.selected_card_ids.has(card_id))


func _make_card_button(card: Dictionary) -> Control:
	var view := CombatCardViewScript.new()
	var card_id := String(card.get("id", ""))
	view.set_meta("card_id", card_id)
	view.setup(card, {}, option_box.get_child_count(), true, CompanionManager.selected_card_ids.has(card_id))
	view.card_pressed.connect(_on_card_view_pressed.bind(card_id))
	return view


func _on_card_view_pressed(_hand_index: int, card_id: String) -> void:
	_on_card_pressed(card_id)


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
