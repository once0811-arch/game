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
var player_hp_bar: ProgressBar
var player_hp_label: Label
var energy_label: Label
var pile_label: Label
var companion_box: HBoxContainer
var hand_area: Control
var enemy_box: HBoxContainer
var log_label: Label
var end_turn_button: Button
var claim_reward_button: Button
var enemy_controls: Array[Control] = []
var feedback_layer: Control
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
	UIStyleScript.add_background(self, "bg_battle_act1_road_ruin", 0.22)

	target_arc = Line2D.new()
	target_arc.z_index = 90
	target_arc.width = 5.0
	target_arc.default_color = Color(1.0, 0.72, 0.24, 0.96)
	target_arc.begin_cap_mode = Line2D.LINE_CAP_ROUND
	target_arc.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(target_arc)

	feedback_layer = Control.new()
	feedback_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	feedback_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_layer.z_index = 90
	add_child(feedback_layer)

	var top_bar := PanelContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 54
	top_bar.add_theme_stylebox_override("panel", _top_hud_style())
	add_child(top_bar)

	var top_content := HBoxContainer.new()
	top_content.add_theme_constant_override("separation", 18)
	top_bar.add_child(top_content)

	var title := UIStyleScript.label("Mercenary", 24)
	title.custom_minimum_size = Vector2(170, 0)
	top_content.add_child(title)

	player_label = UIStyleScript.label("", 17, UIStyleScript.TEXT)
	player_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_content.add_child(player_label)

	pile_label = UIStyleScript.label("", 15, UIStyleScript.GOLD)
	pile_label.custom_minimum_size = Vector2(220, 0)
	pile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pile_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_content.add_child(pile_label)

	var battlefield := Control.new()
	battlefield.set_anchors_preset(Control.PRESET_FULL_RECT)
	battlefield.offset_top = 54
	battlefield.offset_bottom = -190
	add_child(battlefield)

	var floor_shadow := ColorRect.new()
	floor_shadow.anchor_left = 0.0
	floor_shadow.anchor_top = 0.68
	floor_shadow.anchor_right = 1.0
	floor_shadow.anchor_bottom = 1.0
	floor_shadow.color = Color(0.02, 0.018, 0.015, 0.30)
	floor_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battlefield.add_child(floor_shadow)

	var player_box := VBoxContainer.new()
	player_box.anchor_left = 0.075
	player_box.anchor_top = 0.35
	player_box.anchor_right = 0.075
	player_box.anchor_bottom = 0.35
	player_box.offset_left = 0
	player_box.offset_top = 0
	player_box.offset_right = 280
	player_box.offset_bottom = 310
	player_box.custom_minimum_size = Vector2(280, 310)
	player_box.add_theme_constant_override("separation", 8)
	battlefield.add_child(player_box)

	var protagonist := TextureRect.new()
	protagonist.custom_minimum_size = Vector2(250, 230)
	protagonist.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	protagonist.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	protagonist.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	protagonist.texture = DataRegistry.get_temp_asset_texture("protagonist_mercenary_idle")
	player_box.add_child(protagonist)

	player_hp_bar = ProgressBar.new()
	player_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_hp_bar.custom_minimum_size = Vector2(210, 15)
	player_hp_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	player_hp_bar.show_percentage = false
	player_hp_bar.add_theme_stylebox_override("background", _bar_style(Color(0.05, 0.04, 0.04, 0.96)))
	player_hp_bar.add_theme_stylebox_override("fill", _bar_style(Color(0.78, 0.09, 0.08, 0.98)))
	player_box.add_child(player_hp_bar)

	player_hp_label = UIStyleScript.label("", 17, Color.WHITE)
	player_hp_label.custom_minimum_size = Vector2(210, 24)
	player_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_hp_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	player_hp_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	player_box.add_child(player_hp_label)

	companion_box = HBoxContainer.new()
	companion_box.anchor_left = 0.018
	companion_box.anchor_top = 0.055
	companion_box.anchor_right = 0.42
	companion_box.anchor_bottom = 0.055
	companion_box.add_theme_constant_override("separation", 7)
	companion_box.custom_minimum_size = Vector2(320, 54)
	battlefield.add_child(companion_box)

	enemy_box = HBoxContainer.new()
	enemy_box.anchor_left = 0.54
	enemy_box.anchor_top = 0.24
	enemy_box.anchor_right = 0.90
	enemy_box.anchor_bottom = 0.94
	enemy_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	enemy_box.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_box.add_theme_constant_override("separation", 46)
	battlefield.add_child(enemy_box)

	var log_box := VBoxContainer.new()
	log_box.add_theme_constant_override("separation", 6)
	var log_panel := PanelContainer.new()
	log_panel.anchor_left = 0.765
	log_panel.anchor_top = 0.08
	log_panel.anchor_right = 0.985
	log_panel.anchor_bottom = 0.48
	log_panel.add_theme_stylebox_override("panel", _battle_overlay_style(UIStyleScript.BORDER))
	log_panel.add_child(log_box)
	log_panel.visible = false
	battlefield.add_child(log_panel)

	log_box.add_child(UIStyleScript.label("Last Moves", 16))
	log_label = UIStyleScript.label("", 13, UIStyleScript.MUTED)
	log_box.add_child(log_label)

	hand_area = Control.new()
	hand_area.anchor_left = 0.0
	hand_area.anchor_top = 1.0
	hand_area.anchor_right = 1.0
	hand_area.anchor_bottom = 1.0
	hand_area.offset_top = -240
	hand_area.offset_bottom = 0
	hand_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hand_area)

	var energy_wrap := PanelContainer.new()
	energy_wrap.anchor_left = 0.018
	energy_wrap.anchor_top = 1.0
	energy_wrap.anchor_right = 0.018
	energy_wrap.anchor_bottom = 1.0
	energy_wrap.offset_left = 0
	energy_wrap.offset_top = -122
	energy_wrap.offset_right = 96
	energy_wrap.offset_bottom = -32
	energy_wrap.add_theme_stylebox_override("panel", _energy_orb_style())
	add_child(energy_wrap)

	energy_label = UIStyleScript.label("", 25, Color.WHITE)
	energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	energy_wrap.add_child(energy_label)

	end_turn_button = Button.new()
	end_turn_button.text = "End Turn"
	end_turn_button.anchor_left = 1.0
	end_turn_button.anchor_top = 1.0
	end_turn_button.anchor_right = 1.0
	end_turn_button.anchor_bottom = 1.0
	end_turn_button.offset_left = -290
	end_turn_button.offset_top = -230
	end_turn_button.offset_right = -54
	end_turn_button.offset_bottom = -164
	_style_end_turn_button(end_turn_button)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	add_child(end_turn_button)

	claim_reward_button = Button.new()
	claim_reward_button.text = "Claim Reward"
	claim_reward_button.anchor_left = 1.0
	claim_reward_button.anchor_top = 1.0
	claim_reward_button.anchor_right = 1.0
	claim_reward_button.anchor_bottom = 1.0
	claim_reward_button.offset_left = -290
	claim_reward_button.offset_top = -230
	claim_reward_button.offset_right = -54
	claim_reward_button.offset_bottom = -164
	_style_end_turn_button(claim_reward_button, true)
	claim_reward_button.pressed.connect(_on_claim_reward_pressed)
	add_child(claim_reward_button)


