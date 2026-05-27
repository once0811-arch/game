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
var combat_plan_label: Label
var companion_box: HBoxContainer
var hand_area: Control
var enemy_box: HBoxContainer
var player_actor: Control
var protagonist_sprite: TextureRect
var log_label: Label
var end_turn_button: Button
var claim_reward_button: Button
var enemy_controls: Array[Control] = []
var feedback_layer: Control
var combat_prompt_panel: PanelContainer
var combat_prompt_label: Label
var selected_target_index := 0
var selected_card_index := -1
var dragging_card_index := -1
var hovered_enemy_index := -1
var drag_preview: Control
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

	combat_plan_label = UIStyleScript.label("", 16, UIStyleScript.GOLD)
	combat_plan_label.custom_minimum_size = Vector2(286, 0)
	combat_plan_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combat_plan_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	combat_plan_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	combat_plan_label.clip_text = true
	top_content.add_child(combat_plan_label)

	pile_label = UIStyleScript.label("", 15, UIStyleScript.GOLD)
	pile_label.custom_minimum_size = Vector2(326, 0)
	pile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pile_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pile_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	pile_label.clip_text = true
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
	player_actor = player_box
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
	protagonist_sprite = protagonist
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

	var prompt_panel := PanelContainer.new()
	combat_prompt_panel = prompt_panel
	prompt_panel.anchor_left = 0.5
	prompt_panel.anchor_top = 0.0
	prompt_panel.anchor_right = 0.5
	prompt_panel.anchor_bottom = 0.0
	prompt_panel.offset_left = -250
	prompt_panel.offset_top = 66
	prompt_panel.offset_right = 250
	prompt_panel.offset_bottom = 110
	prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_panel.visible = false
	prompt_panel.add_theme_stylebox_override("panel", _battle_overlay_style(Color(0.72, 0.48, 0.18, 0.78)))
	add_child(prompt_panel)

	combat_prompt_label = UIStyleScript.label("", 16, UIStyleScript.TEXT)
	combat_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combat_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	combat_prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_panel.add_child(combat_prompt_label)

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
	_update_combat_plan_label()
	selected_target_index = _clamp_target_index(selected_target_index)
	_refresh_enemy()
	var wave_text := "Wave %d/%d    " % [
		RunState.combat.wave_index + 1,
		RunState.combat.wave_count,
	] if RunState.combat.wave_count > 1 else ""
	pile_label.text = "%sTurn %d    Draw %d  Discard %d  Exhaust %d" % [
		wave_text,
		RunState.combat.turn_index,
		RunState.deck.draw_pile.size(),
		RunState.deck.discard_pile.size(),
		RunState.deck.exhaust_pile.size(),
	]
	_refresh_companions()
	_refresh_hand()
	_refresh_prompt()
	end_turn_button.disabled = RunState.combat.outcome != "active"
	claim_reward_button.visible = RunState.combat.outcome == "victory"
	var recent_logs: Array[String] = []
	var start_index := maxi(log_lines.size() - 5, 0)
	for i in range(start_index, log_lines.size()):
		recent_logs.append(log_lines[i])
	log_label.text = "\n".join(PackedStringArray(recent_logs))


func _update_combat_plan_label() -> void:
	if combat_plan_label == null:
		return
	if RunState.combat.outcome == "victory":
		combat_plan_label.text = "Victory secured"
		combat_plan_label.add_theme_color_override("font_color", UIStyleScript.GREEN)
		return
	if RunState.combat.outcome == "defeat":
		combat_plan_label.text = "Contract broken"
		combat_plan_label.add_theme_color_override("font_color", UIStyleScript.RED)
		return
	var incoming: int = _incoming_attack_damage()
	var unblocked: int = max(incoming - int(RunState.combat.player_block), 0)
	var projected_hp: int = max(int(RunState.current_hp) - unblocked, 0)
	if incoming > 0:
		combat_plan_label.text = "Incoming %d -> HP %d" % [incoming, projected_hp]
		var color := UIStyleScript.RED if unblocked > 0 else UIStyleScript.BLUE
		combat_plan_label.add_theme_color_override("font_color", color)
		return
	var hostile_count := 0
	var guard_count := 0
	for enemy in RunState.combat.enemies:
		if typeof(enemy) != TYPE_DICTIONARY or int(enemy.get("hp", 0)) <= 0:
			continue
		var enemy_dict: Dictionary = enemy
		hostile_count += 1
		if String(enemy_dict.get("intent", {}).get("type", "")) == "block":
			guard_count += 1
	if hostile_count > 0 and guard_count == hostile_count:
		combat_plan_label.text = "Enemies are guarding"
	else:
		combat_plan_label.text = "No incoming damage"
	combat_plan_label.add_theme_color_override("font_color", UIStyleScript.GOLD)


