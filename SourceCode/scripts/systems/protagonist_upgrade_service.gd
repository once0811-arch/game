class_name ProtagonistUpgradeService
extends RefCounted

const EventResolverScript := preload("res://scripts/systems/event_resolver.gd")

var event_resolver = EventResolverScript.new()


func get_options(source: String) -> Array[Dictionary]:
	if source == "act2_boss":
		return [
			{
				"id": "major_protagonist",
				"title": "Mercenary Promotion",
				"description": "Max HP +10, heal 10, and upgrade a card.",
				"effects": [{"type": "max_hp", "amount": 10}, {"type": "upgrade_card"}],
			},
			{
				"id": "major_companions",
				"title": "Shared Command",
				"description": "All companions gain 20 bond and +1 basic attack.",
				"effects": [{"type": "bond_gain", "amount": 20}, {"type": "companion_attack_bonus", "amount": 1}],
			},
			{
				"id": "major_armory",
				"title": "Regent's Armory",
				"description": "Gain a random rare equipment.",
				"effects": [{"type": "gain_equipment", "rarities": ["rare"]}],
			},
		]
	return [
		{
			"id": "minor_protagonist",
			"title": "Field Conditioning",
			"description": "Max HP +5 and heal 5.",
			"effects": [{"type": "max_hp", "amount": 5}],
		},
		{
			"id": "minor_companion_bond",
			"title": "Shared Watch",
			"description": "All companions gain 10 bond.",
			"effects": [{"type": "bond_gain", "amount": 10}],
		},
		{
			"id": "minor_card_refine",
			"title": "Sharpen the Plan",
			"description": "Upgrade the first unupgraded card.",
			"effects": [{"type": "upgrade_card"}],
		},
	]


func apply_option(option: Dictionary) -> Array[String]:
	var logs: Array[String] = []
	for effect in option.get("effects", []):
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		match String(effect.get("type", "")):
			"max_hp":
				var amount := int(effect.get("amount", 0))
				RunState.max_hp += amount
				RunState.current_hp = min(RunState.current_hp + amount, RunState.max_hp)
				RunState.protagonist_upgrade_level += 1
				logs.append("Max HP +%d." % amount)
			"companion_attack_bonus":
				logs.append_array(_gain_companion_attack_bonus(int(effect.get("amount", 0))))
			_:
				logs.append_array(event_resolver.apply_effects([effect]))
	return logs


func _gain_companion_attack_bonus(amount: int) -> Array[String]:
	var logs: Array[String] = []
	if RunState.party.companions.is_empty():
		logs.append("No companions to strengthen.")
		return logs
	for i in range(RunState.party.companions.size()):
		var companion: Dictionary = RunState.party.companions[i]
		companion["attack_bonus"] = int(companion.get("attack_bonus", 0)) + amount
		RunState.party.companions[i] = companion
		logs.append("%s basic attack +%d." % [companion.get("name", "Companion"), amount])
	return logs
