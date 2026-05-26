extends Control

const CardDataScript := preload("res://scripts/data/card_data.gd")
const RewardGeneratorScript := preload("res://scripts/systems/card_reward_generator.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
const CombatCardViewScript := preload("res://scripts/ui/combat_card_view.gd")

var reward_generator = RewardGeneratorScript.new()
var reward_options: Array[Dictionary] = []
var reward_box: HBoxContainer
var status_label: Label
var continue_button: Button
var skip_button: Button


func _ready() -> void:
	_build_ui()
	_generate_rewards()


func _build_ui() -> void:
	UIStyleScript.add_background(self, "bg_event_act1_generic", 0.72)
	var root := UIStyleScript.page_root(self, 38)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	root.add_child(layout)

	var title := UIStyleScript.label("Choose a Reward", 34)
	layout.add_child(title)

	status_label = UIStyleScript.label("", 18, UIStyleScript.MUTED)
	status_label.text = "Choose one card or take gold."
	layout.add_child(status_label)

	reward_box = HBoxContainer.new()
	reward_box.add_theme_constant_override("separation", 14)
	reward_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var reward_panel := UIStyleScript.panel(reward_box, Vector2(0, 240))
	layout.add_child(reward_panel)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	layout.add_child(actions)

	skip_button = Button.new()
	skip_button.text = "Take %d Gold" % reward_generator.get_skip_gold()
	skip_button.icon = DataRegistry.get_temp_asset_texture("icon_gold")
	skip_button.custom_minimum_size = Vector2(150, 44)
	UIStyleScript.style_button(skip_button)
	skip_button.pressed.connect(_on_skip_pressed)
	actions.add_child(skip_button)

	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.custom_minimum_size = Vector2(150, 44)
	UIStyleScript.style_button(continue_button, "primary")
	continue_button.pressed.connect(Callable(SceneRouter, "go_to_map"))
	continue_button.visible = false
	actions.add_child(continue_button)


func _generate_rewards() -> void:
	reward_options = reward_generator.generate_options(int(DataRegistry.get_balance("rewards.card_options", 3)))
	for child in reward_box.get_children():
		child.queue_free()
	for i in range(reward_options.size()):
		reward_box.add_child(_make_reward_button(reward_options[i], i))


func _make_reward_button(card: Dictionary, index: int) -> Control:
	var view := CombatCardViewScript.new()
	view.setup(card, {}, index, true, false)
	view.card_pressed.connect(_on_reward_pressed)
	return view


func _on_reward_pressed(index: int) -> void:
	if index < 0 or index >= reward_options.size():
		return
	var card := reward_options[index]
	RewardState.claim_card(String(card.get("id", "")))
	status_label.text = "Added %s to discard." % CardDataScript.card_name(card)
	for child in reward_box.get_children():
		child.queue_free()
	var chosen := CombatCardViewScript.new()
	chosen.setup(card, {}, 0, true, false)
	reward_box.add_child(chosen)
	skip_button.disabled = true
	continue_button.visible = true


func _on_skip_pressed() -> void:
	var gold := RewardState.skip_card_reward()
	status_label.text = "Gained %d gold." % gold
	for child in reward_box.get_children():
		child.queue_free()
	reward_box.add_child(_make_gold_reward_panel(gold))
	skip_button.disabled = true
	continue_button.visible = true


func _make_gold_reward_panel(gold: int) -> PanelContainer:
	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 10)
	var panel := UIStyleScript.panel(layout, Vector2(230, 210), true)
	UIStyleScript.style_asset_panel(panel, "primary", true, false)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(86, 86)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = DataRegistry.get_temp_asset_texture("icon_gold")
	layout.add_child(icon)
	var label := UIStyleScript.label("+%d Gold" % gold, 24, UIStyleScript.GOLD)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(label)
	return panel
