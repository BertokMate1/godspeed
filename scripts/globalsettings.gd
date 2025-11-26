extends Node

var spawn_mode: String = "time_based"
var mouse_sensitivity: float = 0.25
var best_time: float = 0.0
var leaderboard_entries: Array = []

# SIGNALS TO NOTIFY ABOUT SETTINGS CHANGE
signal spawn_mode_changed(new_mode)
signal sensitivity_changed(new_sensitivity)
signal leaderboard_updated()

# UPDATE SPAWN MODE
func set_spawn_mode(new_mode: String):
	if spawn_mode != new_mode:
		spawn_mode = new_mode
		spawn_mode_changed.emit(spawn_mode)

# UPDATE MOUSE SENS
func set_mouse_sensitivity(new_sensitivity: float):
	if mouse_sensitivity != new_sensitivity:
		mouse_sensitivity = new_sensitivity
		sensitivity_changed.emit(mouse_sensitivity)
		
# BEST TIME GET
func get_best_time() -> float:
	if FileAccess.file_exists("user://best_time.save"):
		var file = FileAccess.open("user://best_time.save", FileAccess.READ)
		best_time = file.get_var()
		file.close()
	return best_time

# BEST TIME WRITE
func set_best_time(time: float):
	best_time = time
	var file = FileAccess.open("user://best_time.save", FileAccess.WRITE)
	file.store_var(best_time)
	file.close()

# LEADERBOARD FUNCTIONS

# LEADERBOARD ENTRIES
func get_leaderboard() -> Array:
	if FileAccess.file_exists("user://leaderboard.save"):
		var file = FileAccess.open("user://leaderboard.save", FileAccess.READ)
		leaderboard_entries = file.get_var()
		file.close()
	else:
		leaderboard_entries = []
	return leaderboard_entries

# NEW TIME TO LEADERBOARD
func add_leaderboard_entry(time: float, date: String = "") -> void:
	if date == "":
		date = get_current_date_time()
	
	var new_entry = {
		"time": time,
		"date": date
	}
	
	get_leaderboard()
	
	# ADD ENTRY
	leaderboard_entries.append(new_entry)
	
	# SORT BY TIME
	leaderboard_entries.sort_custom(sort_by_time)
	
	# ONLY KEEP TOP 10
	if leaderboard_entries.size() > 10:
		leaderboard_entries.resize(10)
	
	# Save leaderboard
	var file = FileAccess.open("user://leaderboard.save", FileAccess.WRITE)
	file.store_var(leaderboard_entries)
	file.close()
	
	# UPDATE BEST TIME
	if leaderboard_entries.size() > 0:
		set_best_time(leaderboard_entries[0]["time"])
	
	# EMIT SIGNAL
	leaderboard_updated.emit()

# SORT FOR LEADERBOARD ENTRIES
func sort_by_time(a: Dictionary, b: Dictionary) -> bool:
	return a["time"] > b["time"]

# GET CURRENT DATE AND TIME AS STRING
func get_current_date_time() -> String:
	var datetime = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d" % [
		datetime["year"], datetime["month"], datetime["day"],
		datetime["hour"], datetime["minute"]
	]

# CLEAR LEADERBOARD
func clear_leaderboard() -> void:
	leaderboard_entries = []
	var file = FileAccess.open("user://leaderboard.save", FileAccess.WRITE)
	file.store_var(leaderboard_entries)
	file.close()
	leaderboard_updated.emit()