func _incoming_attack_damage() -> int:
	var total := 0
	var reduction_remaining: int = int(RunState.combat.enemy_attack_reduction)
	for enemy in RunState.combat.enemies:
		if typeof(enemy) != TYPE_DICTIONARY or int(enemy.get("hp", 0)) <= 0:
			continue
		var enemy_dict: Dictionary = enemy
		var intent: Dictionary = enemy_dict.get("intent", {})
		if String(intent.get("type", "")) != "attack":
			continue
		var damage := int(intent.get("damage", 0))
		if reduction_remaining > 0:
			damage = max(damage - reduction_remaining, 0)
			reduction_remaining = 0
		total += damage
	return total


func _refresh_prompt() -> void:
	if combat_prompt_label == null or combat_prompt_panel == null:
		return
	combat_prompt_panel.visible = true
	combat_prompt_label.add_theme_color_override("font_color", UIStyleScript.TEXT)
	if RunState.combat.outcome == "victory":
		combat_prompt_label.text = "Claim the reward."
	elif RunState.combat.outcome == "defeat":
		combat_prompt_label.text = "The contract is broken."
	elif _is_targeting_enemy_card():
		combat_prompt_label.text = "Choose a living enemy."
	else:
		combat_prompt_label.text = ""
		combat_prompt_panel.visible = false


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
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(258, 326)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.gui_input.connect(_on_enemy_panel_gui_input.bind(enemy_index))
	panel.mouse_entered.connect(_on_enemy_mouse_entered.bind(enemy_index))
	panel.mouse_exited.connect(_on_enemy_mouse_exited.bind(enemy_index))
	_style_enemy_panel(panel, enemy_index)

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
	intent_chip.custom_minimum_size = Vector2(124, 42)
	intent_chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var intent_row := HBoxContainer.new()
	intent_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent_row.alignment = BoxContainer.ALIGNMENT_CENTER
	intent_row.add_theme_constant_override("separation", 6)
	intent_chip.add_child(intent_row)
	var intent_icon := TextureRect.new()
	intent_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent_icon.custom_minimum_size = Vector2(24, 24)
	intent_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	intent_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	intent_icon.texture = DataRegistry.get_temp_asset_texture(_intent_icon_asset_id(String(intent.get("type", "")), int(enemy.get("hp", 0)) <= 0))
	intent_row.add_child(intent_icon)
	var intent_label := UIStyleScript.label("%s %s" % [intent_kind, intent_text], 18, UIStyleScript.GOLD)
	intent_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent_label.custom_minimum_size = Vector2(68, 24)
	intent_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	intent_label.clip_text = true
	intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intent_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	intent_row.add_child(intent_label)
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
	var validation := _validate_card_play(hand_index, -1)
	if not bool(validation.get("ok", false)) and not _card_requires_target(hand_index):
		_show_invalid_action(String(validation.get("message", "")))
		return
	if not _card_requires_target(hand_index):
		_play_card_at_target(hand_index, -1)
		return
	selected_card_index = hand_index
	hovered_enemy_index = -1
	_layout_hand_cards()
	_refresh_enemy()
	_refresh_prompt()


func _on_card_drag_started(hand_index: int, card_name_text: String) -> void:
	if not _is_card_playable(hand_index):
		_show_invalid_action(String(_validate_card_play(hand_index, -1).get("message", "Cannot play.")))
		return
	selected_card_index = hand_index
	dragging_card_index = hand_index
	drag_start_position = _card_center_for_hand_index(hand_index)
	_show_drag_preview(card_name_text)
	if _card_requires_target(hand_index):
		_update_target_arc()
	_refresh_enemy()
	_refresh_prompt()


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
				_show_invalid_action("Choose a living enemy.")
				_refresh()


