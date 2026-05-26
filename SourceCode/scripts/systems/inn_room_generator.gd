class_name InnRoomGenerator
extends RefCounted


func generate_rooms() -> Dictionary:
	var inn_type := _roll_inn_type()
	var pool := _event_rooms() if inn_type == "event" else _normal_rooms()
	var count := int(DataRegistry.get_balance("inn.room_options", 3))
	var rooms: Array[Dictionary] = []
	var used := {}
	while rooms.size() < count and used.size() < pool.size():
		var room: Dictionary = RngService.pick(pool, {})
		var room_id := String(room.get("id", ""))
		if room_id.is_empty() or used.has(room_id):
			continue
		used[room_id] = true
		rooms.append(room.duplicate(true))
	return {
		"type": inn_type,
		"title": "Suspicious Inn" if inn_type == "event" else "Road Inn",
		"rooms": rooms,
	}


func _roll_inn_type() -> String:
	var normal := int(DataRegistry.get_balance("inn.normal_weight", 2))
	var event := int(DataRegistry.get_balance("inn.event_weight", 1))
	var roll := RngService.roll_int(1, max(normal + event, 1))
	return "event" if roll > normal else "normal"


func _normal_rooms() -> Array[Dictionary]:
	return [
		{
			"id": "small_room",
			"name": "Small Room",
			"price": 35,
			"description": "Recover 22% of max HP.",
			"effects": [{"type": "heal_percent", "percent": 22}],
		},
		{
			"id": "good_room",
			"name": "Good Room",
			"price": 80,
			"description": "Recover 45% of max HP.",
			"effects": [{"type": "heal_percent", "percent": 45}],
		},
		{
			"id": "noble_room",
			"name": "Noble Room",
			"price": 125,
			"description": "Recover 70% of max HP.",
			"effects": [{"type": "heal_percent", "percent": 70}],
		},
	]


func _event_rooms() -> Array[Dictionary]:
	return [
		{
			"id": "free_creaking_room",
			"name": "Free Creaking Room",
			"price": 0,
			"description": "Recover 20% of max HP. 25% chance to recover fully.",
			"effects": [
				{"type": "heal_percent", "percent": 20},
				{"type": "heal_percent", "percent": 100, "chance": 25}
			],
		},
		{
			"id": "red_curtain_room",
			"name": "Red Curtain Room",
			"price": 25,
			"description": "Recover 15% of max HP. 50% chance to upgrade a card.",
			"effects": [
				{"type": "heal_percent", "percent": 15},
				{"type": "upgrade_card", "chance": 50}
			],
		},
		{
			"id": "locked_side_room",
			"name": "Locked Side Room",
			"price": 45,
			"description": "Recover 25% of max HP. 35% chance to find equipment.",
			"effects": [
				{"type": "heal_percent", "percent": 25},
				{"type": "gain_equipment", "chance": 35, "rarities": ["common", "uncommon"]}
			],
		},
		{
			"id": "banquet_bed",
			"name": "Banquet Bed",
			"price": 90,
			"description": "Recover 60% of max HP. The crowded hall leaves no room for quiet.",
			"effects": [{"type": "heal_percent", "percent": 60}],
		},
	]
