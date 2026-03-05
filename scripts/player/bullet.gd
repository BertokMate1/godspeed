extends CharacterBody3D

var damage = 30
var speed = 50.0
var direction = Vector3.ZERO
@onready var lifetime = $LifetimeTimer.wait_time

func _ready():
	# START LIFETIME
	$LifetimeTimer.start(lifetime)

func initialize_bullet(start_position: Vector3, shoot_direction: Vector3):
	global_position = start_position
	direction = shoot_direction
	
	# MAKE THE BULLET FACE THE DIRECTION ITS MOVING
	if direction != Vector3.ZERO:
		look_at(global_position + direction, Vector3.UP)

func _physics_process(delta):
	if not is_inside_tree():
		return

	var collision = move_and_collide(direction * speed * delta)

	if collision:
		var collider = collision.get_collider()
		if collider.is_in_group("enemy"):
			GlobalSettings.record_shot_hit()
			if collider.has_method("take_damage"):
				collider.take_damage(damage)
		queue_free()

func _on_lifetime_timer_timeout() -> void:
	queue_free()