func _on_enemy_panel_gui_input(event: InputEvent, enemy_index: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_on_enemy_pressed(enemy_index)


func _on_enemy_pressed(enemy_index: int) -> void:
	if not _enemy_can_target(enemy_index):
		_show_invalid_action("That enemy is already down.")
		return
	selected_target_index = enemy_index
	if selected_card_index >= 0 and _is_card_playable(selected_card_index):
		_play_card_at_target(selected_card_index, enemy_index)
	else:
		_refresh()


func _play_card_at_target(hand_index: int, target_index: int) -> void:
	var validation := _validate_card_play(hand_index, target_index)
	if not bool(validation.get("ok", false)):
		_show_invalid_action(String(validation.get("message", "")))
		return
	var instance: Dictionary = RunState.deck.hand[hand_index]
	var card := DataRegistry.get_card(CardInstanceScript.get_card_id(instance)).duplicate(true)
	var source_position := _card_center_for_hand_index(hand_index)
	var effect_kind := _card_effect_kind(card)
	var destination := _feedback_destination(target_index, effect_kind)
	var enemy_destinations := _current_enemy_centers()
	selected_target_index = target_index
	selected_card_index = -1
	hovered_enemy_index = -1
	_clear_target_arc()
	var messages := turn_manager.play_card(hand_index, target_index)
	_append_logs(messages)
	_refresh()
	_play_card_feedback.call_deferred(card, source_position, target_index, effect_kind, messages, destination, enemy_destinations)


func _on_end_turn_pressed() -> void:
	selected_card_index = -1
	dragging_card_index = -1
	hovered_enemy_index = -1
	_clear_drag_preview()
	_clear_target_arc()
	var messages := turn_manager.end_player_turn()
	_append_logs(messages)
	_refresh()
	_play_enemy_feedback.call_deferred(messages)


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


func _validate_card_play(hand_index: int, target_index: int) -> Dictionary:
	if hand_index < 0 or hand_index >= RunState.deck.hand.size():
		return {"ok": false, "message": "That card is no longer in hand."}
	var instance: Dictionary = RunState.deck.hand[hand_index]
	var card := DataRegistry.get_card(CardInstanceScript.get_card_id(instance))
	return CardPlayRulesScript.validate_play(card, hand_index, target_index)


func _card_requires_target(hand_index: int) -> bool:
	if hand_index < 0 or hand_index >= RunState.deck.hand.size():
		return false
	var instance: Dictionary = RunState.deck.hand[hand_index]
	var card := DataRegistry.get_card(CardInstanceScript.get_card_id(instance))
	return CardPlayRulesScript.requires_enemy_target(card)


func _is_targeting_enemy_card() -> bool:
	var hand_index := dragging_card_index if dragging_card_index >= 0 else selected_card_index
	return hand_index >= 0 and _card_requires_target(hand_index)


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


func _current_enemy_centers() -> Array[Vector2]:
	var centers: Array[Vector2] = []
	for i in range(enemy_controls.size()):
		centers.append(_enemy_center(i))
	return centers


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
	var content := HBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 7)
	drag_preview = PanelContainer.new()
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.z_index = 50
	drag_preview.custom_minimum_size = Vector2(176, 42)
	(drag_preview as PanelContainer).add_theme_stylebox_override("panel", _battle_overlay_style(UIStyleScript.GOLD))
	drag_preview.add_child(content)
	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = DataRegistry.get_temp_asset_texture("icon_tactical_mark")
	content.add_child(icon)
	var label := UIStyleScript.label(card_name, 15, UIStyleScript.GOLD)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(label)
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
	var target_index := _enemy_index_at_position(target)
	target_arc.default_color = Color(1.0, 0.72, 0.24, 0.96) if target_index >= 0 else Color(0.88, 0.24, 0.20, 0.82)
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
	if combat_prompt_label != null:
		if combat_prompt_panel != null:
			combat_prompt_panel.visible = true
		combat_prompt_label.text = text
		combat_prompt_label.add_theme_color_override("font_color", UIStyleScript.RED)


