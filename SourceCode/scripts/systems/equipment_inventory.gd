class_name EquipmentInventory
extends RefCounted

var owned_items: Array[Dictionary] = []
var equipped: Dictionary = {}
var next_instance_id := 1
var card_remove_count := 0


func reset() -> void:
	owned_items.clear()
	equipped.clear()
	next_instance_id = 1
	card_remove_count = 0


func add_equipment(equipment_id: String) -> Dictionary:
	var data := DataRegistry.get_equipment(equipment_id)
	if data.is_empty():
		return {}
	var instance := {
		"instance_id": next_instance_id,
		"equipment_id": equipment_id,
	}
	next_instance_id += 1
	owned_items.append(instance)
	return instance


func equip_cycle(instance_id: int) -> String:
	var instance := get_instance(instance_id)
	if instance.is_empty():
		return "Missing equipment."
	var data := get_data_for_instance(instance)
	if data.is_empty():
		return "Missing equipment data."

	var slot := String(data.get("slot", ""))
	var wearers := get_wearers()
	if wearers.is_empty():
		return "No valid wearer."

	var current_wearer := _get_equipped_wearer(instance_id)
	var next_wearer := ""
	if current_wearer.is_empty():
		next_wearer = String(wearers[0].get("id", ""))
	else:
		var current_index := _wearer_index(wearers, current_wearer)
		if current_index >= 0 and current_index + 1 < wearers.size():
			next_wearer = String(wearers[current_index + 1].get("id", ""))

	_unequip_instance(instance_id)
	if next_wearer.is_empty():
		return "Unequipped %s." % data.get("name", "Equipment")

	_ensure_wearer(next_wearer)
	equipped[next_wearer][slot] = instance_id
	return "Equipped %s to %s." % [data.get("name", "Equipment"), _wearer_name(next_wearer)]


func get_instance(instance_id: int) -> Dictionary:
	for instance in owned_items:
		if int(instance.get("instance_id", 0)) == instance_id:
			return instance
	return {}


func get_data_for_instance(instance: Dictionary) -> Dictionary:
	return DataRegistry.get_equipment(String(instance.get("equipment_id", "")))


func get_wearers() -> Array[Dictionary]:
	var wearers: Array[Dictionary] = [{"id": "protagonist", "name": "Protagonist"}]
	for companion in RunState.party.companions:
		wearers.append({
			"id": String(companion.get("id", "")),
			"name": String(companion.get("name", "Companion")),
		})
	return wearers


func get_total_bonus(effect_type: String, wearer_id: String = "protagonist") -> int:
	var total := 0
	for equipped_wearer_id in equipped.keys():
		var slots: Dictionary = equipped[equipped_wearer_id]
		for instance_id in slots.values():
			var instance := get_instance(int(instance_id))
			var data := get_data_for_instance(instance)
			for effect in data.get("effects", []):
				if typeof(effect) != TYPE_DICTIONARY:
					continue
				if String(effect.get("type", "")) != effect_type:
					continue
				var scope := String(effect.get("scope", "team"))
				if scope == "team" or (scope == "wearer" and String(equipped_wearer_id) == wearer_id):
					total += int(effect.get("amount", 0))
	return total


func get_equipped_lines() -> Array[String]:
	var lines: Array[String] = []
	for wearer in get_wearers():
		var wearer_id := String(wearer.get("id", ""))
		var slots: Dictionary = equipped.get(wearer_id, {})
		var slot_parts: Array[String] = []
		for slot in DataRegistry.get_balance("equipment.slots", ["helmet", "armor", "weapon"]):
			var instance_id := int(slots.get(String(slot), 0))
			if instance_id == 0:
				slot_parts.append("%s: empty" % String(slot))
			else:
				var item := get_data_for_instance(get_instance(instance_id))
				slot_parts.append("%s: %s" % [String(slot), item.get("name", "?")])
		lines.append("%s - %s" % [wearer.get("name", "Wearer"), " / ".join(PackedStringArray(slot_parts))])
	return lines


func get_inventory_lines() -> Array[String]:
	var lines: Array[String] = []
	for instance in owned_items:
		var data := get_data_for_instance(instance)
		var wearer := _get_equipped_wearer(int(instance.get("instance_id", 0)))
		var equipped_text := "inventory" if wearer.is_empty() else "on %s" % _wearer_name(wearer)
		lines.append("#%d %s [%s] - %s" % [
			int(instance.get("instance_id", 0)),
			data.get("name", "Equipment"),
			data.get("slot", "?"),
			equipped_text,
		])
	return lines


func to_dict() -> Dictionary:
	return {
		"owned_items": owned_items.duplicate(true),
		"equipped": equipped.duplicate(true),
		"next_instance_id": next_instance_id,
		"card_remove_count": card_remove_count,
	}


func from_dict(data: Dictionary) -> void:
	owned_items = []
	for instance in data.get("owned_items", []):
		if typeof(instance) == TYPE_DICTIONARY:
			owned_items.append(instance)
	var restored_equipped: Variant = data.get("equipped", {})
	equipped = restored_equipped if typeof(restored_equipped) == TYPE_DICTIONARY else {}
	next_instance_id = int(data.get("next_instance_id", owned_items.size() + 1))
	card_remove_count = int(data.get("card_remove_count", 0))


func _ensure_wearer(wearer_id: String) -> void:
	if not equipped.has(wearer_id) or typeof(equipped[wearer_id]) != TYPE_DICTIONARY:
		equipped[wearer_id] = {}


func _unequip_instance(instance_id: int) -> void:
	for wearer_id in equipped.keys():
		var slots: Dictionary = equipped[wearer_id]
		for slot in slots.keys():
			if int(slots[slot]) == instance_id:
				slots.erase(slot)
				equipped[wearer_id] = slots
				return


func _get_equipped_wearer(instance_id: int) -> String:
	for wearer_id in equipped.keys():
		var slots: Dictionary = equipped[wearer_id]
		for equipped_instance_id in slots.values():
			if int(equipped_instance_id) == instance_id:
				return String(wearer_id)
	return ""


func _wearer_index(wearers: Array[Dictionary], wearer_id: String) -> int:
	for i in range(wearers.size()):
		if String(wearers[i].get("id", "")) == wearer_id:
			return i
	return -1


func _wearer_name(wearer_id: String) -> String:
	for wearer in get_wearers():
		if String(wearer.get("id", "")) == wearer_id:
			return String(wearer.get("name", wearer_id))
	return wearer_id
