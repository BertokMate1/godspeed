extends Node

#SETTINGS VARIABLES
var spawn_mode: String = "time_based"
var mouse_sensitivity: float = 0.25
var best_time: float = 0.0
var leaderboard_entries: Array = []
var player_name: String = "Player"

#SETTINGS CHANGE SIGNALS
signal spawn_mode_changed(new_mode)
signal sensitivity_changed(new_sensitivity)
signal leaderboard_updated()
signal player_name_changed(new_name)

func _ready():
	load_player_name()

#UPDATE SPAWN MODE
func set_spawn_mode(new_mode: String):
	if spawn_mode != new_mode:
		spawn_mode = new_mode
		spawn_mode_changed.emit(spawn_mode)

#UPDATE MOUSE SENS
func set_mouse_sensitivity(new_sensitivity: float):
	if mouse_sensitivity != new_sensitivity:
		mouse_sensitivity = new_sensitivity
		sensitivity_changed.emit(mouse_sensitivity)

#PLAYER NAME FUNCTIONS
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

#LEADERBOARD FUNCTIONS
func get_leaderboard() -> Array:
	if FileAccess.file_exists("user://leaderboard.save"):
		var file = FileAccess.open("user://leaderboard.save", FileAccess.READ)
		leaderboard_entries = file.get_var()
		file.close()
	else:
		leaderboard_entries = []
	
	#ENSURE ALL ENTRIES HAVE NAME FIELD
	for entry in leaderboard_entries:
		if not entry.has("name"):
			entry["name"] = "Player"
	
	return leaderboard_entries

#ADD NEW TIME TO LEADERBOARD
func add_leaderboard_entry(time: float, date: String = "") -> void:
	if date == "":
		date = get_current_date_time()
	
	var new_entry = {
		"time": time,
		"date": date,
		"name": player_name
	}
	
	get_leaderboard()
	
	#ADD NEW ENTRY
	leaderboard_entries.append(new_entry)
	
	#SORT BY TIME (DESCENDING)
	leaderboard_entries.sort_custom(sort_by_time)
	
	#KEEP ONLY TOP 10 ENTRIES
	if leaderboard_entries.size() > 10:
		leaderboard_entries.resize(10)
	
	save_leaderboard()
	
	#UPDATE BEST TIME
	if leaderboard_entries.size() > 0:
		set_best_time(leaderboard_entries[0]["time"])
	
	leaderboard_updated.emit()

#SAVE LEADERBOARD TO FILE
func save_leaderboard():
	var file = FileAccess.open("user://leaderboard.save", FileAccess.WRITE)
	file.store_var(leaderboard_entries)
	file.close()

#SORT FUNCTION FOR LEADERBOARD ENTRIES
func sort_by_time(a: Dictionary, b: Dictionary) -> bool:
	return a["time"] > b["time"]

#GET CURRENT DATE AND TIME AS STRING
func get_current_date_time() -> String:
	var datetime = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d" % [
		datetime["year"], datetime["month"], datetime["day"],
		datetime["hour"], datetime["minute"]
	]

#CLEAR LEADERBOARD
func clear_leaderboard() -> void:
	leaderboard_entries = []
	save_leaderboard()
	leaderboard_updated.emit()

#BEST TIME GET (BACKWARD COMPATIBILITY)
func get_best_time() -> float:
	if FileAccess.file_exists("user://best_time.save"):
		var file = FileAccess.open("user://best_time.save", FileAccess.READ)
		best_time = file.get_var()
		file.close()
	return best_time

#BEST TIME WRITE (BACKWARD COMPATIBILITY)
func set_best_time(time: float):
	best_time = time
	var file = FileAccess.open("user://best_time.save", FileAccess.WRITE)
	file.store_var(best_time)
	file.close()