func _play_card_feedback(card: Dictionary, source_position: Vector2, target_index: int, effect_kind: String, messages: Array[String], destination: Vector2, enemy_destinations: Array[Vector2]) -> void:
	_animate_player_action(effect_kind, destination)
	_animate_played_card(card, source_position, destination, effect_kind)
	await get_tree().create_timer(0.18).timeout
	match effect_kind:
		"damage_all":
			for enemy_destination in enemy_destinations:
				_spawn_projectile(source_position, enemy_destination, effect_kind)
				_spawn_impact(enemy_destination, effect_kind)
		"damage", "mark":
			_spawn_projectile(source_position, destination, effect_kind)
			if target_index >= 0 and target_index < enemy_controls.size() and _enemy_center(target_index).distance_to(destination) < 36.0:
				_animate_target_hit(target_index, effect_kind)
			else:
				_spawn_impact(destination, effect_kind)
		"block", "heal":
			_spawn_impact(destination, effect_kind)
			_animate_player_buff(effect_kind)
		_:
			_spawn_impact(destination, effect_kind)
	_spawn_log_feedback(messages, target_index, effect_kind)


func _play_enemy_feedback(messages: Array[String]) -> void:
	for message in messages:
		var lowered := message.to_lower()
		if lowered.find(" used ") >= 0 and lowered.find(" damage") >= 0:
			var enemy_index := _enemy_index_from_message(message)
			if enemy_index >= 0:
				_animate_enemy_lunge(enemy_index)
				_spawn_projectile(_enemy_center(enemy_index), _player_center(), "enemy_attack")
			_animate_player_hit()
			_spawn_number_from_message(message, _player_center() + Vector2(0, -74), UIStyleScript.RED)
		elif lowered.find(" applied healing down") >= 0:
			var caster_index := _enemy_index_from_message(message)
			var from_position := _enemy_center(caster_index) if caster_index >= 0 else get_viewport_rect().size * 0.5
			_spawn_projectile(from_position, _player_center(), "hex")
			_spawn_float_text("Healing Down", _player_center() + Vector2(-68, -90), Color(0.74, 0.44, 0.86))
			_animate_player_hit(Color(0.56, 0.30, 0.70, 1.0))
		elif lowered.find(" gained ") >= 0 and lowered.find(" block") >= 0:
			var guard_index := _enemy_index_from_message(message)
			if guard_index >= 0:
				_spawn_impact(_enemy_center(guard_index), "block")
		elif lowered.find("attacked marked target") >= 0:
			var target_index := _clamp_target_index(selected_target_index)
			_spawn_projectile(_companion_origin(), _enemy_center(target_index), "mark")
			_animate_target_hit(target_index, "damage")


func _card_effect_kind(card: Dictionary) -> String:
	var has_damage := false
	var has_damage_all := false
	var has_block := false
	var has_heal := false
	var has_mark := false
	for effect in card.get("effects", []):
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		match String(effect.get("type", "")):
			"damage":
				has_damage = true
			"damage_all":
				has_damage_all = true
			"block":
				has_block = true
			"heal":
				has_heal = true
			"tactical_mark", "power_tactical_mark_bonus":
				has_mark = true
	if has_damage_all:
		return "damage_all"
	if has_damage:
		return "damage"
	if has_heal:
		return "heal"
	if has_block:
		return "block"
	if has_mark:
		return "mark"
	return "utility"


func _feedback_destination(target_index: int, effect_kind: String) -> Vector2:
	if effect_kind in ["block", "heal", "utility"]:
		return _player_center()
	return _target_feedback_position(target_index)


func _animate_played_card(card: Dictionary, source_position: Vector2, destination: Vector2, effect_kind: String) -> void:
	if feedback_layer == null:
		return
	var play_card := _make_action_card(card, effect_kind)
	feedback_layer.add_child(play_card)
	play_card.global_position = source_position - play_card.custom_minimum_size * 0.5
	play_card.scale = Vector2(0.72, 0.72)
	play_card.modulate.a = 0.0
	var apex := (source_position + destination) * 0.5 + Vector2(0, -120)
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(play_card, "modulate:a", 1.0, 0.06)
	tween.parallel().tween_property(play_card, "scale", Vector2(1.18, 1.18), 0.16)
	tween.parallel().tween_property(play_card, "global_position", apex - play_card.custom_minimum_size * 0.5, 0.16)
	tween.tween_property(play_card, "global_position", destination - play_card.custom_minimum_size * 0.32, 0.15)
	tween.parallel().tween_property(play_card, "scale", Vector2(0.64, 0.64), 0.15)
	tween.tween_property(play_card, "modulate:a", 0.0, 0.08)
	tween.finished.connect(play_card.queue_free)


