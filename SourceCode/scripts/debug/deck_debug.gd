extends Control

const CardDataScript := preload("res://scripts/data/card_data.gd")
const CardInstanceScript := preload("res://scripts/state/card_instance.gd")
const RewardGeneratorScript := preload("res://scripts/systems/card_reward_generator.gd")

var energy := 0
var max_energy := 0
var log_lines: Array[String] = []
var reward_options: Array[Dictionary] = []
var reward_generator = RewardGeneratorScript.new()

var pile_label: Label
var energy_label: Label
var hand_box: HBoxContainer
var reward_box: HBoxContainer
var log_label: Label


func _ready() -> void:
	_build_ui()
	if not RunState.is_run_active:
		RunState.start_new_run()
	_log("Starting deck created: %d cards." % RunState.deck.get_total_cards())
	_start_turn()
	_generate_reward_options()


func _build_ui() -> void:
	var background := TextureRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var bg_path := DataRegistry.get_temp_asset_path("bg_battle_act1_outpost")
	if not bg_path.is_empty():
		background.texture = load(bg_path)
	add_child(background)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.035, 0.04, 0.045, 0.72)
	add_child(shade)

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 28)
	root.add_theme_constant_override("margin_top", 24)
	root.add_theme_constant_override("margin_right", 28)
	root.add_theme_constant_override("margin_bottom", 24)
	add_child(root)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	root.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	layout.add_child(header)

	var title := Label.new()
	title.text = "Deck Debug"
	title.add_theme_font_size_override("font_size", 30)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var main_button := Button.new()
	main_button.text = "Main Menu"
	main_button.pressed.connect(Callable(SceneRouter, "go_to_main"))
	header.add_child(main_button)

	var map_button := Button.new()
	map_button.text = "Map"
	map_button.pressed.connect(Callable(SceneRouter, "go_to_map"))
	header.add_child(map_button)

	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 14)
	layout.add_child(status)

	energy_label = Label.new()
	energy_label.add_theme_font_size_override("font_size", 18)
	status.add_child(energy_label)

	pile_label = Label.new()
	pile_label.add_theme_font_size_override("font_size", 18)
	status.add_child(pile_label)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	layout.add_child(controls)

	var draw_button := Button.new()
	draw_button.text = "Draw 6"
	draw_button.pressed.connect(_on_draw_pressed)
	controls.add_child(draw_button)

	var end_turn := Button.new()
	end_turn.text = "End Turn"
	end_turn.pressed.connect(_on_end_turn_pressed)
	controls.add_child(end_turn)

	var reward := Button.new()
	reward.text = "Generate Reward"
	reward.pressed.connect(_on_generate_reward_pressed)
	controls.add_child(reward)

	var skip := Button.new()
	skip.text = "Skip Reward (+%d Gold)" % reward_generator.get_skip_gold()
	skip.pressed.connect(_on_skip_reward_pressed)
	controls.add_child(skip)

	var hand_label := Label.new()
	hand_label.text = "Hand"
	hand_label.add_theme_font_size_override("font_size", 20)
	layout.add_child(hand_label)

	hand_box = HBoxContainer.new()
	hand_box.add_theme_constant_override("separation", 8)
	layout.add_child(hand_box)

	var reward_label := Label.new()
	reward_label.text = "Reward Options"
	reward_label.add_theme_font_size_override("font_size", 20)
	layout.add_child(reward_label)

	reward_box = HBoxContainer.new()
	reward_box.add_theme_constant_override("separation", 8)
	layout.add_child(reward_box)

	var log_panel := PanelContainer.new()
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(log_panel)

	log_label = Label.new()
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_panel.add_child(log_label)


func _start_turn() -> void:
	max_energy = int(DataRegistry.get_balance("combat.energy_per_turn", 4))
	energy = max_energy
	var draw_count := int(DataRegistry.get_balance("combat.draw_per_turn", 6))
	var drawn := RunState.deck.draw_cards(draw_count)
	_log("Turn start: drew %d cards." % drawn.size())
	_refresh()


