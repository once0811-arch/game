extends Control

const CardDataScript := preload("res://scripts/data/card_data.gd")
const CardInstanceScript := preload("res://scripts/state/card_instance.gd")
const TurnManagerScript := preload("res://scripts/combat/turn_manager.gd")
const BondSystemScript := preload("res://scripts/systems/bond_system.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
const CombatCardViewScript := preload("res://scripts/ui/combat_card_view.gd")
const CardPlayRulesScript := preload("res://scripts/combat/card_play_rules.gd")

var turn_manager = TurnManagerScript.new()
var bond_system = BondSystemScript.new()
var log_lines: Array[String] = []

var player_label: Label
var pile_label: Label
var companion_label: Label
var hand_area: Control
var enemy_box: HBoxContainer
var log_label: Label
var end_turn_button: Button
var claim_reward_button: Button
var enemy_controls: Array[Control] = []
var selected_target_index := 0
var selected_card_index := -1
var dragging_card_index := -1
var drag_preview: Label
var target_arc: Line2D
var drag_start_position := Vector2.ZERO


func _ready() -> void:
	_build_ui()
	_restart_combat()


func _build_ui() -> void:
	UIStyleScript.add_background(self, "bg_battle_act1_road_ruin", 0.68)
	var root := UIStyleScript.page_root(self, 24)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	root.add_child(layout)

	target_arc = Line2D.new()
	target_arc.z_index = 60
	target_arc.width = 4.0
	target_arc.default_color = Color(0.96, 0.72, 0.28, 0.88)
	target_arc.begin_cap_mode = Line2D.LINE_CAP_ROUND
	target_arc.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(target_arc)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	layout.add_child(header)

	var title := UIStyleScript.label("Contract Combat", 30)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var battlefield := HBoxContainer.new()
	battlefield.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battlefield.add_theme_constant_override("separation", 14)
	layout.add_child(battlefield)

	var player_box := VBoxContainer.new()
	player_box.add_theme_constant_override("separation", 8)
	var player_panel := UIStyleScript.panel(player_box, Vector2(260, 0), true)
	battlefield.add_child(player_panel)

	var protagonist := TextureRect.new()
	protagonist.custom_minimum_size = Vector2(210, 210)
	protagonist.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	protagonist.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var protagonist_path := DataRegistry.get_temp_asset_path("protagonist_mercenary_idle")
	if not protagonist_path.is_empty():
		protagonist.texture = load(protagonist_path)
	player_box.add_child(protagonist)

	player_label = UIStyleScript.label("", 17)
	player_box.add_child(player_label)

	var stage_box := VBoxContainer.new()
	stage_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_box.add_theme_constant_override("separation", 10)
	var stage_panel := UIStyleScript.panel(stage_box, Vector2(0, 0), true)
	stage_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battlefield.add_child(stage_panel)

	pile_label = UIStyleScript.label("", 15, UIStyleScript.MUTED)
	stage_box.add_child(pile_label)

	companion_label = UIStyleScript.label("", 15, UIStyleScript.GREEN)
	stage_box.add_child(companion_label)

	enemy_box = HBoxContainer.new()
	enemy_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	enemy_box.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_box.add_theme_constant_override("separation", 14)
	stage_box.add_child(enemy_box)

	var log_box := VBoxContainer.new()
	log_box.add_theme_constant_override("separation", 8)
	var log_panel := UIStyleScript.panel(log_box, Vector2(310, 0), true)
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battlefield.add_child(log_panel)

	log_box.add_child(UIStyleScript.label("Battle Log", 18))
	log_label = UIStyleScript.label("", 14, UIStyleScript.MUTED)
	log_box.add_child(log_label)

	hand_area = Control.new()
	hand_area.custom_minimum_size = Vector2(0, 252)
	hand_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(hand_area)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 10)
	layout.add_child(controls)

	end_turn_button = Button.new()
	end_turn_button.text = "End Turn"
	end_turn_button.custom_minimum_size = Vector2(180, 46)
	UIStyleScript.style_button(end_turn_button, "primary")
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	controls.add_child(end_turn_button)

	claim_reward_button = Button.new()
	claim_reward_button.text = "Claim Reward"
	claim_reward_button.custom_minimum_size = Vector2(180, 46)
	UIStyleScript.style_button(claim_reward_button, "success")
	claim_reward_button.pressed.connect(_on_claim_reward_pressed)
	controls.add_child(claim_reward_button)