func _make_action_card(card: Dictionary, effect_kind: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 120
	panel.custom_minimum_size = Vector2(150, 212)
	panel.size = panel.custom_minimum_size
	panel.add_theme_stylebox_override("panel", _action_card_style(effect_kind))

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_theme_constant_override("separation", 6)
	margin.add_child(layout)

	var title := UIStyleScript.label(CardDataScript.card_name(card), 15, Color.WHITE)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.clip_text = true
	layout.add_child(title)

	var art := TextureRect.new()
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.custom_minimum_size = Vector2(126, 86)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var art_path := DataRegistry.get_temp_asset_path(String(card.get("asset_id", "")))
	if not art_path.is_empty():
		art.texture = load(art_path)
	layout.add_child(art)

	var verb := UIStyleScript.label(_effect_label(effect_kind), 13, _effect_color(effect_kind))
	verb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	verb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(verb)
	return panel


func _action_card_style(effect_kind: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.066, 0.052, 0.96)
	style.border_color = _effect_color(effect_kind)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 9
	style.corner_radius_top_right = 9
	style.corner_radius_bottom_left = 9
	style.corner_radius_bottom_right = 9
	style.shadow_color = Color(0, 0, 0, 0.62)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0, 7)
	return style


func _spawn_projectile(from_position: Vector2, to_position: Vector2, effect_kind: String) -> void:
	if feedback_layer == null:
		return
	var projectile := PanelContainer.new()
	projectile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	projectile.z_index = 115
	projectile.custom_minimum_size = Vector2(18, 18)
	projectile.size = projectile.custom_minimum_size
	projectile.add_theme_stylebox_override("panel", _disc_style(_effect_color(effect_kind), true))
	feedback_layer.add_child(projectile)
	projectile.global_position = from_position - projectile.size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(projectile, "global_position", to_position - projectile.size * 0.5, 0.18)
	tween.parallel().tween_property(projectile, "scale", Vector2(1.65, 1.65), 0.18)
	tween.tween_property(projectile, "modulate:a", 0.0, 0.08)
	tween.finished.connect(projectile.queue_free)


func _spawn_impact(global_position: Vector2, effect_kind: String) -> void:
	if feedback_layer == null:
		return
	_spawn_sprite_fx(_effect_asset_id(effect_kind), global_position, Vector2(96, 96))
	var ring := PanelContainer.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.z_index = 118
	ring.custom_minimum_size = Vector2(58, 58)
	ring.size = ring.custom_minimum_size
	ring.add_theme_stylebox_override("panel", _ring_style(_effect_color(effect_kind)))
	feedback_layer.add_child(ring)
	ring.global_position = global_position - ring.size * 0.5
	ring.scale = Vector2(0.35, 0.35)
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "scale", Vector2(1.38, 1.38), 0.18)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.24)
	tween.finished.connect(ring.queue_free)


func _spawn_sprite_fx(asset_id: String, global_position: Vector2, size_hint: Vector2) -> void:
	if feedback_layer == null or asset_id.is_empty():
		return
	var asset := DataRegistry.get_temp_asset(asset_id)
	if asset.is_empty():
		return
	var sprite := TextureRect.new()
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.z_index = 119
	sprite.custom_minimum_size = size_hint
	sprite.size = size_hint
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture = DataRegistry.get_temp_asset_texture(asset_id, 0)
	feedback_layer.add_child(sprite)
	sprite.global_position = global_position - size_hint * 0.5
	sprite.scale = Vector2(0.82, 0.82)
	var grow := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	grow.tween_property(sprite, "scale", Vector2(1.18, 1.18), 0.16)
	grow.parallel().tween_property(sprite, "modulate:a", 0.0, 0.36).set_delay(0.12)
	var frames: int = maxi(int(asset.get("frames", 1)), 1)
	for frame in range(1, frames):
		await get_tree().create_timer(0.045).timeout
		if not is_instance_valid(sprite):
			return
		sprite.texture = DataRegistry.get_temp_asset_texture(asset_id, frame)
	await get_tree().create_timer(0.16).timeout
	if is_instance_valid(sprite):
		sprite.queue_free()


