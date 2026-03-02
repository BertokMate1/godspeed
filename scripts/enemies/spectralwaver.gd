extends CharacterBody3D

# Enemy properties
var health = 30
var too_close_range = 100.0
var can_attack = true
var can_teleport = true
var min_height = 2.0  # Minimum hover height
var max_height = 4.0  # Maximum hover height
var min_teleport_distance = 10.0
var max_teleport_distance = 15.0

# Player protected zone
var player_protected_radius = 12
var max_teleport_attempts = 20 

# Navigation reference
@onready var navigation_region = get_node("/root/Main/stage/NavigationRegion3D")
@onready var attack_cooldown = $AttackCooldown.wait_time
@onready var teleport_cooldown = $TeleportCooldown.wait_time

# Projectile
var projectile_scene = preload("res://scenes/enemies/energy_projectile.tscn")

# References
var timer_panel
var player = null
var initial_height_set = false

func _ready():
	# Find the player
	player = get_tree().get_first_node_in_group("player")
	# Add to enemy group for targeting
	add_to_group("enemy")
	
	# Connect signals
	$AttackCooldown.timeout.connect(_on_attack_cooldown_timeout)
	$TeleportCooldown.timeout.connect(_on_teleport_cooldown_timeout)
	
	# Use call_deferred to set initial height after the main script sets position
	call_deferred("set_initial_height")

func set_initial_height():
	# Set initial random height
	global_position.y = randf_range(min_height, max_height)
	initial_height_set = true

func _physics_process(_delta):
	if not is_inside_tree() or player == null:
		return
		
	# Ensure initial height is set (fallback in case deferred call fails)
	if not initial_height_set:
		global_position.y = randf_range(min_height, max_height)
		initial_height_set = true
		
	# Check if player is too close (teleport condition)
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player < too_close_range and can_teleport:
		teleport_to_valid_position()
		
	# Attack regardless of distance (infinite range)
	if can_attack:
		attack()

func attack():
	can_attack = false
	
	# Create and launch projectile
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	
	# Set projectile position and direction
	projectile.global_position = global_position + Vector3(0, 0.5, 0)
	projectile.direction = (player.global_position - global_position).normalized()
	
	# Start cooldown timer
	$AttackCooldown.start(attack_cooldown)

func teleport_to_valid_position():
	can_teleport = false
	$TeleportCooldown.start(teleport_cooldown)
	
	var valid_position = find_valid_teleport_position()
	
	# Apply the new position
	global_position = valid_position

# Teleport position finding with player protection
func find_valid_teleport_position():
	var valid_position = Vector3.ZERO
	var attempts = 0
	
	while attempts < max_teleport_attempts:
		# Calculate random position using spherical coordinates
		var teleport_distance = randf_range(min_teleport_distance, max_teleport_distance)
		var theta = randf() * 2 * PI  # Horizontal angle
		var phi = randf() * PI        # Vertical angle
		
		# Convert to Cartesian coordinates
		var offset_x = teleport_distance * sin(phi) * cos(theta)
		var offset_y = teleport_distance * cos(phi)
		var offset_z = teleport_distance * sin(phi) * sin(theta)
		
		# Calculate target position relative to player
		var proposed_position = player.global_position + Vector3(offset_x, offset_y, offset_z)
		
		# Check if position is too close to player
		var distance_to_player = proposed_position.distance_to(player.global_position)
		if distance_to_player < player_protected_radius:
			attempts += 1
			continue  # Try again if too close to player
		
		# Get valid position from navigation system
		var nav_valid_position = get_nav_valid_position(proposed_position)
		
		# Double-check player distance after navigation correction
		distance_to_player = nav_valid_position.distance_to(player.global_position)
		if distance_to_player < player_protected_radius:
			attempts += 1
			continue  # Try again if corrected position is still too close
		
		# Override the Y position with our random hover height instead of ground level
		nav_valid_position.y = randf_range(min_height, max_height)
		
		# Check if this position is within our game bounds
		if is_position_in_bounds(nav_valid_position):
			valid_position = nav_valid_position
			break
		
		attempts += 1
	
	# Fallback if no valid position found
	if valid_position == Vector3.ZERO:
		# Move away from player but maintain height and respect protected zone
		var direction_away = (global_position - player.global_position).normalized()
		valid_position = global_position + (direction_away * player_protected_radius * 1.5)  # Ensure outside protected zone
		valid_position.y = randf_range(min_height, max_height)
		
		# Validate fallback position
		var distance_to_player_fallback = valid_position.distance_to(player.global_position)
		if distance_to_player_fallback < player_protected_radius:
			# If still too close, use the minimum teleport distance
			valid_position = player.global_position + (direction_away * min_teleport_distance)
			valid_position.y = randf_range(min_height, max_height)
	
	return valid_position

func get_nav_valid_position(proposed_position: Vector3) -> Vector3:
	if navigation_region and navigation_region.has_method("get_navigation_map"):
		var nav_map = navigation_region.get_navigation_map()
		var closest_point = NavigationServer3D.map_get_closest_point(nav_map, proposed_position)
		return closest_point
	else:
		# Fallback: try to get any navigation map
		var maps = NavigationServer3D.get_maps()
		if maps.size() > 0:
			var closest_point = NavigationServer3D.map_get_closest_point(maps[0], proposed_position)
			return closest_point
	
	# Ultimate fallback - return the proposed position
	return proposed_position

func is_position_in_bounds(check_position: Vector3) -> bool:
	# Define play area boundaries
	var play_area_center = Vector3.ZERO  
	var max_play_radius = 45.0
	
	# Check horizontal distance from center
	var horizontal_distance = Vector2(check_position.x, check_position.z).distance_to(Vector2(play_area_center.x, play_area_center.z))
	
	# Check height bounds
	var valid_height = check_position.y >= min_height && check_position.y <= max_height * 1.5
	
	return horizontal_distance <= max_play_radius && valid_height

func take_damage(amount):
	timer_panel = get_tree().get_first_node_in_group("survival_timer")
	
	health -= amount
	if health <= 0:
		timer_panel.add_time(4.0) # add 4 seconds when this enemy dies
		queue_free()

func _on_attack_cooldown_timeout():
	can_attack = true

func _on_teleport_cooldown_timeout():
	can_teleport = true
	
func get_health():
	return health

func set_health(new_health):
	health = new_health

func scale_health(multiplier):
	health *= multiplier
