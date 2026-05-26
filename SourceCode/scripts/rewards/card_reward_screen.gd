extends Control

const CardDataScript := preload("res://scripts/data/card_data.gd")
const RewardGeneratorScript := preload("res://scripts/systems/card_reward_generator.gd")

var reward_generator = RewardGeneratorScript.new()
var reward_options: Array[Dictionary] = []
var reward_box: HBoxContainer
var status_label: Label
var continue_button: Button


func _ready() -> void:
	_build_ui()
	_generate_rewards()


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
	shade.color = Color(0.035, 0.035, 0.04, 0.72)
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
	title.text = "Card Reward"
	title.add_theme_font_size_override("font_size", 34)
	layout.add_child(title)

	status_label = Label.new()
	status_label.text = "Choose one card or take gold."
	status_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(status_label)

	reward_box = HBoxContainer.new()
	reward_box.add_theme_constant_override("separation", 12)
	layout.add_child(reward_box)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	layout.add_child(actions)

	var skip := Button.new()
	skip.text = "Skip (+%d Gold)" % reward_generator.get_skip_gold()
	skip.pressed.connect(_on_skip_pressed)
	actions.add_child(skip)

	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.pressed.connect(Callable(SceneRouter, "go_to_map"))
	continue_button.visible = false
	actions.add_child(continue_button)


func _generate_rewards() -> void:
	reward_options = reward_generator.generate_options(int(DataRegistry.get_balance("rewards.card_options", 3)))
	for child in reward_box.get_children():
		child.queue_free()
	for i in range(reward_options.size()):
		reward_box.add_child(_make_reward_button(reward_options[i], i))


func _make_reward_button(card: Dictionary, index: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(190, 132)
	button.text = "%s [%d]\n%s\n%s" % [
		CardDataScript.card_name(card),
		CardDataScript.card_cost(card),
		CardDataScript.card_rarity(card),
		CardDataScript.card_rules_text(card),
	]
	button.pressed.connect(_on_reward_pressed.bind(index))
	return button


func _on_reward_pressed(index: int) -> void:
	if index < 0 or index >= reward_options.size():
		return
	var card := reward_options[index]
	RewardState.claim_card(String(card.get("id", "")))
	status_label.text = "Added %s to discard." % CardDataScript.card_name(card)
	for child in reward_box.get_children():
		child.queue_free()
	continue_button.visible = true


func _on_skip_pressed() -> void:
	var gold := RewardState.skip_card_reward()
	status_label.text = "Gained %d gold." % gold
	for child in reward_box.get_children():
		child.queue_free()
	continue_button.visible = true
