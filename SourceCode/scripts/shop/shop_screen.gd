extends Control

const ShopGeneratorScript := preload("res://scripts/systems/shop_generator.gd")
const EventResolverScript := preload("res://scripts/systems/event_resolver.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
const CardDataScript := preload("res://scripts/data/card_data.gd")

var shop_generator = ShopGeneratorScript.new()
var event_resolver = EventResolverScript.new()
var stock: Array[Dictionary] = []
var gold_label: Label
var product_grid: GridContainer
var status_label: Label
var feedback_layer: Control
var service_overlay: ColorRect
var service_title_label: Label
var service_body_label: Label
var service_card_grid: GridContainer
var pending_service_product_index := -1
var pending_service_source_position := Vector2.ZERO


func _ready() -> void:
	if not RunState.is_run_active:
		RunState.start_new_run()
	_build_ui()
	stock = shop_generator.generate_stock()
	_refresh()


func _build_ui() -> void:
	UIStyleScript.add_background(self, "bg_shop_act1_rusty_trader", 0.72)
	var root := UIStyleScript.page_root(self, 30)
	feedback_layer = Control.new()
	feedback_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	feedback_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_layer.z_index = 80
	add_child(feedback_layer)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	root.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)

	var title := UIStyleScript.label("Rust Trader", 34)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var done := Button.new()
	done.text = "Leave"
	done.custom_minimum_size = Vector2(108, 42)
	UIStyleScript.style_button(done)
	done.pressed.connect(_on_leave_pressed)
	header.add_child(done)

	gold_label = UIStyleScript.label("", 18, UIStyleScript.GOLD)
	layout.add_child(gold_label)

	product_grid = GridContainer.new()
	product_grid.columns = _shop_column_count()
	product_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	product_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	product_grid.add_theme_constant_override("h_separation", 12)
	product_grid.add_theme_constant_override("v_separation", 12)
	var product_panel := UIStyleScript.panel(product_grid, Vector2(0, 0))
	product_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	product_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(product_panel)

	status_label = UIStyleScript.label("", 16, UIStyleScript.MUTED)
	layout.add_child(status_label)

	_build_service_overlay()


func _refresh() -> void:
	product_grid.columns = _shop_column_count()
	gold_label.text = "Gold %d | Equipment %d" % [RunState.gold, RunState.equipment.owned_items.size()]
	for child in product_grid.get_children():
		child.queue_free()
	for i in range(stock.size()):
		product_grid.add_child(_make_product_button(stock[i], i))


