extends Node

# SETTINGS VARIABLES
var spawn_mode: String = "time_based"
var mouse_sensitivity: float = 0.25
var best_time: float = 0.0
var leaderboard_time_entries: Array = []
var leaderboard_wave_entries: Array = []
var player_name: String = "Player"

# SETTINGS CHANGE SIGNALS
signal spawn_mode_changed(new_mode)
signal sensitivity_changed(new_sensitivity)
signal leaderboard_updated()
signal player_name_changed(new_name)

func _ready():
	load_player_name()

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

	# ENSURE REQUIRED KEYS AND REMOVE LEGACY DATE FIELD
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
	var new_entry = {
		"name": player_name,
		"time": time
	}
	get_time_leaderboard()
	leaderboard_time_entries.append(new_entry)
	leaderboard_time_entries.sort_custom(sort_by_time)
	if leaderboard_time_entries.size() > 10:
		leaderboard_time_entries.resize(10)
	save_time_leaderboard()
	leaderboard_updated.emit()

# WAVE LEADERBOARD
func get_wave_leaderboard() -> Array:
	if FileAccess.file_exists("user://leaderboard_waves.save"):
		var f = FileAccess.open("user://leaderboard_waves.save", FileAccess.READ)
		leaderboard_wave_entries = f.get_var()
		f.close()
	else:
		leaderboard_wave_entries = []

	# ENSURE REQUIRED KEYS AND REMOVE LEGACY DATE FIELD
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
	var new_entry = {
		"name": player_name,
		"waves": waves
	}
	get_wave_leaderboard()
	leaderboard_wave_entries.append(new_entry)
	leaderboard_wave_entries.sort_custom(sort_by_waves)
	if leaderboard_wave_entries.size() > 10:
		leaderboard_wave_entries.resize(10)
	save_wave_leaderboard()
	leaderboard_updated.emit()

# SORTING FUNCTIONS
func sort_by_time(a: Dictionary, b: Dictionary) -> bool:
	return a["time"] > b["time"]

func sort_by_waves(a: Dictionary, b: Dictionary) -> bool:
	return a["waves"] > b["waves"]

# CLEAR LEADERBOARD BY MODE
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
