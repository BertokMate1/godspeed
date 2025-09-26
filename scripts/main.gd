extends Node3D

@onready var target = $player
@onready var spawn_timer = $enemyspawntimer

var spawn_radius_min = 5.0
var spawn_radius_max = 15.0
var enemies_spawned = 0

# Increasing difficulty - spawn closer as more enemies appear
var current_radius = lerp(spawn_radius_max, spawn_radius_min, min(enemies_spawned / 20.0, 1.0))
var random_angle = randf() * 2 * PI
var random_offset = Vector3(
	cos(random_angle) * current_radius,
	0,
	sin(random_angle) * current_radius
)

#enemies
var enemy_scene = preload("res://scenes/charger.tscn")
var spectral_waver_scene = preload("res://scenes/spectral_waver.tscn")
var echo_wraith_scene = preload("res://scenes/echo_wraith.tscn")

func _ready() -> void:
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func _process(_delta: float) -> void:
	get_tree().call_group("enemy", "target_position", target.global_transform.origin)

func _on_spawn_timer_timeout():
	spawn_enemy()
	
func spawn_enemy():
	var enemy
	
	if randf() > 0.2:
		enemy = echo_wraith_scene.instantiate()
	elif randf() > 0.5:
		enemy = spectral_waver_scene.instantiate()
	else:
		enemy = enemy_scene.instantiate()
	
	add_child(enemy)
	
	enemy.call_deferred("set_global_position", target.global_position + random_offset)
	
	if enemy.has_method("is_real") && enemy.is_real:
		enemy.add_to_group("echo_wraith")
	enemy.add_to_group("enemy")
	
	
	enemies_spawned += 1
	
	#Increase spawn rate over time
	if enemies_spawned % 5 == 0:
		spawn_timer.wait_time = max(0.5, spawn_timer.wait_time * 0.9)  # Don't go below 0.5s
