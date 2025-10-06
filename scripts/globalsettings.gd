extends Node

var spawn_mode: String = "time_based"
var mouse_sensitivity: float = 0.25

#SIGNALS TO NOTIFY ABOUT SETTINGS CHANGE
signal spawn_mode_changed(new_mode)
signal sensitivity_changed(new_sensitivity)

#UPDATE SPAWN MODE
func set_spawn_mode(new_mode: String):
	if spawn_mode != new_mode:
		spawn_mode = new_mode
		spawn_mode_changed.emit(spawn_mode)

#UPDATE MOUSE SENS
func set_mouse_sensitivity(new_sensitivity: float):
	if mouse_sensitivity != new_sensitivity:
		mouse_sensitivity = new_sensitivity
		sensitivity_changed.emit(mouse_sensitivity)
