extends Control

const ProtagonistUpgradeServiceScript := preload("res://scripts/systems/protagonist_upgrade_service.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")

var upgrade_service = ProtagonistUpgradeServiceScript.new()
var options: Array[Dictionary] = []
var option_box: HBoxContainer
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
	for i in range(options.size()):
		option_box.add_child(_make_option_button(options[i], i))


func _make_option_button(option: Dictionary, index: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(250, 138)
	button.text = "%s\n%s" % [option.get("title", "Upgrade"), option.get("description", "")]
	UIStyleScript.style_card_button(button, "primary")
	button.pressed.connect(_on_option_pressed.bind(index))
	return button


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
