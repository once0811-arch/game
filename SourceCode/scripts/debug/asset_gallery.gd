extends Control

const PREVIEW_SIZE := Vector2(128, 128)

var registry := AssetRegistry.new()
var status_label: Label
var tab_container: TabContainer


func _ready() -> void:
	_build_base_ui()
	if registry.load_temp_manifest():
		_populate_gallery()
	else:
		status_label.text = "Missing temp asset manifest."


func _build_base_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	root.offset_left = 12
	root.offset_top = 12
	root.offset_right = -12
	root.offset_bottom = -12
	add_child(root)

	var title := Label.new()
	title.text = "Phase 0 Temp Pixel Asset Gallery"
	title.add_theme_font_size_override("font_size", 22)
	root.add_child(title)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)

	var main_button := Button.new()
	main_button.text = "Main Menu"
	main_button.custom_minimum_size = Vector2(120, 34)
	main_button.pressed.connect(Callable(SceneRouter, "go_to_main"))
	actions.add_child(main_button)

	status_label = Label.new()
	status_label.text = "Loading manifest..."
	root.add_child(status_label)

	tab_container = TabContainer.new()
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(tab_container)


func _populate_gallery() -> void:
	var total := int(registry.manifest.get("assets", []).size())
	status_label.text = "Loaded %d temp assets from %s" % [total, AssetRegistry.TEMP_MANIFEST_PATH]

	for category in registry.get_categories():
		var scroll := ScrollContainer.new()
		scroll.name = String(category)
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

		var grid := GridContainer.new()
		grid.columns = 4
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		scroll.add_child(grid)

		for asset in registry.get_assets_for_category(category):
			grid.add_child(_make_asset_card(asset))

		tab_container.add_child(scroll)


func _make_asset_card(asset: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(240, 220)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	var texture_rect := TextureRect.new()
	texture_rect.custom_minimum_size = PREVIEW_SIZE
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var path := String(asset.get("path", ""))
	var texture = load(path)
	if texture is Texture2D:
		texture_rect.texture = texture
	else:
		texture_rect.modulate = Color(0.75, 0.25, 0.25)
	box.add_child(texture_rect)

	var id_label := Label.new()
	id_label.text = String(asset.get("id", "missing_id"))
	id_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(id_label)

	var meta_label := Label.new()
	meta_label.text = "%s | %s" % [String(asset.get("type", "?")), String(asset.get("category", "?"))]
	meta_label.modulate = Color(0.78, 0.82, 0.82)
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(meta_label)

	var path_label := Label.new()
	path_label.text = path
	path_label.modulate = Color(0.58, 0.64, 0.64)
	path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(path_label)

	return panel
