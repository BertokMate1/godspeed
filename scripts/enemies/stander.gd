extends CharacterBody3D

@onready var nav = $NavigationAgent3D

var health = 60
var gravity = 9.8
var damage = 0

var player_node

func _ready():
	player_node = get_tree().get_first_node_in_group("player")
	add_to_group("enemy")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Check for collisions with player after moving
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("player"):
			if collider.has_method("take_damage"):
				collider.take_damage(damage)

func take_damage(amount):
	health -= amount
	if health <= 0:
		queue_free()

func get_health():
	return health

func set_health(new_health):
	health = new_health

func scale_health(multiplier):
	health *= multiplier
