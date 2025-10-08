extends Area3D

var speed = 20.0
var direction = Vector3.ZERO
var damage = 100

@onready var lifetime = $LifetimeTimer.wait_time

func _ready():
	# START LIFETIME
	$LifetimeTimer.start(lifetime)
	
	# Connect signals
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# Move the projectile
	global_position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif body.is_in_group("bullet"):
		queue_free()
		
func _on_lifetime_timer_timeout() -> void:
	queue_free()
