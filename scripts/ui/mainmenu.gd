extends Control

#NODES
@onready var name_input = $Name
@onready var save_name_button = $Save

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	#SET CURRENT PLAYER NAME IN INPUT FIELD
	name_input.text = GlobalSettings.get_player_name()
	
	#CONNECT SIGNALS
	save_name_button.pressed.connect(_on_save_name_button_pressed)
	name_input.text_submitted.connect(_on_name_text_submitted)

#SAVE NAME BUTTON PRESSED
func _on_save_name_button_pressed():
	save_player_name()

#NAME INPUT SUBMITTED
func _on_name_text_submitted(_new_text):
	save_player_name()

#SAVE PLAYER NAME
func save_player_name():
	var new_name = name_input.text
	GlobalSettings.set_player_name(new_name)
	
	#SHOW CONFIRMATION MESSAGE
	save_name_button.text = "Saved!"
	await get_tree().create_timer(1.0).timeout
	save_name_button.text = "Save"

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/gameplay.tscn")

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/options_menu.tscn")

func _on_leaderboards_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/leaderboard.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
