extends CanvasLayer

@onready var survival_time_label = $ColorRect/SurvivalTime
@onready var best_time_label = $ColorRect/BestTime

var main_scene_path = "res://scenes/gameplay.tscn"

func _ready():
	hide()

func show_screen(survival_time: float, best_time: float):
	var seconds = int(survival_time)
	var msec = int(fmod(survival_time, 1) * 100)
	survival_time_label.text = "Survival Time: %02d.%02d" % [seconds, msec]
	
	var best_seconds = int(best_time)
	var best_msec = int(fmod(best_time, 1) * 100)
	best_time_label.text = "Best Time: %02d.%02d" % [best_seconds, best_msec]
	
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event):
	if visible and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			restart_game()

func restart_game():
	hide()
	get_tree().change_scene_to_file(main_scene_path)
