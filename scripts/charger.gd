extends CharacterBody3D

@onready var nav = $NavigationAgent3D
var speed = 5.5
var gravity = 9.8
var damage = 100  # Damage to player on contact

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0  # Reset vertical velocity when on floor
	
	var next_location = nav.get_next_path_position()
	var current_location = global_transform.origin
	var new_velocity = (next_location - current_location).normalized() * speed
	
	velocity.x = new_velocity.x
	velocity.z = new_velocity.z
	
	move_and_slide()
	
	# Check for collisions with player after moving
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("player"):
			if collider.has_method("take_damage"):
				collider.take_damage(damage)  # Damage player on contact

func target_position(target):
	nav.target_position = target