func _animate_target_hit(target_index: int, effect_kind: String) -> void:
	if target_index < 0 or target_index >= enemy_controls.size():
		return
	var target := enemy_controls[target_index]
	var original := target.position
	var shove := Vector2(12, 0) if effect_kind != "mark" else Vector2(0, -8)
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "position", original + shove, 0.045)
	tween.tween_property(target, "position", original - shove * 0.45, 0.055)
	tween.tween_property(target, "position", original, 0.065)
	_spawn_impact(_enemy_center(target_index), effect_kind)


func _animate_player_action(effect_kind: String, destination: Vector2) -> void:
	if protagonist_sprite == null:
		return
	var original_position := protagonist_sprite.position
	var original_texture := protagonist_sprite.texture
	var action_texture := DataRegistry.get_temp_asset_texture("protagonist_mercenary_attack", 1)
	if effect_kind in ["block", "heal"]:
		action_texture = DataRegistry.get_temp_asset_texture("protagonist_mercenary_guard", 1)
	if action_texture != null:
		protagonist_sprite.texture = action_texture
	var direction := (destination - _player_center()).normalized()
	var lunge := Vector2(clampf(direction.x, -1.0, 1.0) * 18.0, -4.0)
	if effect_kind in ["block", "heal", "utility"]:
		lunge = Vector2(0, -6)
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(protagonist_sprite, "position", original_position + lunge, 0.08)
	tween.tween_property(protagonist_sprite, "position", original_position, 0.14)
	tween.finished.connect(func() -> void:
		if is_instance_valid(protagonist_sprite):
			protagonist_sprite.texture = original_texture
	)


func _animate_enemy_lunge(enemy_index: int) -> void:
	if enemy_index < 0 or enemy_index >= enemy_controls.size():
		return
	var target := enemy_controls[enemy_index]
	var original := target.position
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "position", original + Vector2(-34, 0), 0.10)
	tween.tween_property(target, "position", original, 0.16)


func _animate_player_hit(color: Color = Color(1.0, 0.32, 0.22, 1.0)) -> void:
	if protagonist_sprite == null:
		return
	var original := protagonist_sprite.position
	var original_modulate := protagonist_sprite.modulate
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(protagonist_sprite, "position", original + Vector2(-12, 0), 0.05)
	tween.parallel().tween_property(protagonist_sprite, "modulate", color, 0.05)
	tween.tween_property(protagonist_sprite, "position", original + Vector2(8, 0), 0.06)
	tween.tween_property(protagonist_sprite, "position", original, 0.08)
	tween.parallel().tween_property(protagonist_sprite, "modulate", original_modulate, 0.16)


func _animate_player_buff(effect_kind: String) -> void:
	var actor := player_actor if player_actor != null else protagonist_sprite
	if actor == null:
		return
	var original_scale := actor.scale
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(actor, "scale", original_scale * 1.04, 0.10)
	tween.tween_property(actor, "scale", original_scale, 0.16)
	_spawn_float_text(_effect_label(effect_kind), _player_center() + Vector2(-58, -92), _effect_color(effect_kind))


func _spawn_log_feedback(messages: Array[String], target_index: int, effect_kind: String) -> void:
	for message in messages:
		var lowered := message.to_lower()
		if lowered.find("dealt") >= 0 and lowered.find("damage") >= 0:
			_spawn_number_from_message(message, _target_feedback_position(target_index) + Vector2(0, -70), UIStyleScript.RED)
		elif lowered.begins_with("gained") and lowered.find("block") >= 0:
			_spawn_number_from_message(message, _player_center() + Vector2(0, -72), UIStyleScript.BLUE, "+")
		elif lowered.find("healed") >= 0:
			_spawn_number_from_message(message, _player_center() + Vector2(0, -92), UIStyleScript.GREEN, "+")
		elif lowered.find("applied") >= 0 and lowered.find("tactical mark") >= 0:
			_spawn_number_from_message(message, _target_feedback_position(target_index) + Vector2(0, -94), UIStyleScript.GOLD, "Mark ")
		elif lowered.find("gained") >= 0 and lowered.find("energy") >= 0:
			_spawn_number_from_message(message, _energy_center(), UIStyleScript.GOLD, "+")


