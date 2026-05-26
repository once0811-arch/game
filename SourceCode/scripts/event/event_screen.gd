extends Control

const EventResolverScript := preload("res://scripts/systems/event_resolver.gd")

var event_resolver = EventResolverScript.new()
var event_data: Dictionary = {}
var choice_box: VBoxContainer
var status_label: Label
var run_label: Label
var continue_button: Button


func _ready() -> void:
	if not RunState.is_run_active:
		RunState.start_new_run()
	event_data = _pick_event()
	_build_ui()
	_refresh()


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
	shade.color = Color(0.028, 0.030, 0.033, 0.70)
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
	title.text = String(event_data.get("title", "Road Event"))
	title.add_theme_font_size_override("font_size", 34)
	layout.add_child(title)

	run_label = Label.new()
	run_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(run_label)

	var body := Label.new()
	body.text = String(event_data.get("body", ""))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 18)
	layout.add_child(body)

	choice_box = VBoxContainer.new()
	choice_box.add_theme_constant_override("separation", 10)
	layout.add_child(choice_box)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.modulate = Color(0.84, 0.88, 0.80)
	layout.add_child(status_label)

	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.visible = false
	continue_button.pressed.connect(Callable(SceneRouter, "go_to_map"))
	layout.add_child(continue_button)


func _refresh() -> void:
	run_label.text = "HP %d/%d | Gold %d | %s" % [
		RunState.current_hp,
		RunState.max_hp,
		RunState.gold,
		RunState.party.get_companion_summary(),
	]
	for child in choice_box.get_children():
		child.queue_free()
	var choices: Array = event_data.get("choices", [])
	for i in range(choices.size()):
		choice_box.add_child(_make_choice_button(choices[i], i))


func _make_choice_button(choice: Dictionary, index: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 76)
	button.text = "%s\n%s" % [choice.get("label", "Choice"), choice.get("description", "")]
	button.disabled = not event_resolver.can_pay_effects(choice.get("effects", []))
	button.pressed.connect(_on_choice_pressed.bind(index))
	return button


func _on_choice_pressed(index: int) -> void:
	var choices: Array = event_data.get("choices", [])
	if index < 0 or index >= choices.size():
		return
	var choice: Dictionary = choices[index]
	if not event_resolver.can_pay_effects(choice.get("effects", [])):
		status_label.text = "Not enough gold."
		return
	status_label.text = "\n".join(PackedStringArray(event_resolver.apply_effects(choice.get("effects", []))))
	if MapState.has_selected_node() and MapState.get_selected_node_type() == "event":
		MapState.complete_selected_node()
	for child in choice_box.get_children():
		child.queue_free()
	continue_button.visible = true
	run_label.text = "HP %d/%d | Gold %d | %s" % [
		RunState.current_hp,
		RunState.max_hp,
		RunState.gold,
		RunState.party.get_companion_summary(),
	]


func _pick_event() -> Dictionary:
	var events := DataRegistry.get_act1_events()
	if events.is_empty():
		return {"title": "Empty Road", "body": "", "choices": [{"label": "Continue", "description": "No effect.", "effects": []}]}
	return RngService.pick(events, {})