func _restart_combat() -> void:
	if not RunState.is_run_active:
		RunState.start_new_run()
	log_lines.clear()
	selected_target_index = 0
	selected_card_index = -1
	dragging_card_index = -1
	var default_enemy_id := String(DataRegistry.get_balance("combat.fallback_enemy_id", "enemy_act1_mutated_merchant"))
	var enemy_id := MapState.get_selected_enemy_id(default_enemy_id)
	_append_logs(turn_manager.start_combat(enemy_id))
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
	selected_target_index = _clamp_target_index(selected_target_index)
	_refresh_enemy()
	pile_label.text = "Draw %d | Hand %d | Discard %d | Exhaust %d" % [
		RunState.deck.draw_pile.size(),
		RunState.deck.hand.size(),
		RunState.deck.discard_pile.size(),
		RunState.deck.exhaust_pile.size(),
	]
	_refresh_companions()
	_refresh_hand()
	end_turn_button.disabled = RunState.combat.outcome != "active"
	claim_reward_button.visible = RunState.combat.outcome == "victory"
	log_label.text = "\n".join(PackedStringArray(log_lines))


func _refresh_enemy() -> void:
	UIStyleScript.clear(enemy_box)
	enemy_controls.clear()
	if RunState.combat.enemies.is_empty():
		enemy_box.add_child(UIStyleScript.label("No enemy.", 18, UIStyleScript.MUTED))
		return
	for i in range(RunState.combat.enemies.size()):
		var enemy: Dictionary = RunState.combat.enemies[i]
		var panel := _make_enemy_panel(enemy, i)
		enemy_box.add_child(panel)
		enemy_controls.append(panel)


func _make_enemy_panel(enemy: Dictionary, enemy_index: int) -> PanelContainer:
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 6)
	var panel := UIStyleScript.panel(content, Vector2(176, 284), true)
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.gui_input.connect(_on_enemy_panel_gui_input.bind(enemy_index))
	_style_enemy_panel(panel, enemy_index)

	var portrait := TextureRect.new()
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.custom_minimum_size = Vector2(150, 150)
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var asset_path := DataRegistry.get_temp_asset_path(String(enemy.get("asset_id", "")))
	if not asset_path.is_empty():
		portrait.texture = load(asset_path)
	content.add_child(portrait)

	var statuses: Dictionary = enemy.get("statuses", {})
	var name_label := UIStyleScript.label("%s%s" % [
		"> " if enemy_index == selected_target_index and int(enemy.get("hp", 0)) > 0 else "",
		enemy.get("name", "Enemy"),
	], 16)
	content.add_child(name_label)

	var hp_label := UIStyleScript.label("HP %d/%d  Block %d  Mark %d" % [
		int(enemy.get("hp", 0)),
		int(enemy.get("max_hp", 0)),
		int(enemy.get("block", 0)),
		int(statuses.get("tactical_mark", 0)),
	], 14, UIStyleScript.stat_text())
	content.add_child(hp_label)

	var hp_bar := ProgressBar.new()
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar.custom_minimum_size = Vector2(0, 12)
	hp_bar.min_value = 0
	hp_bar.max_value = max(int(enemy.get("max_hp", 1)), 1)
	hp_bar.value = int(enemy.get("hp", 0))
	hp_bar.show_percentage = false
	hp_bar.add_theme_stylebox_override("background", _bar_style(Color(0.045, 0.040, 0.036, 0.95)))
	hp_bar.add_theme_stylebox_override("fill", _bar_style(Color(0.74, 0.18, 0.15, 0.95)))
	content.add_child(hp_bar)

	var intent: Dictionary = enemy.get("intent", {})
	var intent_text := "Intent: Unknown"
	var intent_kind := "?"
	if String(intent.get("type", "")) == "attack":
		intent_kind = "ATK"
		intent_text = "Intent: %s (%d damage)" % [intent.get("label", "Attack"), int(intent.get("damage", 0))]
	elif String(intent.get("type", "")) == "block":
		intent_kind = "BLK"
		intent_text = "Intent: %s (+%d block)" % [intent.get("label", "Block"), int(intent.get("block", 0))]
	elif String(intent.get("type", "")) == "healing_down":
		intent_kind = "HEX"
		intent_text = "Intent: %s (-%d%% healing)" % [intent.get("label", "Hex"), int(intent.get("percent", 50))]
	if int(enemy.get("hp", 0)) <= 0:
		intent_kind = "KO"
		intent_text = "Defeated"
	var intent_chip := PanelContainer.new()
	intent_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent_chip.add_theme_stylebox_override("panel", _intent_style(String(intent.get("type", ""))))
	var intent_label := UIStyleScript.label("%s  %s" % [intent_kind, intent_text], 13, UIStyleScript.GOLD)
	intent_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent_chip.add_child(intent_label)
	content.add_child(intent_chip)
	return panel


func _refresh_hand() -> void:
	UIStyleScript.clear(hand_area)
	for i in range(RunState.deck.hand.size()):
		var instance: Dictionary = RunState.deck.hand[i]
		var card := DataRegistry.get_card(CardInstanceScript.get_card_id(instance))
		var view := CombatCardViewScript.new()
		view.setup(card, instance, i, _is_card_playable(i), i == selected_card_index)
		view.card_pressed.connect(_on_card_pressed)
		view.card_drag_started.connect(_on_card_drag_started)
		hand_area.add_child(view)
	_layout_hand_cards.call_deferred()


