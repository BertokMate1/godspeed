extends Node3D

#NODES
@onready var timer = $enemyspawntimer
@onready var wave_timer = $WaveTimer
@onready var wave_spawn_timer = $WaveSpawnTimer
@onready var navigation_region = $stage/NavigationRegion3D

#ENEMIES
var enemy_scene = preload("res://scenes/charger.tscn")
var spectral_weaver_scene = preload("res://scenes/spectral_waver.tscn")

#SPAWNING MODE
enum SpawnMode { TIME_BASED, WAVE_BASED }
var current_spawn_mode = SpawnMode.TIME_BASED

#TIME SCALING MODE
var base_spawn_time = 2.0
var min_spawn_time = 0.5
var spawn_time_decrease = 0.5
var time_between_decreases = 3.0
var difficulty_timer = 0.0

#WAVE BASED MODE
var current_wave = 0
var enemies_remaining_in_wave = 0
var enemies_to_spawn_this_wave = 0
var wave_in_progress = false
var time_between_waves = 3.0

#WAVE PROGRESSION
var base_enemies_per_wave = 3
var enemies_increase_per_wave = 2
var max_enemies_per_wave = 30
var health_increase_per_wave = 0.2

#SPAWN AREA
var max_spawn_radius = 20.0
var min_spawn_radius = 8.0
var spawn_center = Vector3.ZERO
var spawn_radius = 15.0

#OPTION MENU REF
var options_menu_instance = null

func _ready():
	#TIMER SETUP
	timer.wait_time = base_spawn_time
	timer.one_shot = false
	timer.timeout.connect(_on_spawn_timer_timeout)
	
	wave_timer.wait_time = time_between_waves
	wave_timer.one_shot = true
	wave_timer.timeout.connect(start_next_wave)
	
	wave_spawn_timer.wait_time = 0.5
	wave_spawn_timer.one_shot = true
	wave_spawn_timer.timeout.connect(_spawn_next_enemy_in_wave)
	
	# BASE SPAWN MODE
	set_spawn_mode_from_string(GlobalSettings.spawn_mode)
	
	#SAVE MOUSE SENS FOR PLAYER
	var player = get_tree().get_first_node_in_group("player")
	if player and "mouse_sens" in player:
		player.mouse_sens = GlobalSettings.mouse_sensitivity
	
	#SETTINGS CHANGE LISTENING
	GlobalSettings.spawn_mode_changed.connect(set_spawn_mode_from_string)
	GlobalSettings.sensitivity_changed.connect(_on_sensitivity_changed)

func _on_sensitivity_changed(new_sensitivity):
	var player = get_tree().get_first_node_in_group("player")
	if player and "mouse_sens" in player:
		player.mouse_sens = new_sensitivity

#OPTIONS MENU
func show_options_menu():
	if options_menu_instance != null:
		options_menu_instance.queue_free()
	
	var options_menu_scene = load("res://scenes/options_menu.tscn")
	options_menu_instance = options_menu_scene.instantiate()
	add_child(options_menu_instance)

# SPAWN SYSTEM CONTROL
func set_spawn_mode(mode):
	timer.stop()
	wave_timer.stop()
	wave_spawn_timer.stop()
	
	wave_in_progress = false
	current_spawn_mode = mode
	
	match mode:
		SpawnMode.TIME_BASED:
			timer.wait_time = base_spawn_time
			timer.start()
		SpawnMode.WAVE_BASED:
			current_wave = 0
			start_next_wave()

func set_spawn_mode_from_string(mode_string):
	if mode_string == "time_based":
		set_spawn_mode(SpawnMode.TIME_BASED)
	elif mode_string == "wave_based":
		set_spawn_mode(SpawnMode.WAVE_BASED)

func _on_spawn_timer_timeout():
	if current_spawn_mode == SpawnMode.TIME_BASED:
		spawn_enemy()

func increase_difficulty():
	if timer.wait_time > min_spawn_time:
		timer.wait_time -= spawn_time_decrease

func start_next_wave():
	if current_spawn_mode != SpawnMode.WAVE_BASED:
		return
	
	current_wave += 1
	wave_in_progress = true
	
	# ENEMY CALCULATION FOR WAVES
	enemies_to_spawn_this_wave = base_enemies_per_wave + (current_wave - 1) * enemies_increase_per_wave
	enemies_to_spawn_this_wave = min(enemies_to_spawn_this_wave, max_enemies_per_wave)
	enemies_remaining_in_wave = enemies_to_spawn_this_wave
	
	# START SPAWNING FOR WAVE
	_spawn_next_enemy_in_wave()

func _spawn_next_enemy_in_wave():
	if current_spawn_mode != SpawnMode.WAVE_BASED or not wave_in_progress:
		return
	
	if enemies_to_spawn_this_wave > 0:
		var enemy = spawn_enemy()
		if enemy:
			# ENEMY HEALTH SCALING
			var health_multiplier = 1.0 + (current_wave - 1) * health_increase_per_wave
			if enemy.has_method("scale_health"):
				enemy.scale_health(health_multiplier)
		
		enemies_to_spawn_this_wave -= 1
		
		if enemies_to_spawn_this_wave > 0:
			wave_spawn_timer.start()

func on_enemy_defeated():
	if current_spawn_mode == SpawnMode.WAVE_BASED and wave_in_progress:
		enemies_remaining_in_wave -= 1
		
		if enemies_remaining_in_wave <= 0:
			wave_in_progress = false
			wave_timer.start()

# ENEMY SPAWN FUNC
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
	
	# TRACKING FOR WAVE MODE
	if current_spawn_mode == SpawnMode.WAVE_BASED:
		var enemy_ref = weakref(enemy)
		if enemy.has_signal("tree_exiting"):
			enemy.tree_exiting.connect(_on_enemy_defeated.bind(enemy_ref))
	
	return enemy

func _on_enemy_defeated(enemy_ref):
	var enemy = enemy_ref.get_ref()
	if enemy:
		on_enemy_defeated()

func _process(delta: float) -> void:
	# DIFF INCREACE FOR TIME BASED
	if current_spawn_mode == SpawnMode.TIME_BASED:
		difficulty_timer += delta
		if difficulty_timer >= time_between_decreases:
			difficulty_timer = 0.0
			increase_difficulty()

# VALID SPAWN POSITION FINDING
func get_nav_valid_spawn_position():
	var random_angle = randf() * 2 * PI
	var random_distance = randf_range(0, spawn_radius)
	
	var proposed_position = spawn_center + Vector3(
		cos(random_angle) * random_distance,
		0,
		sin(random_angle) * random_distance
	)
	
	if navigation_region and navigation_region.has_method("get_navigation_map"):
		var nav_map = navigation_region.get_navigation_map()
		var correct_position = NavigationServer3D.map_get_closest_point(nav_map, proposed_position)
		
		correct_position.y += 1.0
		return correct_position
