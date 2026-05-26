extends Control

const CardDataScript := preload("res://scripts/data/card_data.gd")
const CardInstanceScript := preload("res://scripts/state/card_instance.gd")
const TurnManagerScript := preload("res://scripts/combat/turn_manager.gd")
const BondSystemScript := preload("res://scripts/systems/bond_system.gd")

var turn_manager = TurnManagerScript.new()
var bond_system = BondSystemScript.new()
var log_lines: Array[String] = []

var player_label: Label
var enemy_label: Label
var intent_label: Label
var pile_label: Label
var companion_label: Label
var hand_box: HBoxContainer
var log_label: Label
var claim_reward_button: Button
var enemy_texture: TextureRect


func _ready() -> void:
	_build_ui()
	_restart_combat()


func _build_ui() -> void:
	var background := TextureRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var bg_path := DataRegistry.get_temp_asset_path("bg_battle_act1_road_ruin")
	if not bg_path.is_empty():
		background.texture = load(bg_path)
	add_child(background)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.03, 0.035, 0.04, 0.55)
	add_child(shade)

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 28)
	root.add_theme_constant_override("margin_top", 22)
	root.add_theme_constant_override("margin_right", 28)
	root.add_theme_constant_override("margin_bottom", 20)
	add_child(root)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	root.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	layout.add_child(header)

	var title := Label.new()
	title.text = "Combat Test"
	title.add_theme_font_size_override("font_size", 30)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var restart := Button.new()
	restart.text = "Restart"
	restart.pressed.connect(_restart_combat)
	header.add_child(restart)

	var deck_debug := Button.new()
	deck_debug.text = "Deck Debug"
	deck_debug.pressed.connect(Callable(SceneRouter, "open_deck_debug"))
	header.add_child(deck_debug)

	var map := Button.new()
	map.text = "Map"
	map.pressed.connect(Callable(SceneRouter, "go_to_map"))
	header.add_child(map)

	var battlefield := HBoxContainer.new()
	battlefield.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battlefield.add_theme_constant_override("separation", 28)
	layout.add_child(battlefield)

	var player_box := VBoxContainer.new()
	player_box.custom_minimum_size = Vector2(240, 0)
	player_box.add_theme_constant_override("separation", 8)
	battlefield.add_child(player_box)

	var protagonist := TextureRect.new()
	protagonist.custom_minimum_size = Vector2(180, 180)
	protagonist.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	protagonist.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var protagonist_path := DataRegistry.get_temp_asset_path("protagonist_mercenary_idle")
	if not protagonist_path.is_empty():
		protagonist.texture = load(protagonist_path)
	player_box.add_child(protagonist)

	player_label = Label.new()
	player_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	player_label.add_theme_font_size_override("font_size", 18)
	player_box.add_child(player_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battlefield.add_child(spacer)

	var enemy_box := VBoxContainer.new()
	enemy_box.custom_minimum_size = Vector2(280, 0)
	enemy_box.add_theme_constant_override("separation", 8)
	battlefield.add_child(enemy_box)

	enemy_texture = TextureRect.new()
	enemy_texture.custom_minimum_size = Vector2(220, 220)
	enemy_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	enemy_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	enemy_box.add_child(enemy_texture)

	enemy_label = Label.new()
	enemy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enemy_label.add_theme_font_size_override("font_size", 18)
	enemy_box.add_child(enemy_label)

	intent_label = Label.new()
	intent_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intent_label.modulate = Color(0.92, 0.78, 0.58)
	enemy_box.add_child(intent_label)

	pile_label = Label.new()
	pile_label.add_theme_font_size_override("font_size", 16)
	layout.add_child(pile_label)

	companion_label = Label.new()
	companion_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	companion_label.modulate = Color(0.78, 0.88, 0.82)
	layout.add_child(companion_label)

	hand_box = HBoxContainer.new()
	hand_box.add_theme_constant_override("separation", 8)
	layout.add_child(hand_box)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	layout.add_child(controls)

	var end_turn := Button.new()
	end_turn.text = "End Turn"
	end_turn.pressed.connect(_on_end_turn_pressed)
	controls.add_child(end_turn)

	claim_reward_button = Button.new()
	claim_reward_button.text = "Claim Reward"
	claim_reward_button.pressed.connect(_on_claim_reward_pressed)
	controls.add_child(claim_reward_button)

	var log_panel := PanelContainer.new()
	log_panel.custom_minimum_size = Vector2(0, 128)
	layout.add_child(log_panel)

	log_label = Label.new()
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_panel.add_child(log_label)


func _restart_combat() -> void:
	if not RunState.is_run_active:
		RunState.start_new_run()
	log_lines.clear()
	var default_enemy_id := String(DataRegistry.get_balance("combat.debug_enemy_id", "enemy_act1_mutated_merchant"))
	var enemy_id := MapState.get_selected_enemy_id(default_enemy_id)
	_append_logs(turn_manager.start_debug_combat(enemy_id))
	_refresh()


func _refresh() -> void:
	player_label.text = "HP %d/%d | Block %d | Energy %d/%d | Turn %d" % [
		RunState.current_hp,
		RunState.max_hp,
		RunState.combat.player_block,
		RunState.combat.energy,
		RunState.combat.max_energy,
		RunState.combat.turn_index,
	]
	if RunState.combat.healing_reduction_turns > 0:
		player_label.text += "\nHealing Down %d%% / %d turns" % [
			RunState.combat.healing_reduction_percent,
			RunState.combat.healing_reduction_turns,
		]
	_refresh_enemy()
	pile_label.text = "Draw %d | Hand %d | Discard %d | Exhaust %d" % [
		RunState.deck.draw_pile.size(),
		RunState.deck.hand.size(),
		RunState.deck.discard_pile.size(),
		RunState.deck.exhaust_pile.size(),
	]
	_refresh_companions()
	_refresh_hand()
	claim_reward_button.visible = RunState.combat.outcome == "victory"
	log_label.text = "\n".join(PackedStringArray(log_lines))


func _refresh_enemy() -> void:
	if RunState.combat.enemies.is_empty():
		enemy_label.text = "No enemy."
		intent_label.text = ""
		return
	var enemy: Dictionary = RunState.combat.enemies[0]
	var asset_path := DataRegistry.get_temp_asset_path(String(enemy.get("asset_id", "")))
	if not asset_path.is_empty():
		enemy_texture.texture = load(asset_path)
	var statuses: Dictionary = enemy.get("statuses", {})
	enemy_label.text = "%s\nHP %d/%d | Block %d | Mark %d" % [
		enemy.get("name", "Enemy"),
		int(enemy.get("hp", 0)),
		int(enemy.get("max_hp", 0)),
		int(enemy.get("block", 0)),
		int(statuses.get("tactical_mark", 0)),
	]
	var intent: Dictionary = enemy.get("intent", {})
	if String(intent.get("type", "")) == "attack":
		intent_label.text = "Intent: %s (%d damage)" % [intent.get("label", "Attack"), int(intent.get("damage", 0))]
	elif String(intent.get("type", "")) == "block":
		intent_label.text = "Intent: %s (+%d block)" % [intent.get("label", "Block"), int(intent.get("block", 0))]
	else:
		intent_label.text = "Intent: Unknown"


func _refresh_hand() -> void:
	for child in hand_box.get_children():
		child.queue_free()
	for i in range(RunState.deck.hand.size()):
		var instance: Dictionary = RunState.deck.hand[i]
		var card := DataRegistry.get_card(CardInstanceScript.get_card_id(instance))
		hand_box.add_child(_make_card_button(card, instance, i))


func _make_card_button(card: Dictionary, instance: Dictionary, hand_index: int) -> Button:
	var button := Button.new()
	var cost := CardDataScript.card_cost(card)
	var upgraded_suffix := "+" if bool(instance.get("upgraded", false)) else ""
	button.custom_minimum_size = Vector2(150, 124)
	button.text = "%s%s [%d]\n%s\n%s" % [
		CardDataScript.card_name(card),
		upgraded_suffix,
		cost,
		CardDataScript.card_type(card),
		CardDataScript.card_rules_text(card),
	]
	button.disabled = cost > RunState.combat.energy or RunState.combat.outcome != "active"
	button.pressed.connect(_on_card_pressed.bind(hand_index))
	return button


func _on_card_pressed(hand_index: int) -> void:
	_append_logs(turn_manager.play_card(hand_index, 0))
	_refresh()


func _on_end_turn_pressed() -> void:
	_append_logs(turn_manager.end_player_turn())
	_refresh()


func _on_claim_reward_pressed() -> void:
	if MapState.has_selected_node() and MapState.get_selected_node_type() == "boss":
		if RunState.act == 1:
			CompanionManager.begin_recruitment("map_boss")
			SceneRouter.open_companion_reward()
		elif RunState.act == 2:
			UpgradeState.begin_upgrade("act2_boss")
			SceneRouter.open_upgrade_select()
		else:
			MapState.complete_selected_node()
			SceneRouter.open_ending()
		return
	var source := "map_combat" if MapState.has_selected_node() else "debug_combat"
	RewardState.begin_card_reward(source)
	SceneRouter.open_card_reward()


func _append_logs(messages: Array[String]) -> void:
	for message in messages:
		log_lines.append(message)
	while log_lines.size() > 12:
		log_lines.pop_front()


func _refresh_companions() -> void:
	if RunState.party.companions.is_empty():
		companion_label.text = "Companions: none"
		return
	var parts: Array[String] = []
	for companion in RunState.party.companions:
		parts.append("%s / %s / %s" % [
			String(companion.get("name", "?")),
			String(companion.get("oath_name", "No Oath")),
			bond_system.describe_bonuses(companion),
		])
	companion_label.text = "Companions: " + " | ".join(PackedStringArray(parts))
