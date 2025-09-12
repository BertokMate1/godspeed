extends CharacterBody3D

# Enemy properties
var health = 50
var speed = 3.0
var player_detection_range = 20.0
var too_close_range = 5.0
var attack_range = 15.0
var attack_cooldown = 3.0
var can_attack = true
var teleport_cooldown = 2.0
var can_teleport = true

# Navigation
@onready var nav_agent = $NavigationAgent3D
var gravity = 9.8

# Projectile
var projectile_scene = preload("res://scenes/energy_projectile.tscn")

# References
var player = null

func _ready():
	# Find the player
	player = get_tree().get_first_node_in_group("player")
	# Add to enemy group for targeting
	add_to_group("enemy")
	
	# Connect signals
	$AttackCooldown.timeout.connect(_on_attack_cooldown_timeout)
	$TeleportCooldown.timeout.connect(_on_teleport_cooldown_timeout)
	
	# Start with a random attack cooldown offset
	attack_cooldown = randf_range(2.0, 4.0)

func _physics_process(delta):
	if not is_inside_tree() or player == null:
		return
		
	# Handle gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	# Check if player is too close (teleport condition)
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player < too_close_range and can_teleport:
		teleport_away()
		
	# Move toward player but maintain distance
	if distance_to_player > attack_range:
		# Move toward player
		nav_agent.target_position = player.global_position
		var next_pos = nav_agent.get_next_path_position()
		var dir = (next_pos - global_position).normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		# Stop moving when in attack range
		velocity.x = 0
		velocity.z = 0
		
		# Attack if cooldown is ready
		if can_attack:
			attack()
	
	move_and_slide()

func attack():
	can_attack = false
	# Create and launch projectile
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector3(0, 1, 0)  # Shoot from slightly above
	projectile.direction = (player.global_position - global_position).normalized()
	
	# Start cooldown timer
	$AttackCooldown.start(attack_cooldown)

func teleport_away():
	can_teleport = false
	$TeleportCooldown.start(teleport_cooldown)
	
	# Calculate a position away from the player but within navigation bounds
	var direction_away = (global_position - player.global_position).normalized()
	var teleport_distance = randf_range(8.0, 12.0)
	var target_position = global_position + direction_away * teleport_distance
	
	# Ensure the target position is at least at ground level
	target_position.y = max(target_position.y, 0.5)  # Don't go below ground level
	
	# Use NavigationAgent to find a valid position on the navigation mesh
	nav_agent.target_position = target_position
	var valid_position = nav_agent.get_next_path_position()
	
	# Add a small vertical offset to ensure we're above ground
	valid_position.y += 0.5
	
	# Teleport to the validated position
	global_position = valid_position

func take_damage(amount):
	health -= amount
	if health <= 0:
		queue_free()

func _on_attack_cooldown_timeout():
	can_attack = true

func _on_teleport_cooldown_timeout():
	can_teleport = true
