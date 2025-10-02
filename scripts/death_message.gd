extends Control

var time: float = 1.5

func _process(delta) -> void:
	time -= delta
	if time <= 0:
		queue_free()
