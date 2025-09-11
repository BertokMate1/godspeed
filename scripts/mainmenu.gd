extends Control

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/gameplay.tscn")


func _on_options_pressed() -> void:
	print("option")


func _on_leaderboards_pressed() -> void:
	print("leaderboard")


func _on_exit_pressed() -> void:
	get_tree().quit()