func _make_product_button(product: Dictionary, index: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(190, 132)
	var price := int(product.get("price", 0))
	button.text = "%s\n%d gold\n%s" % [
		product.get("title", "Product"),
		price,
		product.get("description", ""),
	]
	button.icon = _product_icon(product)
	button.disabled = bool(product.get("purchased", false)) or RunState.gold < price
	UIStyleScript.style_card_button(button, "primary" if not button.disabled else "locked")
	button.pressed.connect(_on_product_pressed.bind(index))
	return button


func _shop_column_count() -> int:
	if get_viewport_rect().size.x >= 1200.0:
		return 6
	return 4


func _product_icon(product: Dictionary) -> Texture2D:
	match String(product.get("type", "")):
		"card":
			var card := DataRegistry.get_card(String(product.get("card_id", "")))
			return DataRegistry.get_temp_asset_texture(String(card.get("asset_id", "")))
		"equipment":
			var equipment := DataRegistry.get_equipment(String(product.get("equipment_id", "")))
			match String(equipment.get("slot", "")):
				"weapon":
					return DataRegistry.get_temp_asset_texture("icon_weapon_slot")
				"armor":
					return DataRegistry.get_temp_asset_texture("icon_armor_slot")
				"helmet":
					return DataRegistry.get_temp_asset_texture("icon_helmet_slot")
			return DataRegistry.get_temp_asset_texture("node_treasure")
		"service":
			match String(product.get("service", "")):
				"remove":
					return DataRegistry.get_temp_asset_texture("icon_exhaust_pile")
				"upgrade":
					return DataRegistry.get_temp_asset_texture("node_upgrade")
				"transform":
					return DataRegistry.get_temp_asset_texture("icon_draw_pile")
				"copy":
					return DataRegistry.get_temp_asset_texture("icon_discard_pile")
	return DataRegistry.get_temp_asset_texture("icon_gold")


func _on_product_pressed(index: int) -> void:
	if index < 0 or index >= stock.size():
		return
	var product: Dictionary = stock[index]
	if bool(product.get("purchased", false)):
		return
	var price := int(product.get("price", 0))
	var source_position := _product_center(index)
	if RunState.gold < price:
		status_label.text = "Not enough gold."
		_spawn_shop_feedback("Not enough gold", source_position, UIStyleScript.RED)
		return
	if String(product.get("type", "")) == "service" and _service_requires_picker(String(product.get("service", ""))):
		_begin_service_picker(index, source_position)
		return
	RunState.gold -= price
	var logs: Array[String] = []
	match String(product.get("type", "")):
		"card":
			var card_id := String(product.get("card_id", ""))
			RunState.deck.add_card_to_discard(card_id)
			logs.append("Bought card: %s." % product.get("title", "Card"))
		"equipment":
			var instance := RunState.equipment.add_equipment(String(product.get("equipment_id", "")))
			if instance.is_empty():
				logs.append("Could not buy equipment.")
			else:
				logs.append("Bought equipment: %s." % product.get("title", "Equipment"))
		"service":
			logs.append_array(_apply_service(String(product.get("service", ""))))
		_:
			logs.append("Nothing happened.")
	RunTelemetry.record_shop_purchase(String(product.get("type", "")), String(product.get("id", "")), price)
	product["purchased"] = true
	stock[index] = product
	status_label.text = "\n".join(PackedStringArray(logs))
	_refresh()
	_spawn_purchase_feedback(String(product.get("title", "Purchase")), source_position)


func _apply_service(service: String) -> Array[String]:
	match service:
		"remove":
			var before_total := RunState.deck.get_total_cards()
			var logs := event_resolver.apply_effects([{"type": "remove_card"}])
			if RunState.deck.get_total_cards() < before_total:
				RunState.equipment.card_remove_count += 1
			return logs
		"upgrade":
			return event_resolver.apply_effects([{"type": "upgrade_card"}])
		"transform":
			return event_resolver.apply_effects([{"type": "transform_card"}])
		"copy":
			return event_resolver.apply_effects([{"type": "copy_card"}])
		_:
			return ["No service."]


func _build_service_overlay() -> void:
	service_overlay = ColorRect.new()
	service_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	service_overlay.color = Color(0, 0, 0, 0.58)
	service_overlay.visible = false
	service_overlay.z_index = 120
	add_child(service_overlay)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	var panel := UIStyleScript.panel(layout, Vector2(900, 560), true)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -450
	panel.offset_top = -280
	panel.offset_right = 450
	panel.offset_bottom = 280
	service_overlay.add_child(panel)

	service_title_label = UIStyleScript.label("", 30, UIStyleScript.GOLD)
	layout.add_child(service_title_label)

	service_body_label = UIStyleScript.label("", 16, UIStyleScript.MUTED)
	layout.add_child(service_body_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 390)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)

	service_card_grid = GridContainer.new()
	service_card_grid.columns = 4
	service_card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	service_card_grid.add_theme_constant_override("h_separation", 10)
	service_card_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(service_card_grid)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 10)
	layout.add_child(actions)

	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.custom_minimum_size = Vector2(130, 42)
	UIStyleScript.style_button(cancel)
	cancel.pressed.connect(_close_service_picker)
	actions.add_child(cancel)


func _service_requires_picker(service: String) -> bool:
	return service in ["remove", "upgrade", "transform", "copy"]


