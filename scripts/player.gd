extends CharacterBody3D

# NODE VARIABLES
@onready var head: Node3D = $head
@onready var standing_collision_shape: CollisionShape3D = $standing_collision_shape
@onready var crouching_collision_shape: CollisionShape3D = $crouching_collision_shape
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var pos = $head/Camera3D/gun/position

# SPEED COUNTER VARIABLES - ADDED THIS SECTION
var speed_counter = 0.0
var max_speed = 0.0
@onready var speed_label = $SpeedLabel

# EXPORTED VARIABLES
@export var mouse_sens = 0.25

# SPEED VARIABLES
var current_speed = 7.0

var walking_speed = 7.0
var sprinting_speed = 8.5
var ground_accel = 20
var ground_decel = 10
var ground_friction = 6

var crouching_speed = 3.0

#AIR MOVEMENT
var air_cap = 0.85
var air_accel = 1200.0
var air_move_speed = 600.0

# STATES
var walking = false
var sprinting = false
var crouching = false
var sliding = false
var is_dead = false
var auto_bhop = true

# SLIDE VARIABLES
var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_direction = Vector2.ZERO
var slide_speed = 20

# MOCSKOS LERP
var lerp_speed = 10

# JUMP VARIABLE(S)
const JUMP_VELOCITY = 5.0

# CROUCH VARIABLE(S)
var crouching_depth = -0.5

# !!DIRECTION
var direction = Vector3.ZERO

# BULLET
var bullet = load("res://scenes/bullet.tscn")

# HEALTH
var health = 100

# MOUSE CAPTURING FOR CAMERA
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Connect hitbox signals
	$hitbox.body_entered.connect(_on_hitbox_body_entered)
	
	# Add to player group for enemy targeting
	add_to_group("player")
	
	# Create speed label if it doesn't exist - ADDED THIS
	if not has_node("SpeedLabel"):
		var label = Label.new()
		label.name = "SpeedLabel"
		label.text = "Speed: 0.0"
		
		# Center the label in the middle of screen, slightly below center
		var viewport_size = get_viewport().get_visible_rect().size
		label.position = Vector2(viewport_size.x/2 - 50, viewport_size.y/2 + 200)
		
		label.add_theme_color_override("font_color", Color(1, 1, 1))
		label.add_theme_font_size_override("font_size", 14)  # Make it a bit larger
		
		get_tree().root.add_child(label)
		speed_label = label
	
	# Connect to viewport resize signal to keep label centered
	get_viewport().connect("size_changed", Callable(self, "_on_viewport_resize"))
	
func _on_viewport_resize():
	# Recenter the label when viewport size changes
	if speed_label:
		var viewport_size = get_viewport().get_visible_rect().size
		speed_label.position = Vector2(viewport_size.x/2 - 100, viewport_size.y/2 + 50)
	
func _on_hitbox_body_entered(body):
	if body.is_in_group("enemy"):
		take_damage(100)  # Instant death from enemy contact