func _battle_overlay_style(border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.030, 0.030, 0.028, 0.70)
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	return style


func _top_hud_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.050, 0.054, 0.76)
	style.border_color = Color(0.18, 0.24, 0.25, 0.70)
	style.border_width_bottom = 2
	style.shadow_color = Color(0, 0, 0, 0.40)
	style.shadow_size = 8
	style.content_margin_left = 18
	style.content_margin_top = 8
	style.content_margin_right = 18
	style.content_margin_bottom = 8
	return style


func _energy_orb_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.32, 0.40, 0.94)
	style.border_color = Color(0.64, 0.88, 0.92, 1.0)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 34
	style.corner_radius_top_right = 34
	style.corner_radius_bottom_left = 34
	style.corner_radius_bottom_right = 34
	style.shadow_color = Color(0.12, 0.78, 0.92, 0.35)
	style.shadow_size = 12
	style.shadow_offset = Vector2.ZERO
	return style


func _style_end_turn_button(button: Button, victory: bool = false) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _end_turn_style(victory, false))
	button.add_theme_stylebox_override("hover", _end_turn_style(victory, true))
	button.add_theme_stylebox_override("pressed", _end_turn_style(victory, true))
	button.add_theme_stylebox_override("disabled", _end_turn_style(false, false, true))