func _begin_service_picker(product_index: int, source_position: Vector2) -> void:
	pending_service_product_index = product_index
	pending_service_source_position = source_position
	var product: Dictionary = stock[product_index]
	var service := String(product.get("service", ""))
	var entries := _service_entries(service)
	UIStyleScript.clear(service_card_grid)
	service_title_label.text = String(product.get("title", "Service"))
	service_body_label.text = _service_picker_hint(service, int(product.get("price", 0)))
	if entries.is_empty():
		service_body_label.text = "No valid card for this service."
		_spawn_shop_feedback("No valid target", source_position, UIStyleScript.RED)
		return
	for entry in entries:
		service_card_grid.add_child(_make_service_card_button(entry))
	service_overlay.visible = true


func _service_entries(service: String) -> Array[Dictionary]:
	var entries := RunState.deck.get_card_entries(false)
	var filtered: Array[Dictionary] = []
	for entry in entries:
		var card := DataRegistry.get_card(String(entry.get("card_id", "")))
		if card.is_empty():
			continue
		if service == "upgrade" and bool(entry.get("upgraded", false)):
			continue
		filtered.append(entry)
	return filtered


func _make_service_card_button(entry: Dictionary) -> Button:
	var card := DataRegistry.get_card(String(entry.get("card_id", "")))
	var button := Button.new()
	button.custom_minimum_size = Vector2(196, 132)
	var upgraded := "+" if bool(entry.get("upgraded", false)) else ""
	button.text = "%s%s\n%s | Cost %d\n%s" % [
		CardDataScript.card_name(card),
		upgraded,
		CardDataScript.card_type(card).capitalize(),
		CardDataScript.card_cost(card),
		CardDataScript.card_rules_text(card),
	]
	button.icon = DataRegistry.get_temp_asset_texture(String(card.get("asset_id", "")))
	UIStyleScript.style_card_button(button, "primary")
	button.pressed.connect(_on_service_card_pressed.bind(int(entry.get("instance_id", 0))))
	return button


func _on_service_card_pressed(instance_id: int) -> void:
	if pending_service_product_index < 0 or pending_service_product_index >= stock.size():
		_close_service_picker()
		return
	var product: Dictionary = stock[pending_service_product_index]
	var price := int(product.get("price", 0))
	if RunState.gold < price:
		_close_service_picker()
		_spawn_shop_feedback("Not enough gold", pending_service_source_position, UIStyleScript.RED)
		return
	var logs := _apply_service_to_instance(String(product.get("service", "")), instance_id)
	if logs.is_empty():
		logs.append("No effect.")
	if logs[0].begins_with("No "):
		status_label.text = "\n".join(PackedStringArray(logs))
		_spawn_shop_feedback(logs[0], pending_service_source_position, UIStyleScript.RED)
		_close_service_picker()
		return
	RunState.gold -= price
	RunTelemetry.record_shop_purchase(String(product.get("type", "")), String(product.get("id", "")), price)
	product["purchased"] = true
	stock[pending_service_product_index] = product
	status_label.text = "\n".join(PackedStringArray(logs))
	_close_service_picker()
	_refresh()
	_spawn_purchase_feedback(String(product.get("title", "Service")), pending_service_source_position)


func _apply_service_to_instance(service: String, instance_id: int) -> Array[String]:
	match service:
		"remove":
			var removed := RunState.deck.remove_instance(instance_id)
			if removed.is_empty():
				return ["No card removed."]
			RunState.equipment.card_remove_count += 1
			return ["Removed %s." % CardDataScript.card_name(DataRegistry.get_card(removed))]
		"upgrade":
			var upgraded := RunState.deck.upgrade_instance(instance_id)
			if upgraded.is_empty():
				return ["No card upgraded."]
			return ["Upgraded %s." % CardDataScript.card_name(DataRegistry.get_card(upgraded))]
		"transform":
			var replacement := _random_reward_card_id()
			var transformed := RunState.deck.transform_instance(instance_id, replacement)
			if transformed.is_empty() or replacement.is_empty():
				return ["No card transformed."]
			return ["Transformed %s into %s." % [
				CardDataScript.card_name(DataRegistry.get_card(transformed)),
				CardDataScript.card_name(DataRegistry.get_card(replacement)),
			]]
		"copy":
			var copied := RunState.deck.copy_instance_to_discard(instance_id)
			if copied.is_empty():
				return ["No card copied."]
			return ["Copied %s." % CardDataScript.card_name(DataRegistry.get_card(copied))]
		_:
			return ["No service."]