func _on_card_pressed(hand_index: int) -> void:
	if not _is_card_playable(hand_index):
		return
	if not _card_requires_target(hand_index):
		_play_card_at_target(hand_index, -1)
		return
	selected_card_index = hand_index
	_layout_hand_cards()


func _on_card_drag_started(hand_index: int, card_name_text: String) -> void:
	if not _is_card_playable(hand_index):
		return
	selected_card_index = hand_index
	dragging_card_index = hand_index
	drag_start_position = _card_center_for_hand_index(hand_index)
	_show_drag_preview(card_name_text)
	if _card_requires_target(hand_index):
		_update_target_arc()


func _input(event: InputEvent) -> void:
	if dragging_card_index < 0:
		return
	if event is InputEventMouseMotion:
		_move_drag_preview()
		if _card_requires_target(dragging_card_index):
			_update_target_arc()
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			var target_index := _enemy_index_at_position(get_global_mouse_position())
			var hand_index := dragging_card_index
			dragging_card_index = -1
			_clear_drag_preview()
			_clear_target_arc()
			if target_index >= 0:
				_play_card_at_target(hand_index, target_index)
			elif not _card_requires_target(hand_index):
				_play_card_at_target(hand_index, -1)
			else:
				selected_card_index = hand_index
				_refresh()


func _on_enemy_panel_gui_input(event: InputEvent, enemy_index: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_on_enemy_pressed(enemy_index)


func _on_enemy_pressed(enemy_index: int) -> void:
	if not _enemy_can_target(enemy_index):
		return
	selected_target_index = enemy_index
	if selected_card_index >= 0 and _is_card_playable(selected_card_index):
		_play_card_at_target(selected_card_index, enemy_index)
	else:
		_refresh()


func _play_card_at_target(hand_index: int, target_index: int) -> void:
	if not _is_card_playable(hand_index):
		return
	if _card_requires_target(hand_index) and not _enemy_can_target(target_index):
		return
	var played_name := _card_name_for_hand_index(hand_index)
	var feedback_position := _target_feedback_position(target_index)
	selected_target_index = target_index
	selected_card_index = -1
	_append_logs(turn_manager.play_card(hand_index, target_index))
	_spawn_float_text(played_name, feedback_position, UIStyleScript.GOLD)
	_refresh()


func _on_end_turn_pressed() -> void:
	selected_card_index = -1
	dragging_card_index = -1
	_clear_drag_preview()
	_clear_target_arc()
	_append_logs(turn_manager.end_player_turn())
	_refresh()


func _layout_hand_cards() -> void:
	if hand_area == null:
		return
	var cards: Array[Node] = hand_area.get_children()
	var count: int = cards.size()
	if count == 0:
		return
	var card_width: float = 164.0
	var available_width: float = maxf(hand_area.size.x, get_viewport_rect().size.x - 64.0)
	var spread: float = minf(760.0, maxf(0.0, available_width - card_width - 48.0))
	var step: float = 0.0 if count <= 1 else spread / float(count - 1)
	var start_x: float = (available_width - spread - card_width) * 0.5
	for i in range(count):
		var card := cards[i] as Control
		if card == null:
			continue
		var t: float = 0.5 if count <= 1 else float(i) / float(count - 1)
		var curve_y: float = 18.0 + absf(t - 0.5) * 34.0
		var rotation: float = lerpf(-0.085, 0.085, t)
		var target_position := Vector2(start_x + step * i, curve_y)
		if i == selected_card_index:
			target_position.y -= 18.0
		card.rotation = rotation
		card.pivot_offset = Vector2(card_width * 0.5, 112.0)
		var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "position", target_position, 0.16)


func _is_card_playable(hand_index: int) -> bool:
	if RunState.combat.outcome != "active":
		return false
	if hand_index < 0 or hand_index >= RunState.deck.hand.size():
		return false
	var instance: Dictionary = RunState.deck.hand[hand_index]
	var card := DataRegistry.get_card(CardInstanceScript.get_card_id(instance))
	return CardDataScript.card_cost(card) <= RunState.combat.energy


func _card_requires_target(hand_index: int) -> bool:
	if hand_index < 0 or hand_index >= RunState.deck.hand.size():
		return false
	var instance: Dictionary = RunState.deck.hand[hand_index]
	var card := DataRegistry.get_card(CardInstanceScript.get_card_id(instance))
	return CardPlayRulesScript.requires_enemy_target(card)