func _refresh() -> void:
	energy_label.text = "Energy %d/%d" % [energy, max_energy]
	pile_label.text = "Draw %d | Hand %d | Discard %d | Exhaust %d | Total %d" % [
		RunState.deck.draw_pile.size(),
		RunState.deck.hand.size(),
		RunState.deck.discard_pile.size(),
		RunState.deck.exhaust_pile.size(),
		RunState.deck.get_total_cards(),
	]
	_refresh_hand()
	_refresh_rewards()
	log_label.text = "\n".join(PackedStringArray(log_lines))


func _refresh_hand() -> void:
	for child in hand_box.get_children():
		child.queue_free()
	for i in range(RunState.deck.hand.size()):
		var instance: Dictionary = RunState.deck.hand[i]
		var card := DataRegistry.get_card(CardInstanceScript.get_card_id(instance))
		hand_box.add_child(_make_card_button(card, i))


func _refresh_rewards() -> void:
	for child in reward_box.get_children():
		child.queue_free()
	for i in range(reward_options.size()):
		var card := reward_options[i]
		var button := _make_reward_button(card, i)
		reward_box.add_child(button)


func _make_card_button(card: Dictionary, hand_index: int) -> Button:
	var button := Button.new()
	var cost := CardDataScript.card_cost(card)
	button.custom_minimum_size = Vector2(154, 128)
	button.text = "%s [%d]\n%s\n%s" % [
		CardDataScript.card_name(card),
		cost,
		CardDataScript.card_type(card),
		CardDataScript.card_rules_text(card),
	]
	button.disabled = cost > energy
	button.pressed.connect(_on_card_pressed.bind(hand_index))
	return button


func _make_reward_button(card: Dictionary, reward_index: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(170, 116)
	button.text = "%s [%d]\n%s\n%s" % [
		CardDataScript.card_name(card),
		CardDataScript.card_cost(card),
		CardDataScript.card_rarity(card),
		CardDataScript.card_rules_text(card),
	]
	button.pressed.connect(_on_reward_pressed.bind(reward_index))
	return button


func _on_card_pressed(hand_index: int) -> void:
	if hand_index < 0 or hand_index >= RunState.deck.hand.size():
		return
	var instance: Dictionary = RunState.deck.hand[hand_index]
	var card := DataRegistry.get_card(CardInstanceScript.get_card_id(instance))
	var cost := CardDataScript.card_cost(card)
	if cost > energy:
		_log("Not enough energy for %s." % CardDataScript.card_name(card))
		return
	energy -= cost
	RunState.deck.play_card(hand_index)
	_log("Played %s for %d energy." % [CardDataScript.card_name(card), cost])
	_refresh()


func _on_draw_pressed() -> void:
	var draw_count := int(DataRegistry.get_balance("combat.draw_per_turn", 6))
	var before_draw: int = RunState.deck.draw_pile.size()
	var before_discard: int = RunState.deck.discard_pile.size()
	var drawn := RunState.deck.draw_cards(draw_count)
	if before_draw == 0 and before_discard > 0:
		_log("Discard shuffled into draw pile.")
	_log("Drew %d cards." % drawn.size())
	_refresh()


func _on_end_turn_pressed() -> void:
	var discarded := RunState.deck.discard_hand()
	_log("Ended turn: discarded %d cards." % discarded)
	_start_turn()


func _on_generate_reward_pressed() -> void:
	_generate_reward_options()


func _on_reward_pressed(reward_index: int) -> void:
	if reward_index < 0 or reward_index >= reward_options.size():
		return
	var card := reward_options[reward_index]
	RunState.deck.add_card_to_discard(String(card.get("id", "")))
	_log("Added reward card: %s." % CardDataScript.card_name(card))
	reward_options.clear()
	_refresh()


func _on_skip_reward_pressed() -> void:
	var gold := reward_generator.get_skip_gold()
	RunState.gold += gold
	reward_options.clear()
	_log("Skipped reward: gained %d gold." % gold)
	_refresh()


func _log(message: String) -> void:
	log_lines.append(message)
	while log_lines.size() > 10:
		log_lines.pop_front()


func _generate_reward_options() -> void:
	reward_options = reward_generator.generate_options(int(DataRegistry.get_balance("rewards.card_options", 3)))
	_log("Generated %d reward options." % reward_options.size())
	_refresh()
