extends CanvasLayer

@onready var survival_time_label = $ColorRect/SurvivalTime
@onready var best_time_label = $ColorRect/BestTime
@onready var wave_label = $ColorRect/WaveLabel
@onready var kills_label = $ColorRect/KillsLabel
@onready var shots_label = $ColorRect/ShotsLabel
@onready var accuracy_label = $ColorRect/AccuracyLabel
@onready var avg_kill_label = $ColorRect/AvgKillLabel
@onready var avg_speed_label = $ColorRect/AvgSpeedLabel
@onready var threat_density_label = $ColorRect/ThreatDensityLabel
@onready var death_cause_label = $ColorRect/DeathCauseLabel

var main_scene_path = "res://scenes/gameplay.tscn"

func _ready():
	hide()

func show_screen(survival_time: float, best_time: float, wave_count: int = 0):
	# TIME
	survival_time_label.text = "Survival Time: %s" % _format_time(survival_time)
	best_time_label.text = "Best Time: %s" % _format_time(best_time)

	# WAVE
	if wave_count > 0:
		wave_label.text = "Wave Reached: %d" % wave_count
		wave_label.show()
	else:
		wave_label.hide()

	# KILL + SHOOTING STATS
	kills_label.text = "Enemies Killed: %d" % GlobalSettings.enemies_killed
	shots_label.text = "Shots Fired: %d  |  Hits: %d" % [GlobalSettings.shots_fired, GlobalSettings.shots_hit]
	accuracy_label.text = "Accuracy: %.1f%%" % GlobalSettings.get_accuracy()

	# AVG KILL TIME
	var avg_kill = GlobalSettings.get_avg_kill_interval()
	if avg_kill > 0.0:
		avg_kill_label.text = "Avg. Kill Interval: %.2fs" % avg_kill
	else:
		avg_kill_label.text = "Avg. Kill Interval: N/A"

	# AVG SPEED
	avg_speed_label.text = "Avg. Speed: %.1f u/s" % GlobalSettings.get_avg_speed()
	
	# THREAT DENSITY
	var avg_density = GlobalSettings.get_avg_threat_density()
	threat_density_label.text = "Avg. Threat Density: %.1f enemies" % avg_density
	
	# DEATH CAUSE
	death_cause_label.text = "Killed by: %s" % GlobalSettings.death_cause

	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# STAT RESET 
	GlobalSettings.reset_stats()

func _format_time(t: float) -> String:
	var seconds = int(t)
	var msec = int(fmod(t, 1) * 100)
	return "%02d.%02d" % [seconds, msec]

func _input(event):
	if visible and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			restart_game()

func restart_game():
	hide()
	get_tree().change_scene_to_file(main_scene_path)