func _end_turn_style(victory: bool, hover: bool, disabled: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.35, 0.42, 0.95)
	style.border_color = Color(0.68, 0.82, 0.82, 1.0)
	if victory:
		style.bg_color = Color(0.16, 0.42, 0.24, 0.96)
		style.border_color = UIStyleScript.GREEN
	if hover:
		style.bg_color = style.bg_color.lightened(0.12)
		style.border_color = Color.WHITE
	if disabled:
		style.bg_color = Color(0.08, 0.08, 0.08, 0.82)
		style.border_color = Color(0.20, 0.20, 0.20, 1.0)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.shadow_color = Color(0, 0, 0, 0.46)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = 18
	style.content_margin_right = 18
	return style


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
	player_label.text = "HP %d/%d    Gold %d    Block %d" % [
		RunState.current_hp,
		RunState.max_hp,
		RunState.gold,
		RunState.combat.player_block,
	]
	energy_label.text = "%d/%d" % [
		RunState.combat.energy,
		RunState.combat.max_energy,
	]
	if player_hp_bar != null:
		player_hp_bar.max_value = max(RunState.max_hp, 1)
		player_hp_bar.value = RunState.current_hp
	if player_hp_label != null:
		player_hp_label.text = "%d/%d" % [RunState.current_hp, RunState.max_hp]
	if RunState.combat.healing_reduction_turns > 0:
		player_label.text += "    Healing Down %d%%/%d" % [
			RunState.combat.healing_reduction_percent,
			RunState.combat.healing_reduction_turns,
		]
	selected_target_index = _clamp_target_index(selected_target_index)
	_refresh_enemy()
	pile_label.text = "Turn %d    Draw %d" % [
		RunState.combat.turn_index,
		RunState.deck.draw_pile.size(),
	]
	_refresh_companions()
	_refresh_hand()
	end_turn_button.disabled = RunState.combat.outcome != "active"
	claim_reward_button.visible = RunState.combat.outcome == "victory"
	var recent_logs: Array[String] = []
	var start_index := maxi(log_lines.size() - 5, 0)
	for i in range(start_index, log_lines.size()):
		recent_logs.append(log_lines[i])
	log_label.text = "\n".join(PackedStringArray(recent_logs))


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


