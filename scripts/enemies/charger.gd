extends CharacterBody3D

# NODES
@onready var nav = $NavigationAgent3D

# BASE STATS
var health = 30
var base_speed = 7.5
var speed = base_speed
var gravity = 9.8
var damage = 100

# PLAYER REFERENCE
var player_node

# TIMER / ACCELERATION SETTINGS
var time_since_spawn := 0.0
var ignore_delay := 4.0               # TIME BEFORE ACCELERATION STARTS (seconds)
var acceleration_per_second := 1.0    # SPEED INCREASE PER SECOND AFTER DELAY
var max_speed := 999.0                # OPTIONAL CAP (set high to disable)

func _ready():
	# REGISTER AND CACHE PLAYER
	player_node = get_tree().get_first_node_in_group("player")
	add_to_group("enemy")

func _physics_process(delta):
	# UPDATE SPAWN TIMER (used to trigger acceleration)
	time_since_spawn += delta

	# UPDATE NAV TARGET IF PLAYER EXISTS
	if player_node:
		nav.target_position = player_node.global_position

	# APPLY ACCELERATION AFTER DELAY
	if time_since_spawn >= ignore_delay:
		speed += acceleration_per_second * delta
		if speed > max_speed:
			speed = max_speed

	# APPLY GRAVITY WHEN AIRBORNE
	if not is_on_floor():
		velocity.y -= gravity * delta

	# NAVIGATION MOVEMENT
	var next_location = nav.get_next_path_position()
	var current_location = global_transform.origin
	var dir = (next_location - current_location)
	if dir.length() > 0.001:
		var new_velocity = dir.normalized() * speed
		velocity.x = new_velocity.x
		velocity.z = new_velocity.z
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

	# COLLISION CHECKS (FIXED ITERATION)
	var slide_count = get_slide_collision_count()
	for i in range(slide_count):
		var collision = get_slide_collision(i)
		if not collision:
			continue
		var collider = collision.get_collider()
		if collider and collider.is_in_group("player"):
			if collider.has_method("take_damage"):
				collider.take_damage(damage)

# DAMAGE HANDLING
func take_damage(amount):
	health -= amount
	if health <= 0:
		# REWARD PLAYER WITH TIME ON KILL IF TIMER EXISTS
		var timer_panel = get_tree().get_first_node_in_group("survival_timer")
		if timer_panel and timer_panel.has_method("add_time"):
			timer_panel.add_time(2.0)
		queue_free()

# SIMPLE ACCESSORS
func get_health():
	return health

func set_health(new_health):
	health = new_health

func scale_health(multiplier):
	health *= multiplier
