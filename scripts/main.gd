extends Node3D

# NODES
@onready var timer = $enemyspawntimer
@onready var wave_timer = $WaveTimer
@onready var wave_spawn_timer = $WaveSpawnTimer
@onready var navigation_region = $stage/NavigationRegion3D

# ENEMIES
var charger_scene = preload("res://scenes/enemies/charger.tscn")
var spectral_weaver_scene = preload("res://scenes/enemies/spectral_waver.tscn")
var stander_scene = preload("res://scenes/enemies/stander.tscn")

# SPAWNING MODE
enum SpawnMode { TIME_BASED, WAVE_BASED }
var current_spawn_mode = SpawnMode.TIME_BASED

# TIME SCALING MODE
var min_spawn_time = 0.5
var spawn_time_decrease = 0.5
var time_between_decreases = 2.5
var difficulty_timer = 0.0
var elapsed_time = 0.0

# WAVE BASED MODE
var current_wave = 0
var enemies_remaining_in_wave = 0
var enemies_to_spawn_this_wave = 0
var wave_in_progress = false

# WAVE PROGRESSION
var base_enemies_per_wave = 3
var enemies_increase_per_wave = 5
var max_enemies_per_wave = 999
var health_increase_per_wave = 0.2

# SPAWN AREA
var max_spawn_radius = 30.0
var min_spawn_radius = 10.0
var spawn_center = Vector3.ZERO
var spawn_radius = 15.0

# PROTECTED ZONE AROUND PLAYER
var player_protected_radius = 8.0
var max_spawn_attempts = 20

# SPAWN CAP
var max_active_enemies = 30

# THREAT DENSITY SAMPLING
var threat_density_timer = 0.0
const THREAT_DENSITY_INTERVAL = 2.0

func _ready():
	# RESET SURVIVAL TIMER
	var timer_panel = get_tree().get_first_node_in_group("survival_timer")
	if timer_panel and timer_panel.has_method("reset"):
		timer_panel.reset()
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# TIMER SETUP
	timer.timeout.connect(_on_spawn_timer_timeout)
	wave_timer.timeout.connect(start_next_wave)
	wave_spawn_timer.timeout.connect(_spawn_next_enemy_in_wave)
	
	# BASE SPAWN MODE
	set_spawn_mode_from_string(GlobalSettings.spawn_mode)
	
	# SAVE MOUSE SENS FOR PLAYER
	var player = get_tree().get_first_node_in_group("player")
	if player and "mouse_sens" in player:
		player.mouse_sens = GlobalSettings.mouse_sensitivity
		
	add_to_group("spawn_manager")
	
	# SETTINGS CHANGE LISTENING
	GlobalSettings.spawn_mode_changed.connect(set_spawn_mode_from_string)
	GlobalSettings.sensitivity_changed.connect(_on_sensitivity_changed)

func get_current_wave() -> int:
	return current_wave

func _on_sensitivity_changed(new_sensitivity):
	var player = get_tree().get_first_node_in_group("player")
	if player and "mouse_sens" in player:
		player.mouse_sens = new_sensitivity

# RETURNS CURRENT NUMBER OF ALIVE ENEMIES IN THE SCENE
func get_active_enemy_count() -> int:
	return get_tree().get_nodes_in_group("enemy").size()

# SPAWN SYSTEM CONTROL
func set_spawn_mode(mode):
	timer.stop()
	wave_timer.stop()
	wave_spawn_timer.stop()
	
	wave_in_progress = false
	current_spawn_mode = mode
	
	match mode:
		SpawnMode.TIME_BASED:
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
		# ONLY SPAWN IF UNDER THE ACTIVE ENEMY CAP
		if get_active_enemy_count() < max_active_enemies:
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
		if get_active_enemy_count() < max_active_enemies:
			# CAP NOT REACHED — SPAWN ENEMY AND DECREASE COUNTER
			var enemy = await spawn_enemy()
			if enemy:
				# ENEMY HEALTH SCALING
				var health_multiplier = 1.0 + (current_wave - 1) * health_increase_per_wave
				if enemy.has_method("scale_health"):
					enemy.scale_health(health_multiplier)
			enemies_to_spawn_this_wave -= 1
		else:
			# CAP REACHED — DO NOT DECREASE COUNTER, RETRY AFTER TIMER
			wave_spawn_timer.start()
			return
		
		if enemies_to_spawn_this_wave > 0:
			wave_spawn_timer.start()