func _make_enemy_panel(enemy: Dictionary, enemy_index: int) -> Control:
	var panel := Control.new()
	panel.custom_minimum_size = Vector2(258, 326)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.gui_input.connect(_on_enemy_panel_gui_input.bind(enemy_index))

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 5)
	margin.add_child(content)

	var intent: Dictionary = enemy.get("intent", {})
	var intent_text := "Unknown"
	var intent_kind := "?"
	if String(intent.get("type", "")) == "attack":
		intent_kind = "ATK"
		intent_text = "%d" % int(intent.get("damage", 0))
	elif String(intent.get("type", "")) == "block":
		intent_kind = "BLK"
		intent_text = "+%d" % int(intent.get("block", 0))
	elif String(intent.get("type", "")) == "healing_down":
		intent_kind = "HEX"
		intent_text = "-%d%%" % int(intent.get("percent", 50))
	if int(enemy.get("hp", 0)) <= 0:
		intent_kind = "KO"
		intent_text = "Defeated"
	var intent_chip := PanelContainer.new()
	intent_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent_chip.add_theme_stylebox_override("panel", _intent_style(String(intent.get("type", ""))))
	intent_chip.custom_minimum_size = Vector2(92, 40)
	intent_chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var intent_label := UIStyleScript.label("%s %s" % [intent_kind, intent_text], 18, UIStyleScript.GOLD)
	intent_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intent_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	intent_chip.add_child(intent_label)
	content.add_child(intent_chip)

	var portrait := TextureRect.new()
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.custom_minimum_size = Vector2(220, 190)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = DataRegistry.get_temp_asset_texture(String(enemy.get("asset_id", "")))
	content.add_child(portrait)

	var name_label := UIStyleScript.label(String(enemy.get("name", "Enemy")), 16, Color.WHITE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.clip_text = true
	content.add_child(name_label)

	var hp_bar := ProgressBar.new()
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar.custom_minimum_size = Vector2(196, 15)
	hp_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hp_bar.min_value = 0
	hp_bar.max_value = max(int(enemy.get("max_hp", 1)), 1)
	hp_bar.value = int(enemy.get("hp", 0))
	hp_bar.show_percentage = false
	hp_bar.add_theme_stylebox_override("background", _bar_style(Color(0.045, 0.040, 0.036, 0.95)))
	hp_bar.add_theme_stylebox_override("fill", _bar_style(Color(0.78, 0.09, 0.08, 0.98)))
	content.add_child(hp_bar)

	var statuses: Dictionary = enemy.get("statuses", {})
	var stat_text := "%d/%d" % [int(enemy.get("hp", 0)), int(enemy.get("max_hp", 0))]
	if int(enemy.get("block", 0)) > 0:
		stat_text += "   Block %d" % int(enemy.get("block", 0))
	if int(statuses.get("tactical_mark", 0)) > 0:
		stat_text += "   Mark %d" % int(statuses.get("tactical_mark", 0))
	var hp_label := UIStyleScript.label(stat_text, 14, Color.WHITE)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(hp_label)
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
		_show_invalid_action("Not enough energy.")
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
				_show_invalid_action("Choose an enemy target.")
				_refresh()


func _on_enemy_panel_gui_input(event: InputEvent, enemy_index: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_on_enemy_pressed(enemy_index)


func _on_enemy_pressed(enemy_index: int) -> void:
	if not _enemy_can_target(enemy_index):
		_show_invalid_action("That target is gone.")
		return
	selected_target_index = enemy_index
	if selected_card_index >= 0 and _is_card_playable(selected_card_index):
		_play_card_at_target(selected_card_index, enemy_index)
	else:
		_refresh()


func _play_card_at_target(hand_index: int, target_index: int) -> void:
	if not _is_card_playable(hand_index):
		_show_invalid_action("Not enough energy.")
		return
	if _card_requires_target(hand_index) and not _enemy_can_target(target_index):
		_show_invalid_action("Choose an enemy target.")
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
	var card_size: Vector2 = CombatCardViewScript.CARD_SIZE
	var card_width: float = card_size.x
	var viewport_width: float = get_viewport_rect().size.x
	var left_reserve := 150.0
	var right_reserve := 330.0
	var hand_width: float = maxf(hand_area.size.x, viewport_width)
	var lane_width: float = maxf(520.0, hand_width - left_reserve - right_reserve)
	var spread: float = minf(720.0, maxf(0.0, lane_width - card_width - 20.0))
	var step: float = 0.0 if count <= 1 else spread / float(count - 1)
	var start_x: float = left_reserve + (lane_width - spread - card_width) * 0.5
	for i in range(count):
		var card := cards[i] as Control
		if card == null:
			continue
		var t: float = 0.5 if count <= 1 else float(i) / float(count - 1)
		var curve_y: float = 2.0 + absf(t - 0.5) * 14.0
		var rotation: float = lerpf(-0.075, 0.075, t)
		var target_position := Vector2(start_x + step * i, curve_y)
		if i == selected_card_index:
			target_position.y -= 24.0
		card.rotation = rotation
		card.pivot_offset = card_size * 0.5
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
			return card.global_position + CombatCardViewScript.CARD_SIZE * 0.5
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


func _show_invalid_action(text: String) -> void:
	_spawn_float_text(text, get_global_mouse_position(), UIStyleScript.RED)


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
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	if enemy_index == selected_target_index and alive and (selected_card_index >= 0 or dragging_card_index >= 0):
		style.bg_color = Color(0.20, 0.12, 0.04, 0.04)
		style.border_color = Color(1.0, 0.65, 0.22, 0.34)
	elif not alive:
		style.bg_color = Color(0.02, 0.02, 0.02, 0.12)
		style.border_color = Color(0.12, 0.12, 0.12, 0.28)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0, 0, 0, 0)
	style.shadow_size = 0
	style.shadow_offset = Vector2.ZERO
	style.content_margin_left = 10
	style.content_margin_top = 6
	style.content_margin_right = 10
	style.content_margin_bottom = 6
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
		_show_feedback_for_message(message)
	while log_lines.size() > 12:
		log_lines.pop_front()


func _refresh_companions() -> void:
	UIStyleScript.clear(companion_box)
	if RunState.party.companions.is_empty():
		return
	for companion in RunState.party.companions:
		companion_box.add_child(_make_companion_tile(companion))


func _make_companion_tile(companion: Dictionary) -> PanelContainer:
	var content := MarginContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("margin_left", 5)
	content.add_theme_constant_override("margin_top", 5)
	content.add_theme_constant_override("margin_right", 5)
	content.add_theme_constant_override("margin_bottom", 5)
	var panel := PanelContainer.new()
	panel.add_child(content)
	panel.custom_minimum_size = Vector2(54, 54)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.tooltip_text = "%s\n%s\nBond %d/100" % [
		String(companion.get("name", "?")),
		String(companion.get("oath_name", "No Oath")),
		int(companion.get("bond_score", 0)),
	]
	panel.add_theme_stylebox_override("panel", _companion_icon_style())

	var portrait := TextureRect.new()
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.custom_minimum_size = Vector2(44, 44)
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = DataRegistry.get_temp_asset_texture(String(companion.get("portrait_asset_id", "")))
	content.add_child(portrait)
	return panel


func _companion_icon_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.024, 0.022, 0.76)
	style.border_color = Color(0.72, 0.48, 0.18, 0.92)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0, 0, 0, 0.50)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 3)
	return style


