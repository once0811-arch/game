class_name UIStyle
extends RefCounted

const TEXT := Color(0.94, 0.91, 0.84)
const MUTED := Color(0.72, 0.75, 0.70)
const GOLD := Color(0.96, 0.72, 0.28)
const GREEN := Color(0.49, 0.78, 0.55)
const RED := Color(0.86, 0.32, 0.28)
const BLUE := Color(0.44, 0.62, 0.72)
const PANEL := Color(0.075, 0.070, 0.060, 0.88)
const PANEL_DARK := Color(0.030, 0.032, 0.034, 0.90)
const CARD := Color(0.135, 0.120, 0.095, 0.94)
const CARD_HOVER := Color(0.205, 0.170, 0.115, 0.96)
const CARD_DISABLED := Color(0.050, 0.050, 0.048, 0.76)
const BORDER := Color(0.39, 0.31, 0.20, 0.95)
const BORDER_BRIGHT := Color(0.82, 0.58, 0.26, 1.0)
const KENNEY_FONT := "res://assets/vendor/kenney_ui/fonts/Kenney_Future.ttf"
const KENNEY_BUTTONS := {
	"default": "res://assets/vendor/kenney_ui/buttons/button_default.png",
	"primary": "res://assets/vendor/kenney_ui/buttons/button_primary.png",
	"success": "res://assets/vendor/kenney_ui/buttons/button_success.png",
	"danger": "res://assets/vendor/kenney_ui/buttons/button_danger.png",
	"blue": "res://assets/vendor/kenney_ui/buttons/button_blue.png",
	"locked": "res://assets/vendor/kenney_ui/buttons/button_default.png",
	"disabled": "res://assets/vendor/kenney_ui/buttons/button_default.png",
}


static func add_background(parent: Control, asset_id: String, shade_alpha: float = 0.66) -> void:
	var background := TextureRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var bg_path := DataRegistry.get_temp_asset_path(asset_id)
	if not bg_path.is_empty():
		background.texture = load(bg_path)
	parent.add_child(background)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.018, 0.019, 0.020, shade_alpha)
	parent.add_child(shade)


static func page_root(parent: Control, margin: int = 30) -> MarginContainer:
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", margin)
	root.add_theme_constant_override("margin_top", margin)
	root.add_theme_constant_override("margin_right", margin)
	root.add_theme_constant_override("margin_bottom", margin)
	parent.add_child(root)
	return root


static func panel(child: Control = null, min_size: Vector2 = Vector2.ZERO, dark: bool = false) -> PanelContainer:
	var panel_node := PanelContainer.new()
	panel_node.custom_minimum_size = min_size
	style_panel(panel_node, dark)
	if child != null:
		panel_node.add_child(child)
	return panel_node


static func style_panel(panel_node: PanelContainer, dark: bool = false) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_DARK if dark else PANEL
	style.border_color = BORDER
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0, 0, 0, 0.38)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	panel_node.add_theme_stylebox_override("panel", style)


static func style_asset_panel(panel_node: PanelContainer, variant: String = "default", selected: bool = false, disabled: bool = false) -> void:
	var style := _asset_box_style(variant, selected, disabled)
	if style == null:
		style_panel(panel_node, disabled)
	else:
		panel_node.add_theme_stylebox_override("panel", style)


static func style_button(button: Button, variant: String = "default") -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.42, 0.42, 0.40))
	button.add_theme_font_size_override("font_size", 15)
	var font := _ui_font()
	if font != null:
		button.add_theme_font_override("font", font)
	else:
		button.remove_theme_font_override("font")
	button.add_theme_constant_override("outline_size", 3)
	button.add_theme_color_override("font_outline_color", Color(0.02, 0.018, 0.015, 0.82))
	button.add_theme_stylebox_override("normal", _button_style(variant, false, false))
	button.add_theme_stylebox_override("hover", _button_style(variant, true, false))
	button.add_theme_stylebox_override("pressed", _button_style(variant, true, false))
	button.add_theme_stylebox_override("disabled", _button_style("disabled", false, true))