# MOUSE MOVEMENT FOR CAMERA AND +-89 DEGREE SO IT CANT ROTATE FULLY AROUND
func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_z(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.z = clamp(head.rotation.z, deg_to_rad(-89), deg_to_rad(89))
			
			
func _handle_ground_physics(delta) -> void:
	#basically the air physics but on ground
	var cur_ground_speed_in_direction = self.velocity.dot(direction)
	var add_speed_till_cap = current_speed - cur_ground_speed_in_direction
	if add_speed_till_cap > 0:
		var accel_speed = ground_accel * delta * current_speed
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * direction
		
	#apply friction
	var control = max(self.velocity.length(), ground_decel)
	var drop = control * ground_friction * delta
	var new_speed = max(self.velocity.length() - drop, 0.0)
	if self.velocity.length() > 0:
		new_speed /= self.velocity.length()
	self.velocity *= new_speed
	
	#also gravity duh
func _handle_air_physics(delta) -> void:
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	
	var cur_air_speed_in_direction = self.velocity.dot(direction)
	#WISH SPEED ( IF DIRECTION> 0 LENGTH) CAPPED TO AIR_CAP
	var capped_speed = min((air_move_speed * direction).length(), air_cap)
	#HOW MUCH TO GET TO THE SPEED OF THE PLAYER WISHES
	var add_speed_till_cap = capped_speed - cur_air_speed_in_direction
	if add_speed_till_cap > 0:
		var accel_speed = air_accel * air_move_speed * delta
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * direction
	
# THE MOVEMENTS START HERE
func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	# Check if player is still in the scene tree
	if not is_inside_tree():
		return
	
	# CALCULATE SPEED - ADDED THIS SECTION
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	speed_counter = horizontal_velocity.length()
	
	# Update max speed
	if speed_counter > max_speed:
		max_speed = speed_counter
	
	# Update speed display
	if speed_label:
		speed_label.text = "Speed: " + str(snapped(speed_counter, 0.1)) + " u/s\nMax: " + str(snapped(max_speed, 0.1)) + " u/s"
	
	# GETTING MOVEMENT INPUT FIRST THING IN THE MORNIN' (SO IT CAN BE USED LATER)
	var input_dir := Input.get_vector("backward", "forward", "left", "right")
	
	if Input.is_action_pressed("crouch") || sliding :
		current_speed = crouching_speed
		
		head.position.y = lerp(head.position.y, 1.0 + crouching_depth, delta * lerp_speed)
		
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		
		#Slide begin logic
		
		if sprinting && input_dir != Vector2.ZERO:
			sliding =true
			slide_timer = slide_timer_max
			slide_direction = input_dir
		
		walking = false
		sprinting = false
		crouching = true
		
	elif !ray_cast_3d.is_colliding():
		
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
		
		head.position.y = lerp(head.position.y, 1.0, delta * lerp_speed)
		
		if Input.is_action_pressed("sprint"):
			
			current_speed = sprinting_speed
			sprinting = true
			
		else:
			current_speed = walking_speed
			walking = true
			
	
	#HANDLE SLIDE
	
	if sliding:
		slide_timer -= delta
		if 0 >= slide_timer:
			sliding = false
	
	# Handle jump
	if is_on_floor():
		if Input.is_action_just_pressed("jump") or (auto_bhop and Input.is_action_pressed("jump")):
			self.velocity.y = JUMP_VELOCITY
			sliding = false
		_handle_ground_physics(delta)
	else:
		_handle_air_physics(delta)
			
	move_and_slide()
		
	# Bullet shooting
	if Input.is_action_just_pressed("click"):
	# Check if the pos node is valid and in the tree
		if pos and pos.is_inside_tree():
			var instance = bullet.instantiate()
		
		# Add to scene tree first
			get_parent().add_child(instance)
		
		# Set position and rotation after adding to scene
			instance.global_position = pos.global_position
			instance.global_rotation = pos.global_rotation
		
		# Set direction based on the bullet's forward vector
			instance.direction = instance.global_transform.basis.x.normalized()


	#MOVEMENT LERP SO ITS NOT SUPER RESPONSIVE (FEELS BETTER IG?)
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta * lerp_speed)
	
	if sliding:
		direction = (transform.basis * Vector3(slide_direction.x,0,slide_direction.y)).normalized()
	
	#THE CORE MOVEMENT (UNLESS WE ARE SLIDING)
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		if sliding:
			velocity.x = direction.x * (slide_timer + 0.1) * slide_speed
			velocity.z = direction.z * (slide_timer + 0.1) * slide_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

# Damage system
func take_damage(amount):
	if is_dead:
		return
		
	health -= amount
	
	if health <= 0:
		die()

func die():
	is_dead = true
	# Remove speed label when player dies
	if speed_label and speed_label.is_inside_tree():
		speed_label.queue_free()
	get_tree().quit()
