extends Control

const UIStyleScript := preload("res://scripts/ui/ui_style.gd")


func _ready() -> void:
	RunState.run_complete = true
	RunState.phase_note = "The core is broken. The road back is finally real."
	RunTelemetry.record_run_complete()
	_build_ui()


func _build_ui() -> void:
	UIStyleScript.add_background(self, "bg_battle_act1_boss_gate", 0.82)
	var root := UIStyleScript.page_root(self, 46)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	root.add_child(layout)

	var title := UIStyleScript.label("The Core Breaks", 40)
	layout.add_child(title)

	var summary := UIStyleScript.label("", 20, UIStyleScript.MUTED)
	summary.text = "HP %d/%d | Gold %d | Companions %d\n%s" % [
		RunState.current_hp,
		RunState.max_hp,
		RunState.gold,
		RunState.party.get_companion_count(),
		RunState.party.get_companion_summary(),
	]
	layout.add_child(UIStyleScript.panel(summary, Vector2(0, 130), true))

	var main := Button.new()
	main.text = "Main Menu"
	main.custom_minimum_size = Vector2(220, 44)
	UIStyleScript.style_button(main, "primary")
	main.pressed.connect(Callable(SceneRouter, "go_to_main"))
	layout.add_child(main)