func _show_feedback_for_message(message: String) -> void:
	var lowered := message.to_lower()
	if lowered.find("oath") >= 0:
		_show_battle_toast("OATH", message, UIStyleScript.GOLD, "fx_oath_token_glint")
	elif lowered.find("kyle wager") >= 0:
		_show_battle_toast("WAGER", message, UIStyleScript.GREEN, "fx_gold_spark")
	elif lowered.find("bond") >= 0:
		_show_battle_toast("BOND", message, UIStyleScript.GREEN, "fx_oath_token_glint")
	elif lowered == "victory.":
		_show_battle_toast("VICTORY", "Contract fulfilled.", UIStyleScript.GREEN, "fx_gold_spark")
	elif lowered == "defeat.":
		_show_battle_toast("DEFEAT", "The road claims the contract.", UIStyleScript.RED, "fx_healing_down_black_crack")


func _show_battle_toast(title: String, message: String, color: Color, asset_id: String) -> void:
	if feedback_layer == null:
		return
	var content := HBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 10)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 95
	panel.custom_minimum_size = Vector2(420, 58)
	panel.add_theme_stylebox_override("panel", _toast_style(color))
	panel.add_child(content)
	feedback_layer.add_child(panel)

	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(42, 42)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = DataRegistry.get_temp_asset_texture(asset_id)
	content.add_child(icon)

	var text_box := VBoxContainer.new()
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(text_box)

	var title_label := UIStyleScript.label(title, 15, color)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(title_label)

	var body := UIStyleScript.label(message, 13, UIStyleScript.TEXT)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.clip_text = true
	text_box.add_child(body)

	var viewport_size := get_viewport_rect().size
	panel.position = Vector2((viewport_size.x - panel.custom_minimum_size.x) * 0.5, 82)
	panel.modulate.a = 0.0
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(panel, "position:y", 64.0, 0.18)
	tween.tween_interval(1.05)
	tween.tween_property(panel, "modulate:a", 0.0, 0.26)
	tween.finished.connect(panel.queue_free)


func _toast_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.033, 0.030, 0.96)
	style.border_color = color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0, 0, 0, 0.58)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	return style
