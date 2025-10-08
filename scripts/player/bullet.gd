extends CharacterBody3D

var damage = 30
var speed = 40.0
var direction = Vector3.ZERO

@onready var lifetime = $LifetimeTimer.wait_time

func _ready():
	# START LIFETIME
	$LifetimeTimer.start(lifetime)
	
# Initialization function
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
			if collision.get_collider().has_method("take_damage"):
				collision.get_collider().take_damage(damage)
		queue_free() # bullet disappear
		
func _on_lifetime_timer_timeout() -> void:
	queue_free()