# ENEMY SPAWN FUNC
func spawn_enemy():
	var enemy
	var enemy_type = randf()
	
	# CALCULATE DIFFICULTY FACTOR (0.0 = EARLY GAME, 1.0 = LATE GAME)
	var difficulty_factor: float
	if current_spawn_mode == SpawnMode.WAVE_BASED:
		# IN WAVE MODE: SCALE OVER 10 WAVES
		difficulty_factor = clamp(float(current_wave) / 10.0, 0.0, 1.0)
	else:
		# IN TIME MODE: SCALE OVER 120 SECONDS USING ELAPSED TIME
		difficulty_factor = clamp(elapsed_time / 120.0, 0.0, 1.0)
	
	# DYNAMIC SPAWN RATIOS
	# STANDER:         60% -> 20%
	# CHARGER:         30% -> 40%
	# SPECTRAL WEAVER: 10% -> 40%
	var stander_chance = lerp(0.6, 0.2, difficulty_factor)
	var charger_chance = lerp(0.3, 0.4, difficulty_factor)
	# SPECTRAL WEAVER GETS THE REMAINDER
	
	if enemy_type < stander_chance:
		enemy = stander_scene.instantiate()
	elif enemy_type < stander_chance + charger_chance:
		enemy = charger_scene.instantiate()
	else:
		enemy = spectral_weaver_scene.instantiate()
	
	add_child(enemy)
	
	var spawn_position = await get_nav_valid_spawn_position()
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
		if current_spawn_mode == SpawnMode.WAVE_BASED and wave_in_progress:
			enemies_remaining_in_wave -= 1
			if enemies_remaining_in_wave <= 0:
				wave_in_progress = false
			wave_timer.start()

func _process(delta: float) -> void:
	# DIFF INCREASE FOR TIME BASED
	if current_spawn_mode == SpawnMode.TIME_BASED:
		elapsed_time += delta
		difficulty_timer += delta
		if difficulty_timer >= time_between_decreases:
			difficulty_timer = 0.0
			increase_difficulty()

	# THREAT DENSITY SAMPLING — RECORD ACTIVE ENEMY COUNT EVERY 2 SECONDS
	threat_density_timer += delta
	if threat_density_timer >= THREAT_DENSITY_INTERVAL:
		threat_density_timer = 0.0
		GlobalSettings.record_threat_density(get_active_enemy_count())

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().paused = true
		$PauseMenu.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()

# WEIGHTED SPAWN ANGLE — NEVER FROM THE FRONT
func _get_weighted_spawn_angle(player: Node3D) -> float:
	# PLAYER'S CURRENT FACING DIRECTION (Y AXIS ROTATION)
	var player_forward_angle = player.rotation.y
	# FRONT EXCLUSION ZONE — 60 DEGREES IN FRONT OF PLAYER
	var front_exclusion = deg_to_rad(60)
	
	var angle: float
	var attempts = 0
	while attempts < 20:
		angle = randf() * TAU
		# DIFFERENCE BETWEEN PROPOSED ANGLE AND THE PLAYER'S BACK DIRECTION
		var diff = abs(wrapf(angle - (player_forward_angle + PI), -PI, PI))
		# ACCEPT ANGLE ONLY IF IT FALLS OUTSIDE THE FRONT EXCLUSION ZONE
		if diff > front_exclusion:
			return angle
		attempts += 1
	# FALLBACK: SPAWN DIRECTLY BEHIND PLAYER
	return player_forward_angle + PI

