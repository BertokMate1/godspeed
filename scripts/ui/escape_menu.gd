extends Control

func _ready():
	hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().paused = false
		hide()
		get_viewport().set_input_as_handled()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _on_main_exit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/mainmenu.tscn")

func _on_game_exit_pressed() -> void:
	get_tree().quit()
