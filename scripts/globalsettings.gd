extends Node

# SETTINGS VARIABLES
var spawn_mode: String = "time_based"
var mouse_sensitivity: float = 0.25
var best_time: float = 0.0
var leaderboard_time_entries: Array = []
var leaderboard_wave_entries: Array = []
var player_name: String = "Player"

# STATISTICS
var shots_fired: int = 0
var shots_hit: int = 0
var enemies_killed: int = 0
var kill_timestamps: Array = []
var speed_samples: Array = []
var threat_density_samples: Array = []
var death_cause: String = "Unknown"

# SETTINGS CHANGE SIGNALS
signal spawn_mode_changed(new_mode)
signal sensitivity_changed(new_sensitivity)
signal leaderboard_updated()
signal player_name_changed(new_name)

func _ready():
	load_player_name()
	load_best_time()

# UPDATE SPAWN MODE
func set_spawn_mode(new_mode: String):
	if spawn_mode != new_mode:
		spawn_mode = new_mode
		spawn_mode_changed.emit(spawn_mode)

# UPDATE MOUSE SENSITIVITY
func set_mouse_sensitivity(new_sensitivity: float):
	if mouse_sensitivity != new_sensitivity:
		mouse_sensitivity = new_sensitivity
		sensitivity_changed.emit(mouse_sensitivity)

# PLAYER NAME MANAGEMENT
func set_player_name(new_name: String):
	if new_name.strip_edges().is_empty():
		new_name = "Player"
	player_name = new_name.strip_edges()
	var file = FileAccess.open("user://player_name.save", FileAccess.WRITE)
	file.store_string(player_name)
	file.close()
	player_name_changed.emit(player_name)

func get_player_name() -> String:
	return player_name

func load_player_name():
	if FileAccess.file_exists("user://player_name.save"):
		var file = FileAccess.open("user://player_name.save", FileAccess.READ)
		player_name = file.get_as_text()
		file.close()
	else:
		player_name = "Player"

# STATISTICS
func reset_stats():
	shots_fired = 0
	shots_hit = 0
	enemies_killed = 0
	kill_timestamps.clear()
	speed_samples.clear()
	threat_density_samples.clear()
	death_cause = "Unknown"

func record_shot_fired():
	shots_fired += 1

func record_shot_hit():
	shots_hit += 1

func record_kill():
	enemies_killed += 1
	kill_timestamps.append(Time.get_ticks_msec() / 1000.0)

func record_speed_sample(speed: float):
	speed_samples.append(speed)

func get_accuracy() -> float:
	if shots_fired == 0:
		return 0.0
	return (float(shots_hit) / float(shots_fired)) * 100.0

func get_avg_kill_interval() -> float:
	if kill_timestamps.size() < 2:
		return 0.0
	var total_interval = 0.0
	for i in range(1, kill_timestamps.size()):
		total_interval += kill_timestamps[i] - kill_timestamps[i - 1]
	return total_interval / (kill_timestamps.size() - 1)

func get_avg_speed() -> float:
	if speed_samples.is_empty():
		return 0.0
	var total = 0.0
	for s in speed_samples:
		total += s
	return total / speed_samples.size()

func record_threat_density(enemy_count: int):
	threat_density_samples.append(enemy_count)
	
func record_death_cause(cause: String):
	death_cause = cause

func get_avg_threat_density() -> float:
	if threat_density_samples.is_empty():
		return 0.0
	var total = 0.0
	for s in threat_density_samples:
		total += s
	return total / threat_density_samples.size()

# LEADERBOARD SYSTEM

# TIME LEADERBOARD
func get_time_leaderboard() -> Array:
	if FileAccess.file_exists("user://leaderboard_time.save"):
		var f = FileAccess.open("user://leaderboard_time.save", FileAccess.READ)
		leaderboard_time_entries = f.get_var()
		f.close()
	elif FileAccess.file_exists("user://leaderboard.save"):
		var f2 = FileAccess.open("user://leaderboard.save", FileAccess.READ)
		leaderboard_time_entries = f2.get_var()
		f2.close()
	else:
		leaderboard_time_entries = []

	for entry in leaderboard_time_entries:
		if not entry.has("name"):
			entry["name"] = "Player"
		if entry.has("date"):
			entry.erase("date")
		if not entry.has("time"):
			entry["time"] = 0.0
	return leaderboard_time_entries

func save_time_leaderboard() -> void:
	var f = FileAccess.open("user://leaderboard_time.save", FileAccess.WRITE)
	f.store_var(leaderboard_time_entries)
	f.close()

func add_time_leaderboard_entry(time: float) -> void:
	var new_entry = {"name": player_name, "time": time}
	get_time_leaderboard()
	leaderboard_time_entries.append(new_entry)
	leaderboard_time_entries.sort_custom(sort_by_time)
	if leaderboard_time_entries.size() > 10:
		leaderboard_time_entries.resize(10)
	save_time_leaderboard()
	leaderboard_updated.emit()
	
func save_best_time() -> void:
	var f = FileAccess.open("user://best_time.save", FileAccess.WRITE)
	f.store_float(best_time)
	f.close()

func load_best_time() -> void:
	if FileAccess.file_exists("user://best_time.save"):
		var f = FileAccess.open("user://best_time.save", FileAccess.READ)
		best_time = f.get_float()
		f.close()

# WAVE LEADERBOARD
func get_wave_leaderboard() -> Array:
	if FileAccess.file_exists("user://leaderboard_waves.save"):
		var f = FileAccess.open("user://leaderboard_waves.save", FileAccess.READ)
		leaderboard_wave_entries = f.get_var()
		f.close()
	else:
		leaderboard_wave_entries = []

	for entry in leaderboard_wave_entries:
		if not entry.has("name"):
			entry["name"] = "Player"
		if entry.has("date"):
			entry.erase("date")
		if not entry.has("waves"):
			entry["waves"] = 0
	return leaderboard_wave_entries

func save_wave_leaderboard() -> void:
	var f = FileAccess.open("user://leaderboard_waves.save", FileAccess.WRITE)
	f.store_var(leaderboard_wave_entries)
	f.close()

func add_wave_leaderboard_entry(waves: int) -> void:
	var new_entry = {"name": player_name, "waves": waves}
	get_wave_leaderboard()
	leaderboard_wave_entries.append(new_entry)
	leaderboard_wave_entries.sort_custom(sort_by_waves)
	if leaderboard_wave_entries.size() > 10:
		leaderboard_wave_entries.resize(10)
	save_wave_leaderboard()
	leaderboard_updated.emit()

# SORTING
func sort_by_time(a: Dictionary, b: Dictionary) -> bool:
	return a["time"] > b["time"]

func sort_by_waves(a: Dictionary, b: Dictionary) -> bool:
	return a["waves"] > b["waves"]

# CLEAR
func clear_leaderboard(mode: String = "time") -> void:
	if mode == "time":
		leaderboard_time_entries = []
		var f = FileAccess.open("user://leaderboard_time.save", FileAccess.WRITE)
		f.store_var(leaderboard_time_entries)
		f.close()
	else:
		leaderboard_wave_entries = []
		var f = FileAccess.open("user://leaderboard_waves.save", FileAccess.WRITE)
		f.store_var(leaderboard_wave_entries)
		f.close()
	leaderboard_updated.emit()
