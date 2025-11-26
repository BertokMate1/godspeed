extends Control

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/gameplay.tscn")

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/options_menu.tscn")

func _on_leaderboards_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/leaderboard.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
