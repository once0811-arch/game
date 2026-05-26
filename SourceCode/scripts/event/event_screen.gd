extends Control

const EventResolverScript := preload("res://scripts/systems/event_resolver.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")

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
	UIStyleScript.add_background(self, "bg_event_act1_generic", 0.72)
	var root := UIStyleScript.page_root(self, 38)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	root.add_child(layout)

	var title := UIStyleScript.label(String(event_data.get("title", "Road Event")), 34)
	layout.add_child(title)

	run_label = UIStyleScript.label("", 17, UIStyleScript.GOLD)
	layout.add_child(run_label)

	var body := UIStyleScript.label("", 19)
	body.text = String(event_data.get("body", ""))
	var body_panel := UIStyleScript.panel(body, Vector2(0, 120), true)
	layout.add_child(body_panel)

	choice_box = VBoxContainer.new()
	choice_box.add_theme_constant_override("separation", 12)
	layout.add_child(choice_box)

	status_label = UIStyleScript.label("", 16, UIStyleScript.MUTED)
	layout.add_child(status_label)

	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.visible = false
	continue_button.custom_minimum_size = Vector2(150, 44)
	UIStyleScript.style_button(continue_button, "primary")
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
	button.custom_minimum_size = Vector2(0, 82)
	button.text = "%s\n%s" % [choice.get("label", "Choice"), choice.get("description", "")]
	button.disabled = not event_resolver.can_pay_effects(choice.get("effects", []))
	UIStyleScript.style_card_button(button, "primary" if not button.disabled else "locked")
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
	RunTelemetry.record_event_choice(String(event_data.get("id", "")), String(choice.get("label", "")))
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