func _random_reward_card_id() -> String:
	var pool: Array[Dictionary] = []
	for card in DataRegistry.get_all_cards():
		if CardDataScript.is_reward_eligible(card):
			pool.append(card)
	if pool.is_empty():
		return ""
	var card: Dictionary = RngService.pick(pool, {})
	return String(card.get("id", ""))


func _service_picker_hint(service: String, price: int) -> String:
	match service:
		"remove":
			return "Pay %d gold after choosing a card to remove from the deck." % price
		"upgrade":
			return "Pay %d gold after choosing a card to upgrade." % price
		"transform":
			return "Pay %d gold after choosing a card to transform into a reward-pool card." % price
		"copy":
			return "Pay %d gold after choosing a card to copy into discard." % price
		_:
			return "Choose a card."


func _close_service_picker() -> void:
	service_overlay.visible = false
	pending_service_product_index = -1
	pending_service_source_position = Vector2.ZERO


func _on_leave_pressed() -> void:
	if MapState.has_selected_node() and MapState.get_selected_node_type() == "shop":
		MapState.complete_selected_node()
	SceneRouter.go_to_map()


func _product_center(index: int) -> Vector2:
	if product_grid != null and index >= 0 and index < product_grid.get_child_count():
		var child := product_grid.get_child(index) as Control
		if child != null:
			return child.global_position + child.size * 0.5
	return get_viewport_rect().size * 0.5


func _spawn_purchase_feedback(title: String, source_position: Vector2) -> void:
	_spawn_shop_feedback("Purchased\n%s" % title, source_position, UIStyleScript.GOLD)
	for i in range(5):
		_spawn_coin_spark(source_position + Vector2((i - 2) * 10, 0))


func _spawn_shop_feedback(text: String, source_position: Vector2, color: Color) -> void:
	if feedback_layer == null:
		return
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 90
	panel.custom_minimum_size = Vector2(260, 68)
	panel.size = panel.custom_minimum_size
	panel.add_theme_stylebox_override("panel", _feedback_style(color))
	feedback_layer.add_child(panel)
	var viewport_size := get_viewport_rect().size
	var start_position := Vector2((viewport_size.x - panel.custom_minimum_size.x) * 0.5, 82.0)
	panel.global_position = start_position
	var label := UIStyleScript.label(text, 16, Color.WHITE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.custom_minimum_size = Vector2(248, 60)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	panel.modulate.a = 0.0
	var lift_position := panel.global_position + Vector2(0, -12)
	var exit_position := panel.global_position + Vector2(0, -46)
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.08)
	tween.parallel().tween_property(panel, "global_position", lift_position, 0.16)
	tween.tween_interval(0.42)
	tween.tween_property(panel, "global_position", exit_position, 0.30)
	tween.parallel().tween_property(panel, "modulate:a", 0.0, 0.30)
	tween.finished.connect(panel.queue_free)


func _spawn_coin_spark(source_position: Vector2) -> void:
	if feedback_layer == null:
		return
	var spark := PanelContainer.new()
	spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spark.z_index = 88
	spark.custom_minimum_size = Vector2(12, 12)
	spark.size = spark.custom_minimum_size
	spark.add_theme_stylebox_override("panel", _coin_style())
	feedback_layer.add_child(spark)
	spark.global_position = source_position
	var drift := Vector2(RngService.roll_int(-28, 28), RngService.roll_int(-54, -22))
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(spark, "global_position", spark.global_position + drift, 0.40)
	tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.40)
	tween.finished.connect(spark.queue_free)


func _feedback_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.032, 0.028, 0.96)
	style.border_color = color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0, 0, 0, 0.52)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	return style


func _coin_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UIStyleScript.GOLD
	style.border_color = Color(1.0, 0.90, 0.45, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style