func _spawn_number_from_message(message: String, position: Vector2, color: Color, prefix: String = "") -> void:
	var amount := _first_integer(message)
	if amount < 0:
		return
	_spawn_float_text("%s%d" % [prefix, amount], position, color)


func _first_integer(text: String) -> int:
	var digits := ""
	for i in range(text.length()):
		var character := text.substr(i, 1)
		if character >= "0" and character <= "9":
			digits += character
		elif not digits.is_empty():
			break
	return int(digits) if not digits.is_empty() else -1


func _enemy_index_from_message(message: String) -> int:
	for i in range(RunState.combat.enemies.size()):
		var enemy: Dictionary = RunState.combat.enemies[i]
		var enemy_name := String(enemy.get("name", ""))
		if not enemy_name.is_empty() and message.begins_with(enemy_name):
			return i
	return -1


func _player_center() -> Vector2:
	if protagonist_sprite != null:
		return protagonist_sprite.global_position + protagonist_sprite.size * 0.5
	if player_actor != null:
		return player_actor.global_position + player_actor.size * 0.5
	return get_viewport_rect().size * 0.5


func _enemy_center(enemy_index: int) -> Vector2:
	if enemy_index >= 0 and enemy_index < enemy_controls.size():
		var enemy_control := enemy_controls[enemy_index]
		return enemy_control.global_position + enemy_control.size * 0.5
	return get_viewport_rect().size * 0.5


func _energy_center() -> Vector2:
	if energy_label != null:
		return energy_label.global_position + energy_label.size * 0.5
	return Vector2(80, get_viewport_rect().size.y - 80)


func _companion_origin() -> Vector2:
	if companion_box != null and companion_box.get_child_count() > 0:
		var child := companion_box.get_child(0) as Control
		if child != null:
			return child.global_position + child.size * 0.5
	return _player_center() + Vector2(60, -80)


func _effect_label(effect_kind: String) -> String:
	match effect_kind:
		"damage", "damage_all", "enemy_attack":
			return "Strike"
		"block":
			return "Guard"
		"heal":
			return "Mend"
		"mark":
			return "Mark"
		"hex":
			return "Hex"
		_:
			return "Tactic"


func _effect_asset_id(effect_kind: String) -> String:
	match effect_kind:
		"damage", "enemy_attack":
			return "fx_slash_small"
		"damage_all":
			return "fx_pierce_red"
		"block":
			return "fx_guard_flash"
		"heal":
			return "fx_heal_low"
		"mark":
			return "fx_tactical_mark_pin"
		"hex":
			return "fx_healing_down_black_crack"
		_:
			return "fx_oath_token_glint"


func _effect_color(effect_kind: String) -> Color:
	match effect_kind:
		"damage", "damage_all", "enemy_attack":
			return Color(1.0, 0.26, 0.18, 1.0)
		"block":
			return UIStyleScript.BLUE
		"heal":
			return UIStyleScript.GREEN
		"mark":
			return UIStyleScript.GOLD
		"hex":
			return Color(0.70, 0.38, 0.82, 1.0)
		_:
			return Color(0.82, 0.78, 0.64, 1.0)


func _disc_style(color: Color, filled: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.95 if filled else 0.0)
	style.border_color = color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.shadow_color = Color(color.r, color.g, color.b, 0.42)
	style.shadow_size = 9
	style.shadow_offset = Vector2.ZERO
	return style


func _ring_style(color: Color) -> StyleBoxFlat:
	var style := _disc_style(color, false)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 30
	style.corner_radius_top_right = 30
	style.corner_radius_bottom_left = 30
	style.corner_radius_bottom_right = 30
	return style


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


func _intent_icon_asset_id(intent_type: String, defeated: bool = false) -> String:
	if defeated:
		return "icon_health"
	match intent_type:
		"attack":
			return "icon_weapon_slot"
		"block":
			return "icon_block"
		"healing_down":
			return "icon_healing_down"
		_:
			return "icon_tactical_mark"


