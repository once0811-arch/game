extends Control

const ShopGeneratorScript := preload("res://scripts/systems/shop_generator.gd")
const EventResolverScript := preload("res://scripts/systems/event_resolver.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")

var shop_generator = ShopGeneratorScript.new()
var event_resolver = EventResolverScript.new()
var stock: Array[Dictionary] = []
var gold_label: Label
var product_grid: GridContainer
var status_label: Label


func _ready() -> void:
	if not RunState.is_run_active:
		RunState.start_new_run()
	_build_ui()
	stock = shop_generator.generate_stock()
	_refresh()


func _build_ui() -> void:
	UIStyleScript.add_background(self, "bg_shop_act1_rusty_trader", 0.72)
	var root := UIStyleScript.page_root(self, 30)

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
	product_grid.columns = 3
	product_grid.add_theme_constant_override("h_separation", 12)
	product_grid.add_theme_constant_override("v_separation", 12)
	var product_panel := UIStyleScript.panel(product_grid, Vector2(0, 0))
	product_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(product_panel)

	status_label = UIStyleScript.label("", 16, UIStyleScript.MUTED)
	layout.add_child(status_label)


func _refresh() -> void:
	gold_label.text = "Gold %d | Equipment %d" % [RunState.gold, RunState.equipment.owned_items.size()]
	for child in product_grid.get_children():
		child.queue_free()
	for i in range(stock.size()):
		product_grid.add_child(_make_product_button(stock[i], i))


func _make_product_button(product: Dictionary, index: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(250, 134)
	var price := int(product.get("price", 0))
	button.text = "%s\n%d gold\n%s" % [
		product.get("title", "Product"),
		price,
		product.get("description", ""),
	]
	button.disabled = bool(product.get("purchased", false)) or RunState.gold < price
	UIStyleScript.style_card_button(button, "primary" if not button.disabled else "locked")
	button.pressed.connect(_on_product_pressed.bind(index))
	return button


func _on_product_pressed(index: int) -> void:
	if index < 0 or index >= stock.size():
		return
	var product: Dictionary = stock[index]
	if bool(product.get("purchased", false)):
		return
	var price := int(product.get("price", 0))
	if RunState.gold < price:
		status_label.text = "Not enough gold."
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


func _on_leave_pressed() -> void:
	if MapState.has_selected_node() and MapState.get_selected_node_type() == "shop":
		MapState.complete_selected_node()
	SceneRouter.go_to_map()
