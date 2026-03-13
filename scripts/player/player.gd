extends CharacterBody3D

# NODE VARIABLES
@onready var head: Node3D = $head
@onready var standing_collision_shape: CollisionShape3D = $standing_collision_shape
@onready var crouching_collision_shape: CollisionShape3D = $crouching_collision_shape
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var pos = $head/Camera3D/gun/position

# EXPORTED VARIABLES
@export var mouse_sens = 0.25

# SHOTGUN VARIABLES
var shotgun_cooldown = 0.8
var shotgun_timer = 0.0
var can_shoot_shotgun = true
var pellet_count = 5
var spread_angle = 0.05

# PISTOL FIRE RATE
var pistol_cooldown = 0.135
var pistol_timer = 0.0
var can_shoot_pistol = true

# SPEED VARIABLES
var current_speed = 10.0
var walking_speed = 10.0
var ground_accel = 20
var ground_decel = 10
var ground_friction = 6
var crouching_speed = 3.0

# SPEED COUNTER VARIABLES
var speed_counter = 0.0
var max_speed = 0.0
var speed_label = null
var speed_sample_timer = 0.0
const SPEED_SAMPLE_INTERVAL = 0.5

# AIR MOVEMENT
var air_accel = 5.0
var max_air_speed = 10.0
var air_control = 0.3

# STATES
var walking = false
var crouching = false
var sliding = false
var is_dead = false
var auto_bhop = true

# SLIDE VARIABLES
var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_direction = Vector2.ZERO
var slide_speed = 20

# LERP
var lerp_speed = 10

# JUMP
const JUMP_VELOCITY = 5.0

# CROUCH
var crouching_depth = -0.5

# HEALTH
var health = 3
var max_health = 3

# HIT FLASH
var hit_flash_timer = 0.0
const HIT_FLASH_DURATION = 0.3
var hit_overlay: ColorRect = null

# INVINCIBILITY FRAMES
var invincible = false
var invincibility_duration = 1.0
var invincibility_timer = 0.0

# DIRECTION
var direction = Vector3.ZERO
var wishdir = Vector3.ZERO

# SCENES
var bullet = load("res://scenes/player/bullet.tscn")
var speed_label_scene = preload("res://scenes/ui/speed_label.tscn")
var hp_display_scene = preload("res://scenes/ui/hp_display.tscn")
var hp_display = null

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$hitbox.body_entered.connect(_on_hitbox_body_entered)
	add_to_group("player")
	reset_player()
	call_deferred("_setup_ui")

func _setup_ui():
	# SPEED LABEL SETUP
	var label_instance = speed_label_scene.instantiate()
	get_parent().add_child(label_instance)
	speed_label = label_instance

	# HP DISPLAY SETUP
	var hp_instance = hp_display_scene.instantiate()
	get_parent().add_child(hp_instance)
	hp_display = hp_instance

	# HIT OVERLAY — RED FLASH ON DAMAGE
	hit_overlay = ColorRect.new()
	hit_overlay.color = Color(1, 0, 0, 0.0)
	hit_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var canvas = CanvasLayer.new()
	canvas.layer = 10
	canvas.add_child(hit_overlay)
	add_child(canvas)

func reset_player():
	health = max_health
	is_dead = false
	set_process_input(true)
	set_physics_process(true)

func _process(delta):
	# SHOTGUN COOLDOWN
	if not can_shoot_shotgun:
		shotgun_timer -= delta
		if shotgun_timer <= 0.0:
			can_shoot_shotgun = true

	# PISTOL COOLDOWN
	if not can_shoot_pistol:
		pistol_timer -= delta
		if pistol_timer <= 0.0:
			can_shoot_pistol = true

	# INVINCIBILITY TIMER
	if invincible:
		invincibility_timer -= delta
		if invincibility_timer <= 0.0:
			invincible = false

	# HIT FLASH FADE
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
		var alpha = (hit_flash_timer / HIT_FLASH_DURATION) * 0.4
		if hit_overlay:
			hit_overlay.color = Color(1, 0, 0, alpha)
	else:
		if hit_overlay:
			hit_overlay.color = Color(1, 0, 0, 0.0)

func _on_hitbox_body_entered(body):
	var dmg := 0
	if "damage" in body:
		dmg = body.damage
	if dmg > 0:
		take_damage(dmg)

