extends CharacterBody3D

var speed = 30.0
var direction = Vector3.ZERO

# Optional initialization function
func initialize_bullet(start_position: Vector3, shoot_direction: Vector3):
	global_position = start_position
	direction = shoot_direction
	
	# Make the bullet face the direction it's moving
	if direction != Vector3.ZERO:
		look_at(global_position + direction, Vector3.UP)

func _physics_process(delta):
	# Check if bullet is still in the scene tree
	if not is_inside_tree():
		return
		
	var collision = move_and_collide(direction * speed * delta)
	if collision:
		if collision.get_collider().is_in_group("enemy"):
			collision.get_collider().queue_free() # enemy disappear
		queue_free() # bullet disappear