func _style_enemy_panel(panel: PanelContainer, enemy_index: int) -> void:
	var style := StyleBoxFlat.new()
	var alive := _enemy_can_target(enemy_index)
	var targeting := _is_targeting_enemy_card()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	if alive and targeting and enemy_index == hovered_enemy_index:
		style.bg_color = Color(0.36, 0.18, 0.04, 0.18)
		style.border_color = Color(1.0, 0.70, 0.22, 0.92)
		style.shadow_color = Color(1.0, 0.45, 0.10, 0.38)
		style.shadow_size = 12
	elif alive and targeting:
		style.bg_color = Color(0.20, 0.12, 0.04, 0.08)
		style.border_color = Color(1.0, 0.65, 0.22, 0.56)
		style.shadow_color = Color(1.0, 0.45, 0.10, 0.16)
		style.shadow_size = 8
	elif enemy_index == hovered_enemy_index and alive:
		style.bg_color = Color(0.08, 0.13, 0.14, 0.10)
		style.border_color = Color(0.62, 0.78, 0.80, 0.42)
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
	if style.shadow_size <= 0:
		style.shadow_color = Color(0, 0, 0, 0)
		style.shadow_size = 0
	style.shadow_offset = Vector2.ZERO
	style.content_margin_left = 10
	style.content_margin_top = 6
	style.content_margin_right = 10
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)


func _on_enemy_mouse_entered(enemy_index: int) -> void:
	hovered_enemy_index = enemy_index
	if enemy_index >= 0 and enemy_index < enemy_controls.size():
		_style_enemy_panel(enemy_controls[enemy_index] as PanelContainer, enemy_index)
	if _is_targeting_enemy_card():
		selected_target_index = enemy_index
		_update_target_arc()
		_refresh_prompt()


func _on_enemy_mouse_exited(enemy_index: int) -> void:
	if hovered_enemy_index == enemy_index:
		hovered_enemy_index = -1
	if enemy_index >= 0 and enemy_index < enemy_controls.size():
		_style_enemy_panel(enemy_controls[enemy_index] as PanelContainer, enemy_index)
	if _is_targeting_enemy_card():
		_update_target_arc()


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
	panel.custom_minimum_size = Vector2(62, 76)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var bonuses := bond_system.describe_bonuses(companion)
	panel.tooltip_text = "%s\n%s\n%s\n%s" % [
		String(companion.get("name", "?")),
		String(companion.get("oath_name", "No Oath")),
		bonuses,
		bond_system.get_next_threshold_text(companion),
	]
	panel.add_theme_stylebox_override("panel", _companion_icon_style())

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 3)
	content.add_child(column)

	var portrait := TextureRect.new()
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.custom_minimum_size = Vector2(44, 44)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = DataRegistry.get_temp_asset_texture(String(companion.get("portrait_asset_id", "")))
	column.add_child(portrait)

	var bar := ProgressBar.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.custom_minimum_size = Vector2(46, 5)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.min_value = 0
	bar.max_value = 100
	bar.value = int(companion.get("bond_score", 0))
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _bar_style(Color(0.035, 0.032, 0.028, 0.96)))
	bar.add_theme_stylebox_override("fill", _bar_style(_bond_color(int(companion.get("bond_score", 0)))))
	column.add_child(bar)

	var score := UIStyleScript.label(str(int(companion.get("bond_score", 0))), 10, UIStyleScript.GOLD)
	score.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score.autowrap_mode = TextServer.AUTOWRAP_OFF
	column.add_child(score)
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


func _bond_color(score: int) -> Color:
	if score >= 100:
		return Color(0.96, 0.72, 0.28, 1.0)
	if score >= 60:
		return Color(0.48, 0.76, 0.70, 1.0)
	if score >= 30:
		return Color(0.49, 0.78, 0.55, 1.0)
	return Color(0.45, 0.55, 0.58, 1.0)


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
	panel.size = panel.custom_minimum_size
	panel.add_theme_stylebox_override("panel", _toast_style(color))
	panel.add_child(content)
	feedback_layer.add_child(panel)
	content.custom_minimum_size = Vector2(396, 42)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(42, 42)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = DataRegistry.get_temp_asset_texture(asset_id)
	content.add_child(icon)

	var text_box := VBoxContainer.new()
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.custom_minimum_size = Vector2(320, 42)
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(text_box)

	var title_label := UIStyleScript.label(title, 15, color)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.custom_minimum_size = Vector2(320, 18)
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.clip_text = true
	text_box.add_child(title_label)

	var body := UIStyleScript.label(message, 13, UIStyleScript.TEXT)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.custom_minimum_size = Vector2(320, 18)
	body.autowrap_mode = TextServer.AUTOWRAP_OFF
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