# MOUSE MOVEMENT FOR CAMERA — CLAMPED TO +-89 DEGREES
func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_z(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.z = clamp(head.rotation.z, deg_to_rad(-89), deg_to_rad(89))

# PROPER GROUND MOVEMENT
func _handle_ground_physics(delta) -> void:
	var input_dir := Input.get_vector("backward", "forward", "left", "right")
	wishdir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# APPLY GROUND ACCELERATION
	if input_dir != Vector2.ZERO:
		var current_speed_on_ground = velocity.dot(wishdir)
		var add_speed = walking_speed - current_speed_on_ground
		if add_speed > 0:
			var accel_speed = ground_accel * delta * walking_speed
			accel_speed = min(accel_speed, add_speed)
			velocity += accel_speed * wishdir

	# APPLY FRICTION
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	var speed = horizontal_velocity.length()
	if speed > 0:
		var control = max(speed, ground_decel)
		var drop = control * ground_friction * delta
		horizontal_velocity = horizontal_velocity.normalized() * max(0, speed - drop)
		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.z

# PROPER AIR MOVEMENT
func _handle_air_physics(delta) -> void:
	# APPLY GRAVITY
	velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta

	var input_dir := Input.get_vector("backward", "forward", "left", "right")
	wishdir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if wishdir != Vector3.ZERO:
		# CALCULATE CURRENT SPEED IN DESIRED DIRECTION
		var current_speed_in_dir = velocity.dot(wishdir)
		var add_speed = max_air_speed - current_speed_in_dir

		# APPLY AIR ACCELERATION IF WE CAN ADD SPEED
		if add_speed > 0:
			var accel_speed = air_accel * delta * max_air_speed
			accel_speed = min(accel_speed, add_speed)
			velocity += accel_speed * wishdir

		# APPLY AIR CONTROL TO SLIGHTLY ADJUST VELOCITY
		var current_vel = Vector3(velocity.x, 0, velocity.z)
		if current_vel.length() > 0.1:
			var control_dir = current_vel.normalized().slerp(wishdir, air_control * delta)
			var controlled_vel = control_dir * current_vel.length()
			velocity.x = controlled_vel.x
			velocity.z = controlled_vel.z

# MAIN PHYSICS LOOP
func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_inside_tree():
		return

	# CALCULATE SPEED
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	speed_counter = horizontal_velocity.length()
	if speed_counter > max_speed:
		max_speed = speed_counter

	# SPEED SAMPLING FOR STATS
	speed_sample_timer += delta
	if speed_sample_timer >= SPEED_SAMPLE_INTERVAL:
		speed_sample_timer = 0.0
		GlobalSettings.record_speed_sample(speed_counter)

	if speed_label and speed_label.has_method("update_speed"):
		speed_label.update_speed(speed_counter, max_speed)

	# GETTING MOVEMENT INPUT
	var input_dir := Input.get_vector("backward", "forward", "left", "right")

	# IMMEDIATE RESPONSE IN AIR, LERP ON GROUND
	var new_direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if not is_on_floor():
		direction = new_direction
	else:
		direction = lerp(direction, new_direction, delta * lerp_speed)

	# CROUCH AND SLIDE LOGIC
	if Input.is_action_just_pressed("crouch") || sliding:
		current_speed = crouching_speed
		head.position.y = lerp(head.position.y, 1.0 + crouching_depth, delta * lerp_speed)
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false

		# SLIDE BEGIN
		if input_dir != Vector2.ZERO and !sliding and is_on_floor():
			sliding = true
			slide_timer = slide_timer_max
			slide_direction = input_dir
		walking = false
		crouching = true
	elif !ray_cast_3d.is_colliding():
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
		head.position.y = lerp(head.position.y, 1.0, delta * lerp_speed)
		current_speed = walking_speed
		walking = true
		sliding = false

	# HANDLE SLIDE TIMER
	if sliding:
		slide_timer -= delta
		if 0 >= slide_timer or !is_on_floor():
			sliding = false

	# JUMP AND GROUND / AIR PHYSICS
	if is_on_floor():
		if Input.is_action_just_pressed("jump") or (auto_bhop and Input.is_action_pressed("jump")):
			velocity.y = JUMP_VELOCITY
			sliding = false
		_handle_ground_physics(delta)
	else:
		_handle_air_physics(delta)

	# APPLY SLIDE VELOCITY
	if sliding:
		direction = (transform.basis * Vector3(slide_direction.x, 0, slide_direction.y)).normalized()
		velocity.x = direction.x * (slide_timer + 0.1) * slide_speed
		velocity.z = direction.z * (slide_timer + 0.1) * slide_speed

	move_and_slide()

	# PISTOL SHOOTING WITH FIRE RATE LIMIT
	if Input.is_action_just_pressed("click") and can_shoot_pistol:
		if pos and pos.is_inside_tree():
			can_shoot_pistol = false
			pistol_timer = pistol_cooldown
			GlobalSettings.record_shot_fired()
			var instance = bullet.instantiate()
			get_parent().add_child(instance)
			instance.global_position = pos.global_position
			instance.global_rotation = pos.global_rotation
			instance.direction = instance.global_transform.basis.x.normalized()

	if Input.is_action_just_pressed("shotgun") and can_shoot_shotgun:
		shoot_shotgun()

# SHOTGUN SHOOT
func shoot_shotgun():
	if not pos or not pos.is_inside_tree():
		return
	can_shoot_shotgun = false
	shotgun_timer = shotgun_cooldown
	GlobalSettings.record_shot_fired()

	# SPAWN PELLETS WITH RANDOM SPREAD
	for i in range(pellet_count):
		var instance = bullet.instantiate()
		get_parent().add_child(instance)
		instance.global_position = pos.global_position
		instance.global_rotation = pos.global_rotation
		var random_rotation = instance.global_rotation
		random_rotation.y += randf_range(-spread_angle, spread_angle)
		random_rotation.z += randf_range(-spread_angle, spread_angle)
		instance.global_rotation = random_rotation
		instance.direction = instance.global_transform.basis.x.normalized()

# DAMAGE SYSTEM
func take_damage(amount, source: String = "Unknown"):
	if is_dead:
		return
	# IGNORE DAMAGE DURING INVINCIBILITY WINDOW
	if invincible:
		return

	health -= amount
	invincible = true
	invincibility_timer = invincibility_duration
	hit_flash_timer = HIT_FLASH_DURATION

	# UPDATE HP DISPLAY
	if hp_display and hp_display.has_method("update_hp"):
		hp_display.update_hp(health, max_health)

	if health <= 0:
		# RECORD WHAT KILLED THE PLAYER
		GlobalSettings.death_cause = source
		die()

# PLAYER DEATH LOGIC
func die():
	if is_dead:
		return
	is_dead = true

	# RETRIEVE SURVIVAL TIME FROM TIMER
	var timer_panel = get_tree().get_first_node_in_group("survival_timer")
	var survival_time = 0.0
	if timer_panel and timer_panel.has_method("get_survival_time"):
		survival_time = timer_panel.get_survival_time()

	# DETERMINE LEADERBOARD TYPE BASED ON SPAWN MODE
	var spawn_manager = get_tree().get_first_node_in_group("spawn_manager")
	var wave_count = 0
	if spawn_manager and spawn_manager.current_spawn_mode == spawn_manager.SpawnMode.WAVE_BASED:
		if spawn_manager.has_method("get_current_wave"):
			wave_count = spawn_manager.get_current_wave()
		elif "current_wave" in spawn_manager:
			wave_count = spawn_manager.current_wave
		GlobalSettings.add_wave_leaderboard_entry(wave_count)
	else:
		GlobalSettings.add_time_leaderboard_entry(survival_time)

	# BEST TIME COMPARISON AND SAVE
	if GlobalSettings.best_time == 0.0 or survival_time > GlobalSettings.best_time:
		GlobalSettings.best_time = survival_time
	GlobalSettings.save_best_time()
	var best_time = GlobalSettings.best_time

	# DISPLAY END GAME SCREEN
	var end_screen_scene = preload("res://scenes/ui/endgamescreen.tscn")
	var end_screen_instance = end_screen_scene.instantiate()
	get_tree().root.add_child(end_screen_instance)
	if end_screen_instance.has_method("show_screen"):
		end_screen_instance.show_screen(survival_time, best_time, wave_count)

	# REMOVE UI ELEMENTS
	if speed_label and speed_label.is_inside_tree():
		speed_label.queue_free()
	if hp_display and hp_display.is_inside_tree():
		hp_display.queue_free()

	# DISABLE PLAYER CONTROL
	set_process_input(false)
	set_physics_process(false)

# TRANSITION BACK TO MAIN MENU
func transition_to_main_menu():
	var transition_scene = preload("res://scenes/ui/scene_transition.tscn")
	var transition = transition_scene.instantiate()
	get_tree().root.add_child(transition)
	await transition.fade_to_main_menu()
