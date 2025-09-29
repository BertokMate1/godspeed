extends CanvasLayer

@onready var anim_player: AnimationPlayer = $AnimationPlayer

func fade_to_main_menu() -> void:
	# Play fade animation
	anim_player.play("fade")
	await anim_player.animation_finished

	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
	
	# Remove the fade overlay to prevent black screen
	queue_free()
