extends Control

const ProtagonistUpgradeServiceScript := preload("res://scripts/systems/protagonist_upgrade_service.gd")
const BondSystemScript := preload("res://scripts/systems/bond_system.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")

var upgrade_service = ProtagonistUpgradeServiceScript.new()
var bond_system = BondSystemScript.new()
var options: Array[Dictionary] = []
var option_box: HBoxContainer
var companion_box: HBoxContainer
var status_label: Label
var continue_button: Button


func _ready() -> void:
	if UpgradeState.pending_source.is_empty():
		UpgradeState.begin_upgrade("map_upgrade")
	options = upgrade_service.get_options(UpgradeState.pending_source)
	_build_ui()
	_refresh()


func _build_ui() -> void:
	UIStyleScript.add_background(self, "bg_event_act1_generic", 0.78)
	var root := UIStyleScript.page_root(self, 38)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	root.add_child(layout)

	var title := UIStyleScript.label("Choose Upgrade", 34)
	layout.add_child(title)

	status_label = UIStyleScript.label("", 18, UIStyleScript.MUTED)
	layout.add_child(status_label)

	companion_box = HBoxContainer.new()
	companion_box.add_theme_constant_override("separation", 10)
	companion_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var companion_panel := UIStyleScript.panel(companion_box, Vector2(0, 128), true)
	layout.add_child(companion_panel)

	option_box = HBoxContainer.new()
	option_box.add_theme_constant_override("separation", 14)
	var option_panel := UIStyleScript.panel(option_box, Vector2(0, 170))
	layout.add_child(option_panel)

	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.visible = false
	continue_button.custom_minimum_size = Vector2(150, 44)
	UIStyleScript.style_button(continue_button, "primary")
	continue_button.pressed.connect(Callable(SceneRouter, "go_to_map"))
	layout.add_child(continue_button)


func _refresh() -> void:
	status_label.text = "Act %d | HP %d/%d | Companions %d" % [
		RunState.act,
		RunState.current_hp,
		RunState.max_hp,
		RunState.party.get_companion_count(),
	]
	for child in option_box.get_children():
		child.queue_free()
	for child in companion_box.get_children():
		child.queue_free()
	_refresh_companion_summary()
	for i in range(options.size()):
		option_box.add_child(_make_option_button(options[i], i))


func _make_option_button(option: Dictionary, index: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(250, 138)
	button.text = "%s\n%s" % [option.get("title", "Upgrade"), option.get("description", "")]
	button.icon = _option_icon(option)
	UIStyleScript.style_card_button(button, "primary")
	button.pressed.connect(_on_option_pressed.bind(index))
	return button


func _refresh_companion_summary() -> void:
	if RunState.party.companions.is_empty():
		var empty := UIStyleScript.label("No companion yet. Protagonist upgrades are safer until a contract is signed.", 16, UIStyleScript.MUTED)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		companion_box.add_child(empty)
		return
	for companion in RunState.party.companions:
		companion_box.add_child(_make_companion_upgrade_tile(companion))


func _make_companion_upgrade_tile(companion: Dictionary) -> PanelContainer:
	var content := HBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 10)
	var panel := UIStyleScript.panel(content, Vector2(260, 104), true)
	UIStyleScript.style_asset_panel(panel, "primary", int(companion.get("bond_score", 0)) >= 30, false)

	var portrait := TextureRect.new()
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.custom_minimum_size = Vector2(72, 72)
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = DataRegistry.get_temp_asset_texture(String(companion.get("portrait_asset_id", "")))
	content.add_child(portrait)

	var text_box := VBoxContainer.new()
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_theme_constant_override("separation", 3)
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(text_box)

	var name := UIStyleScript.label(String(companion.get("name", "?")), 17, UIStyleScript.TEXT)
	name.autowrap_mode = TextServer.AUTOWRAP_OFF
	name.clip_text = true
	text_box.add_child(name)

	var bond := UIStyleScript.label("Bond %d/100 - %s" % [
		int(companion.get("bond_score", 0)),
		bond_system.get_next_threshold_text(companion),
	], 13, UIStyleScript.GOLD)
	bond.autowrap_mode = TextServer.AUTOWRAP_OFF
	bond.clip_text = true
	text_box.add_child(bond)

	var bonuses := bond_system.get_active_bonus_lines(companion)
	var bonus_text := "No bond bonus yet." if bonuses.is_empty() else "\n".join(PackedStringArray(bonuses)).left(80)
	var bonus := UIStyleScript.label(bonus_text, 12, UIStyleScript.MUTED)
	bonus.custom_minimum_size = Vector2(160, 36)
	text_box.add_child(bonus)
	return panel


func _option_icon(option: Dictionary) -> Texture2D:
	match String(option.get("id", "")):
		"field_conditioning":
			return DataRegistry.get_temp_asset_texture("icon_health")
		"shared_watch":
			return DataRegistry.get_temp_asset_texture("node_companion_contract")
		"sharpen_plan":
			return DataRegistry.get_temp_asset_texture("node_upgrade")
	return DataRegistry.get_temp_asset_texture("node_upgrade")


func _on_option_pressed(index: int) -> void:
	if index < 0 or index >= options.size():
		return
	var option: Dictionary = options[index]
	var logs := upgrade_service.apply_option(option)
	RunTelemetry.record_upgrade(UpgradeState.pending_source, String(option.get("id", "")))
	status_label.text = "\n".join(PackedStringArray(logs))
	UpgradeState.complete_pending()
	for child in option_box.get_children():
		child.queue_free()
	continue_button.visible = true
