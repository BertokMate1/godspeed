extends CharacterBody3D

# NODES
@onready var nav = $NavigationAgent3D

# BASE STATS
var health = 60
var gravity = 9.8
var damage = 1

# REFERENCES
var player_node
var timer_panel

# TELEPORT SETTINGS
var time_since_spawn := 0.0
const TELEPORT_DELAY := 10.0        # TIME BEFORE TELEPORT (SECONDS)
const TELEPORT_DISTANCE := 5.0      # DISTANCE IN FRONT OF PLAYER
const TELEPORT_COOLDOWN := 2.0      # MIN TIME AFTER TELEPORT BEFORE NEXT ELIGIBLE
const Y_OFFSET := 1.0               # UPWARD NUDGE TO AVOID GROUND EMBED
var teleport_cooldown_timer := 0.0

# RAYCAST SETTINGS (GROUND ALIGNMENT)
const RAYCAST_UP := 5.0
const RAYCAST_DOWN := 10.0

# PREDICTION WHEN PLAYER IS MOVING (SET TO 0 TO DISABLE)
const PREDICTION_FACTOR := 0.5

func _ready():
	# REGISTER AND CACHE PLAYER
	player_node = get_tree().get_first_node_in_group("player")
	add_to_group("enemy")

func _physics_process(delta):
	# UPDATE TIMERS
	time_since_spawn += delta
	if teleport_cooldown_timer > 0.0:
		teleport_cooldown_timer -= delta

	# TELEPORT WHEN IGNORED LONG ENOUGH AND COOLDOWN PASSED
	if player_node and time_since_spawn >= TELEPORT_DELAY and teleport_cooldown_timer <= 0.0:
		_teleport_in_front_of_player()
		teleport_cooldown_timer = TELEPORT_COOLDOWN
		time_since_spawn = 0.0

	# APPLY GRAVITY
	if not is_on_floor():
		velocity.y -= gravity * delta

	# COLLISION CHECKS (SAFE ITERATION)
	var slide_count = get_slide_collision_count()
	for i in range(slide_count):
		var collision = get_slide_collision(i)
		if not collision:
			continue
		var collider = collision.get_collider()
		if collider and collider.is_in_group("player"):
			if collider.has_method("take_damage"):
				collider.take_damage(damage, "Stander")

# TELEPORT IN FRONT OF PLAYER (PREDICTIVE + SAFE_ON_GROUND + FACE PLAYER)
func _teleport_in_front_of_player():
	if not player_node:
		return

	# PLAYER POSITION
	var player_pos: Vector3 = player_node.global_transform.origin

	# TRY TO PREDICT PLAYER MOVEMENT DIRECTION USING VELOCITY
	var forward: Vector3 = Vector3.ZERO
	var predicted_offset: Vector3 = Vector3.ZERO

	if player_node is CharacterBody3D:
		var pv: Vector3 = player_node.velocity
		if pv.length() > 0.5:
			predicted_offset = pv * PREDICTION_FACTOR
			forward = pv.normalized()

	# FALLBACK: USE PLAYER'S HEAD / GLOBAL FACING IF NO VELOCITY
	if forward == Vector3.ZERO:
		if player_node.has_node("head"):
			var head = player_node.get_node("head")
			forward = -head.global_transform.basis.z.normalized()
		else:
			forward = -player_node.global_transform.basis.z.normalized()

	# TARGET POSITION IN FRONT OF PLAYER, WITH PREDICTION
	var target_pos = player_pos + forward * TELEPORT_DISTANCE + predicted_offset

	# RAYCAST DOWN TO FIND GROUND HEIGHT (USE PhysicsRayQueryParameters3D)
	var space = get_world_3d().direct_space_state
	var from_point = target_pos + Vector3.UP * RAYCAST_UP
	var to_point = target_pos - Vector3.UP * RAYCAST_DOWN
	var exclude = [self, player_node]

	var ray_params = PhysicsRayQueryParameters3D.new()
	ray_params.from = from_point
	ray_params.to = to_point
	ray_params.exclude = exclude

	var result = space.intersect_ray(ray_params)

	if result and result.has("position"):
		target_pos.y = result["position"].y + Y_OFFSET
	else:
		# FALLBACK: ALIGN TO PLAYER Y PLUS OFFSET
		target_pos.y = player_pos.y + Y_OFFSET

	# APPLY TELEPORT (SET GLOBAL ORIGIN)
	global_transform.origin = target_pos

	# ROTATE TO FACE PLAYER (SO THE ENEMY BLOCKS MORE EFFECTIVELY)
	look_at(player_pos, Vector3.UP)

	# ZERO OUT VELOCITY TO AVOID RESIDUAL MOMENTUM
	velocity = Vector3.ZERO

func take_damage(amount):
	timer_panel = get_tree().get_first_node_in_group("survival_timer")
	health -= amount
	if health <= 0:
		if timer_panel and timer_panel.has_method("add_time"):
			timer_panel.add_time(3.0) # ADD 3 SECONDS ON KILL
		GlobalSettings.record_kill()
		queue_free()

func get_health():
	return health

func set_health(new_health):
	health = new_health

func scale_health(multiplier):
	health *= multiplier
