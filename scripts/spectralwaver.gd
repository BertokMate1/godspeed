extends CharacterBody3D

# Enemy properties
var health = 50
var player_detection_range = 20.0
var too_close_range = 8.0
var attack_cooldown = 3.0
var can_attack = true
var teleport_cooldown = 2.0
var can_teleport = true
var min_height = 1.5  # Minimum height
var max_height = 3.5  # Maximum height
var min_teleport_distance = 10.0  # Minimum distance from player
var max_teleport_distance = 15.0  # Maximum distance from player

# Navigation
@onready var nav_agent = $NavigationAgent3D

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
	
	# Set initial random position
	teleport_to_random_position()

func _physics_process(delta):
	if not is_inside_tree() or player == null:
		return
		
	# Check if player is too close (teleport condition)
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player < too_close_range and can_teleport:
		teleport_to_random_position()
		
	# Attack regardless of distance (infinite range)
	if can_attack:
		attack()

func attack():
	can_attack = false
	
	# Create and launch projectile
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	
	# Set projectile position and direction
	projectile.global_position = global_position + Vector3(0, 0.5, 0)  # Shoot from slightly above
	projectile.direction = (player.global_position - global_position).normalized()
	
	# Start cooldown timer
	$AttackCooldown.start(attack_cooldown)

func teleport_to_random_position():
	can_teleport = false
	$TeleportCooldown.start(teleport_cooldown)
	
	# Calculate a random distance from the player
	var teleport_distance = randf_range(min_teleport_distance, max_teleport_distance)
	
	# Calculate random angles for spherical coordinates
	var theta = randf() * 2 * PI  # Horizontal angle
	var phi = randf() * PI        # Vertical angle
	
	# Convert spherical coordinates to Cartesian coordinates
	var offset_x = teleport_distance * sin(phi) * cos(theta)
	var offset_y = teleport_distance * cos(phi)
	var offset_z = teleport_distance * sin(phi) * sin(theta)
	
	# Calculate target position relative to player
	var target_position = player.global_position + Vector3(offset_x, offset_y, offset_z)
	
	# Ensure Y position stays within reasonable bounds
	target_position.y = clamp(target_position.y, min_height, max_height)
	
	# Teleport directly to the calculated position
	global_position = target_position

func take_damage(amount):
	health -= amount
	if health <= 0:
		queue_free()

func _on_attack_cooldown_timeout():
	can_attack = true

func _on_teleport_cooldown_timeout():
	can_teleport = true
