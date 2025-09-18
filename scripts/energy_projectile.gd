extends Area3D

var speed = 8.0
var direction = Vector3.ZERO
var lifetime = 5.0
var damage = 100  # Set to high value for one-hit kill

func _ready():
	# Set lifetime timer
	$LifetimeTimer.start(lifetime)
	
	# Make the projectile face its direction
	if direction != Vector3.ZERO:
		look_at(global_position + direction, Vector3.UP)
		
	# Connect signals
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# Move the projectile
	global_position += direction * speed * delta

func _on_lifetime_timer_timeout():
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Kill player instantly
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif body.is_in_group("bullet"):
		# Destroyed by player bullet
		queue_free()
