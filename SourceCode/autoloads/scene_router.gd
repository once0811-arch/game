extends Node

const MAIN_SCENE := "res://scenes/main/main.tscn"
const MAP_SCENE := "res://scenes/map/map_screen.tscn"
const ASSET_GALLERY_SCENE := "res://scenes/debug/asset_gallery.tscn"


func go_to_main() -> void:
	_change_to(MAIN_SCENE)


func go_to_map() -> void:
	_change_to(MAP_SCENE)


func open_asset_gallery() -> void:
	_change_to(ASSET_GALLERY_SCENE)


func start_new_run() -> void:
	RunState.start_new_run()
	go_to_map()


func _change_to(scene_path: String) -> void:
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Scene change failed %s: %s" % [scene_path, error])