static func style_card_button(button: Button, variant: String = "default") -> void:
	style_button(button, variant)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.expand_icon = false
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


static func label(text: String, size: int = 16, color: Color = TEXT) -> Label:
	var label_node := Label.new()
	label_node.text = text
	label_node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_node.add_theme_font_size_override("font_size", size)
	label_node.add_theme_color_override("font_color", color)
	var font := _ui_font()
	if font != null:
		label_node.add_theme_font_override("font", font)
	return label_node


static func clear(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()


static func stat_text() -> Color:
	return Color(0.86, 0.86, 0.78)


static func _button_style(variant: String, hover: bool, disabled: bool) -> StyleBox:
	var asset_style := _asset_button_style(variant, hover, disabled)
	if asset_style != null:
		return asset_style
	var style := StyleBoxFlat.new()
	var bg := CARD
	var border := BORDER
	if hover:
		bg = CARD_HOVER
		border = BORDER_BRIGHT
	if variant == "primary":
		bg = Color(0.44, 0.25, 0.12, 0.96) if not hover else Color(0.58, 0.34, 0.15, 0.98)
		border = BORDER_BRIGHT
	elif variant == "danger":
		bg = Color(0.34, 0.10, 0.08, 0.95) if not hover else Color(0.48, 0.14, 0.10, 0.98)
		border = RED
	elif variant == "success":
		bg = Color(0.12, 0.27, 0.16, 0.95) if not hover else Color(0.16, 0.38, 0.20, 0.98)
		border = GREEN
	elif variant == "locked":
		bg = Color(0.055, 0.055, 0.052, 0.82)
		border = Color(0.18, 0.18, 0.17)
	elif disabled:
		bg = CARD_DISABLED
		border = Color(0.16, 0.16, 0.15)
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0, 0, 0, 0.42)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 2)
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	return style


static func _asset_button_style(variant: String, hover: bool, disabled: bool) -> StyleBoxTexture:
	var style := _asset_box_style(variant, hover, disabled)
	if style == null:
		return null
	style.content_margin_left = 18
	style.content_margin_top = 12
	style.content_margin_right = 18
	style.content_margin_bottom = 14
	return style


static func _asset_box_style(variant: String, highlighted: bool, disabled: bool) -> StyleBoxTexture:
	var key := "disabled" if disabled else variant
	if not KENNEY_BUTTONS.has(key):
		key = "default"
	var path := String(KENNEY_BUTTONS[key])
	if not ResourceLoader.exists(path):
		return null
	var style := StyleBoxTexture.new()
	style.texture = load(path)
	style.texture_margin_left = 44
	style.texture_margin_top = 34
	style.texture_margin_right = 44
	style.texture_margin_bottom = 38
	style.content_margin_left = 16
	style.content_margin_top = 12
	style.content_margin_right = 16
	style.content_margin_bottom = 12
	if disabled:
		style.modulate_color = Color(0.40, 0.40, 0.38, 0.78)
	elif highlighted:
		style.modulate_color = Color(1.12, 1.08, 0.92, 1.0)
	elif variant == "locked":
		style.modulate_color = Color(0.50, 0.48, 0.44, 0.82)
	else:
		style.modulate_color = Color(0.86, 0.72, 0.56, 0.96) if variant == "primary" else Color(0.78, 0.80, 0.76, 0.94)
	return style


static func _ui_font() -> Font:
	if _use_locale_fallback_font():
		return null
	if ResourceLoader.exists(KENNEY_FONT):
		return load(KENNEY_FONT)
	return null


static func _use_locale_fallback_font() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return false
	var settings := tree.root.get_node_or_null("/root/SettingsState")
	if settings == null:
		return false
	return String(settings.get("language_code")) == "ko"
