extends CharacterBody3D

# Enemy properties
var health = 60
var speed = 4.0
var clone_count = 2
var clones = []
var swap_cooldown = 5.0
var can_swap = true

# Simple color differentiation
var real_color = Color(1.0, 0.2, 0.2)  # Red for real one
var clone_color = Color(0.2, 0.2, 1.0)  # Blue for clones

# References
var player = null
@onready var nav_agent = $NavigationAgent
@onready var swap_timer = $SwapTimer
@onready var body_mesh = $BodyMesh

func _ready():
	# Find player
	player = get_tree().get_first_node_in_group("player")
	
	# Add to appropriate groups
	add_to_group("enemy")
	
	# Check if this is the original (real) wraith
	if not is_in_group("echo_wraith_clone"):
		# This is the real one - add it to the real wraith group
		add_to_group("echo_wraith_real")
		add_to_group("echo_wraith")  # General group for all wraiths
		
		# Spawn clones
		spawn_clones()
	
	# Connect timer signal
	swap_timer.wait_time = swap_cooldown
	swap_timer.timeout.connect(_on_swap_timer_timeout)
	
	# Set appropriate color
	update_color()

func _physics_process(delta):
	if not is_inside_tree() or player == null:
		return
		
	# Movement logic for real wraith only
	if is_in_group("echo_wraith_real"):
		# Move toward player using navigation
		nav_agent.target_position = player.global_position
		var next_pos = nav_agent.get_next_path_position()
		var dir = (next_pos - global_position).normalized()
		velocity = dir * speed
		move_and_slide()
		
		# Sync clone positions
		sync_clones()
		
		# Attempt swap periodically
		if can_swap:
			attempt_swap()

func spawn_clones():
	for i in range(clone_count):
		# Load the scene (this same scene)
		var clone_scene = load("res://scenes/echo_wraith.tscn")
		var clone = clone_scene.instantiate()
		
		# Add clone to appropriate groups
		clone.add_to_group("enemy")
		clone.add_to_group("echo_wraith")
		clone.add_to_group("echo_wraith_clone")  # Mark as clone
		
		get_parent().add_child(clone)
		clone.global_position = calculate_clone_position(i)
		clone.update_color()
		
		clones.append(clone)

func calculate_clone_position(index):
	# Position clones in a circle around the real wraith
	var angle = (2 * PI / clone_count) * index
	var radius = 2.0
	var offset = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
	return global_position + offset

func sync_clones():
	# Only real wraith should sync clones
	if not is_in_group("echo_wraith_real"):
		return
		
	for i in range(clones.size()):
		if is_instance_valid(clones[i]):
			var clone_offset = calculate_clone_position(i) - global_position
			clones[i].global_position = global_position + clone_offset

func attempt_swap():
	if clones.size() == 0:
		return
		
	can_swap = false
	swap_timer.start()
	
	# Choose a random clone to swap with
	var valid_clones = []
	for clone in clones:
		if is_instance_valid(clone):
			valid_clones.append(clone)
	
	if valid_clones.size() > 0:
		var target_clone = valid_clones[randi() % valid_clones.size()]
		
		# Swap positions
		var real_position = global_position
		global_position = target_clone.global_position
		target_clone.global_position = real_position
		
		# Swap groups to change identity
		remove_from_group("echo_wraith_real")
		add_to_group("echo_wraith_clone")
		
		target_clone.remove_from_group("echo_wraith_clone")
		target_clone.add_to_group("echo_wraith_real")
		
		# Update colors
		update_color()
		target_clone.update_color()

func update_color():
	# Create a simple material with the appropriate color
	var material = StandardMaterial3D.new()
	
	if is_in_group("echo_wraith_real"):
		material.albedo_color = real_color
		# Make real one slightly larger
		body_mesh.scale = Vector3(1.1, 1.1, 1.1)
	else:
		material.albedo_color = clone_color
		# Make clones slightly smaller
		body_mesh.scale = Vector3(0.9, 0.9, 0.9)
	
	body_mesh.material_override = material

func take_damage(amount):
	if is_in_group("echo_wraith_clone"):
		# Clones die in one hit
		print("Clone destroyed!")
		queue_free()
		return
		
	# Real wraith takes damage
	health -= amount
	print("Real wraith took damage. Health: ", health)
	
	if health <= 0:
		die()

func die():
	print("Real wraith died!")
	# Destroy all clones
	for clone in clones:
		if is_instance_valid(clone):
			clone.queue_free()
	queue_free()

func _on_swap_timer_timeout():
	can_swap = true