func _card_name_for_hand_index(hand_index: int) -> String:
	if hand_index < 0 or hand_index >= RunState.deck.hand.size():
		return ""
	var instance: Dictionary = RunState.deck.hand[hand_index]
	var card := DataRegistry.get_card(CardInstanceScript.get_card_id(instance))
	return CardDataScript.card_name(card)


func _card_center_for_hand_index(hand_index: int) -> Vector2:
	for child in hand_area.get_children():
		if child.get("hand_index") != null and int(child.get("hand_index")) == hand_index:
			var card := child as Control
			return card.global_position + Vector2(82, 112)
	return get_global_mouse_position()


func _enemy_can_target(enemy_index: int) -> bool:
	if RunState.combat.outcome != "active":
		return false
	if enemy_index < 0 or enemy_index >= RunState.combat.enemies.size():
		return false
	var enemy: Dictionary = RunState.combat.enemies[enemy_index]
	return int(enemy.get("hp", 0)) > 0


func _enemy_index_at_position(global_position: Vector2) -> int:
	for i in range(enemy_controls.size()):
		var control := enemy_controls[i]
		if control.get_global_rect().has_point(global_position) and _enemy_can_target(i):
			return i
	return -1


func _target_feedback_position(target_index: int) -> Vector2:
	if target_index >= 0 and target_index < enemy_controls.size():
		var control := enemy_controls[target_index]
		return control.global_position + control.size * 0.5
	return get_global_mouse_position()


func _clamp_target_index(target_index: int) -> int:
	if RunState.combat.enemies.is_empty():
		return 0
	if target_index >= 0 and target_index < RunState.combat.enemies.size():
		var current: Dictionary = RunState.combat.enemies[target_index]
		if int(current.get("hp", 0)) > 0:
			return target_index
	for i in range(RunState.combat.enemies.size()):
		var enemy: Dictionary = RunState.combat.enemies[i]
		if int(enemy.get("hp", 0)) > 0:
			return i
	return 0


func _show_drag_preview(card_name: String) -> void:
	_clear_drag_preview()
	drag_preview = UIStyleScript.label(card_name, 17, UIStyleScript.GOLD)
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.z_index = 50
	add_child(drag_preview)
	_move_drag_preview()


func _move_drag_preview() -> void:
	if drag_preview == null:
		return
	drag_preview.global_position = get_global_mouse_position() + Vector2(14, 14)


func _clear_drag_preview() -> void:
	if drag_preview == null:
		return
	drag_preview.queue_free()
	drag_preview = null


func _update_target_arc() -> void:
	if target_arc == null:
		return
	target_arc.clear_points()
	var start := drag_start_position
	var target := get_global_mouse_position()
	var distance := target - start
	for i in range(8):
		var t := float(i) / 8.0
		var point := Vector2(
			start.x + distance.x * t,
			start.y + (1.0 - pow(1.0 - t, 3.0)) * distance.y
		)
		target_arc.add_point(point)
	target_arc.add_point(target)


func _clear_target_arc() -> void:
	if target_arc != null:
		target_arc.clear_points()


func _spawn_float_text(text: String, global_position: Vector2, color: Color) -> void:
	if text.is_empty():
		return
	var label := UIStyleScript.label(text, 20, color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 80
	label.global_position = global_position - Vector2(48, 16)
	add_child(label)
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "global_position", label.global_position + Vector2(0, -42), 0.42)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.42)
	tween.finished.connect(label.queue_free)


func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


func _intent_style(intent_type: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	match intent_type:
		"attack":
			style.bg_color = Color(0.28, 0.08, 0.06, 0.92)
			style.border_color = UIStyleScript.RED
		"block":
			style.bg_color = Color(0.07, 0.17, 0.15, 0.92)
			style.border_color = UIStyleScript.GREEN
		"healing_down":
			style.bg_color = Color(0.17, 0.11, 0.24, 0.92)
			style.border_color = Color(0.48, 0.32, 0.62, 1.0)
		_:
			style.bg_color = Color(0.10, 0.09, 0.08, 0.90)
			style.border_color = UIStyleScript.BORDER
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 8
	style.content_margin_top = 5
	style.content_margin_right = 8
	style.content_margin_bottom = 5
	return style


func _style_enemy_panel(panel: PanelContainer, enemy_index: int) -> void:
	var style := StyleBoxFlat.new()
	var alive := _enemy_can_target(enemy_index)
	style.bg_color = Color(0.085, 0.075, 0.065, 0.93)
	style.border_color = UIStyleScript.BORDER
	if enemy_index == selected_target_index and alive:
		style.bg_color = Color(0.16, 0.105, 0.055, 0.96)
		style.border_color = UIStyleScript.BORDER_BRIGHT
	elif not alive:
		style.bg_color = Color(0.045, 0.045, 0.045, 0.84)
		style.border_color = Color(0.16, 0.16, 0.15, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)


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
	var source := "map_combat" if MapState.has_selected_node() else "combat_fallback"
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
