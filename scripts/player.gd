extends CharacterBody3D

# NODE VARIABLES
@onready var head: Node3D = $head
@onready var standing_collision_shape: CollisionShape3D = $standing_collision_shape
@onready var crouching_collision_shape: CollisionShape3D = $crouching_collision_shape
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var pos = $head/Camera3D/gun/position

# EXPORTED VARIABLES
@export var mouse_sens = 0.25

# SPEED VARIABLES
var current_speed = 5.0
const walking_speed = 5.0
const sprinting_speed = 8.0
const crouching_speed = 3.0

# STATES
var walking = false
var sprinting = false
var crouching = false
var sliding = false
var is_dead = false

# SLIDE VARIABLES
var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_direction = Vector2.ZERO
var slide_speed = 20

# MOCSKOS LERP
var lerp_speed = 10

# JUMP VARIABLE(S)
const JUMP_VELOCITY = 4.5

# CROUCH VARIABLE(S)
var crouching_depth = -0.5

# !!DIRECTION
var direction = Vector3.ZERO

# BULLET
var bullet = load("res://scenes/bullet.tscn")

# MOUSE CAPTURING FOR CAMERA
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	$hitbox.body_entered.connect(_on_hitbox_body_entered)
	
func _on_hitbox_body_entered(body):
	if body.is_in_group("enemy"):
		is_dead = true
		print("dead")
		get_tree().quit()
		
# MOUSE MOVEMENT FOR CAMERA AND +-89 DEGREE SO IT CANT ROTATE FULLY AROUND
func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_z(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.z = clamp(head.rotation.z, deg_to_rad(-89), deg_to_rad(89))
			
# THE MOVEMENTS START HERE
func _physics_process(delta: float) -> void:
	# Check if player is still in the scene tree
	if not is_inside_tree():
		return
	
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
	
	# Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		sliding = false
		
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
