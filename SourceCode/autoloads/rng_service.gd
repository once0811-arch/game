extends Node

var rng := RandomNumberGenerator.new()
var current_seed := 0


func _ready() -> void:
	randomize_seed()


func randomize_seed() -> int:
	rng.randomize()
	current_seed = rng.seed
	return current_seed


func set_run_seed(seed_value: int) -> void:
	current_seed = seed_value
	rng.seed = seed_value


func roll_int(min_value: int, max_value: int) -> int:
	return rng.randi_range(min_value, max_value)


func pick(items: Array, default_value: Variant = null) -> Variant:
	if items.is_empty():
		return default_value
	return items[roll_int(0, items.size() - 1)]
