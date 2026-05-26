extends Node

const PartyStateScript := preload("res://scripts/state/party_state.gd")
const DeckStateScript := preload("res://scripts/state/deck_state.gd")
const CombatStateScript := preload("res://scripts/state/combat_state.gd")
const EquipmentInventoryScript := preload("res://scripts/systems/equipment_inventory.gd")

var is_run_active := false
var run_seed := 0
var act := 1
var depth := 0
var gold := 0
var current_hp := 1
var max_hp := 1
var protagonist_upgrade_level := 0
var run_complete := false
var phase_note := "No active run."
var party = PartyStateScript.new()
var deck = DeckStateScript.new()
var combat = CombatStateScript.new()
var equipment = EquipmentInventoryScript.new()


func start_new_run() -> void:
	var starting: Dictionary = DataRegistry.get_balance("run", {})
	is_run_active = true
	run_seed = RngService.randomize_seed()
	act = int(starting.get("starting_act", 1))
	depth = int(starting.get("starting_depth", 0))
	gold = int(starting.get("starting_gold", 80))
	max_hp = int(starting.get("starting_max_hp", 75))
	current_hp = max_hp
	protagonist_upgrade_level = 0
	run_complete = false
	phase_note = "A fresh contract begins. The road ahead is unstable."
	party.reset()
	deck.build_starting_deck(DataRegistry.get_starter_deck_ids())
	combat.reset()
	equipment.reset()


func advance_depth() -> void:
	if is_run_active:
		depth += 1


func to_snapshot() -> Dictionary:
	return {
		"is_run_active": is_run_active,
		"run_seed": run_seed,
		"act": act,
		"depth": depth,
		"gold": gold,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"protagonist_upgrade_level": protagonist_upgrade_level,
		"run_complete": run_complete,
		"phase_note": phase_note,
		"party": party.to_dict(),
		"deck": deck.to_dict(),
		"combat": combat.to_dict(),
		"equipment": equipment.to_dict(),
	}


func load_snapshot(snapshot: Dictionary) -> bool:
	if snapshot.is_empty():
		return false
	is_run_active = bool(snapshot.get("is_run_active", false))
	run_seed = int(snapshot.get("run_seed", 0))
	act = int(snapshot.get("act", 1))
	depth = int(snapshot.get("depth", 0))
	gold = int(snapshot.get("gold", 0))
	current_hp = int(snapshot.get("current_hp", 1))
	max_hp = int(snapshot.get("max_hp", max(current_hp, 1)))
	protagonist_upgrade_level = int(snapshot.get("protagonist_upgrade_level", 0))
	run_complete = bool(snapshot.get("run_complete", false))
	phase_note = String(snapshot.get("phase_note", "Loaded Phase 1 snapshot."))
	RngService.set_run_seed(run_seed)

	var party_data: Dictionary = snapshot.get("party", {})
	var deck_data: Dictionary = snapshot.get("deck", {})
	var combat_data: Dictionary = snapshot.get("combat", {})
	var equipment_data: Dictionary = snapshot.get("equipment", {})
	party.from_dict(party_data)
	deck.from_dict(deck_data)
	combat.from_dict(combat_data)
	equipment.from_dict(equipment_data)
	return is_run_active
