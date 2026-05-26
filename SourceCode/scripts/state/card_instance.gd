class_name CardInstance
extends RefCounted


static func create(instance_id: int, card_id: String) -> Dictionary:
	return {
		"instance_id": instance_id,
		"card_id": card_id,
		"upgraded": false,
	}


static func get_card_id(instance: Dictionary) -> String:
	return String(instance.get("card_id", ""))


static func get_card_instance_id(instance: Dictionary) -> int:
	return int(instance.get("instance_id", 0))
