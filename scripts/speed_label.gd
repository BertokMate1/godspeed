extends Control

@onready var label = $Label

func update_speed(current_speed: float, max_speed: float) -> void:
	label.text = "Speed: " + str(snapped(current_speed, 0.1)) + " u/s\nMax: " + str(snapped(max_speed, 0.1)) + " u/s"

func _on_viewport_resize():
	pass
