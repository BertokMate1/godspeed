extends Node3D

@onready var target = $player
@onready var timer = $enemyspawntimer
@onready var navigation_region = $stage/NavigationRegion3D

# Preload enemy scenes
var enemy_scene = preload("res://scenes/charger.tscn")
var spectral_weaver_scene = preload("res://scenes/spectral_waver.tscn")

# Spawning parameters
var max_spawn_radius = 20.0
var min_spawn_radius = 8.0

func _ready():
	timer.wait_time = 2.0
	timer.autostart = true
	timer.timeout.connect(_on_spawn_timer_timeout)

func _process(_delta: float) -> void:
	get_tree().call_group("enemy", "target_position", target.global_transform.origin)

func _on_spawn_timer_timeout():
	spawn_enemy()

func spawn_enemy():
	var enemy
	var enemy_type = randf()
	
	if enemy_type < 0.4:
		enemy = spectral_weaver_scene.instantiate()
	else:
		enemy = enemy_scene.instantiate()
	
	add_child(enemy)
	
	var spawn_position = get_nav_valid_spawn_position()
	enemy.global_position = spawn_position
	enemy.add_to_group("enemy")

func get_nav_valid_spawn_position():
	var valid_position = Vector3.ZERO
	var attempts = 0
	var max_attempts = 10
	
	while attempts < max_attempts:
		var random_angle = randf() * 2 * PI
		var random_distance = randf_range(min_spawn_radius, max_spawn_radius)
		
		var proposed_position = target.global_position + Vector3(
			cos(random_angle) * random_distance,
			0,  # We'll get Y from navigation
			sin(random_angle) * random_distance
		)
		
		# Use navigation system to find a valid position
		var nav_map = navigation_region.get_navigation_map()
		var closest_point = NavigationServer3D.map_get_closest_point(
			nav_map, 
			proposed_position
		)
		
		# Check if the point is reasonably close to our proposed position
		if closest_point.distance_to(proposed_position) < 5.0:
			valid_position = closest_point
			break
		
		attempts += 1
	
	# Fallback
	if valid_position == Vector3.ZERO:
		valid_position = target.global_position + Vector3(0, 0, -min_spawn_radius)
	
	return valid_position