# VALID SPAWN POSITION WITH PLAYER PROTECTION + DIRECTIONAL WEIGHTING
func get_nav_valid_spawn_position():
	var player = get_tree().get_first_node_in_group("player")
	var player_position = Vector3.ZERO
	if player:
		player_position = player.global_position

	var attempts = 0
	var valid_position_found = false
	var spawn_position = Vector3.ZERO

	# HOW MANY FRAMES WE'RE WILLING TO WAIT FOR NAV MAP TO SYNC
	const WAIT_FRAMES := 8

	while attempts < max_spawn_attempts and not valid_position_found:
		# USE WEIGHTED ANGLE SO ENEMIES SPAWN FROM SIDES AND BEHIND, NEVER FROM THE FRONT
		var random_angle: float
		if player:
			random_angle = _get_weighted_spawn_angle(player)
		else:
			random_angle = randf() * TAU

		var random_distance = randf_range(min_spawn_radius, max_spawn_radius)

		var proposed_position = spawn_center + Vector3(
			cos(random_angle) * random_distance,
			0,
			sin(random_angle) * random_distance
		)

		# CHECK IF POSITION IS TOO CLOSE TO PLAYER
		if player:
			var distance_to_player = proposed_position.distance_to(player_position)
			if distance_to_player < player_protected_radius:
				attempts += 1
				continue

		# USE NAVIGATION SYSTEM TO VALIDATE POSITION
		if navigation_region and navigation_region.has_method("get_navigation_map"):
			var nav_map = navigation_region.get_navigation_map()
			var waited_frames = 0
			var map_ready := false

			# WAIT UNTIL THE NAVIGATION MAP HAS COMPLETED AT LEAST ONE ITERATION
			while waited_frames < WAIT_FRAMES:
				if nav_map and nav_map != RID():
					var iter_id = NavigationServer3D.map_get_iteration_id(nav_map)
					if iter_id > 0:
						map_ready = true
						break
				nav_map = navigation_region.get_navigation_map()
				waited_frames += 1
				await get_tree().process_frame

			if map_ready:
				# SNAP PROPOSED POSITION TO THE NEAREST VALID POINT ON THE NAV MESH
				var correct_position = NavigationServer3D.map_get_closest_point(nav_map, proposed_position)

				# RE-CHECK PLAYER DISTANCE AFTER NAVIGATION CORRECTION
				if player:
					var corrected_distance_to_player = correct_position.distance_to(player_position)
					if corrected_distance_to_player < player_protected_radius:
						attempts += 1
						continue

				correct_position.y += 1.0
				spawn_position = correct_position
				valid_position_found = true
			else:
				# NAV MAP NOT READY AFTER WAIT — USE PROPOSED POSITION AS FALLBACK
				spawn_position = proposed_position
				valid_position_found = true
		else:
			# FALLBACK WITHOUT NAVIGATION
			spawn_position = proposed_position
			valid_position_found = true

		attempts += 1

	# IF WE COULDN'T FIND A VALID POSITION AFTER MAX ATTEMPTS, USE DIRECTIONAL FALLBACK
	if not valid_position_found:
		var fallback_angle: float
		if player:
			fallback_angle = _get_weighted_spawn_angle(player)
		else:
			fallback_angle = randf() * TAU

		var random_distance = randf_range(min_spawn_radius, max_spawn_radius)
		var proposed_position = spawn_center + Vector3(
			cos(fallback_angle) * random_distance,
			0,
			sin(fallback_angle) * random_distance
		)

		# TRY SNAPPING TO NAV MESH ONCE MORE IF AVAILABLE AND READY
		if navigation_region and navigation_region.has_method("get_navigation_map"):
			var nav_map = navigation_region.get_navigation_map()
			if nav_map and nav_map != RID() and NavigationServer3D.map_get_iteration_id(nav_map) > 0:
				var correct_position = NavigationServer3D.map_get_closest_point(nav_map, proposed_position)
				correct_position.y += 1.0
				return correct_position
		# FINAL FALLBACK
		return proposed_position

	return spawn_position
