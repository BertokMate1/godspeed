extends Control

@onready var entries_container = $VBoxContainer/ScrollContainer/Entries
@onready var back_button = $VBoxContainer/ButtonsContainer/Back

func _ready():
	# Connect buttons
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	else:
		print("ERROR: Back button not found!")
	
	# Set up scroll container
	var scroll_container = $VBoxContainer/ScrollContainer
	scroll_container.custom_minimum_size = Vector2(700, 400)
	
	# Connect to leaderboard updates
	if GlobalSettings.has_signal("leaderboard_updated"):
		GlobalSettings.leaderboard_updated.connect(_on_leaderboard_updated)
	else:
		print("ERROR: leaderboard_updated signal not found in GlobalSettings!")
	
	# Load and display leaderboard
	refresh_leaderboard()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func refresh_leaderboard():
	
	# Clear existing entries
	for child in entries_container.get_children():
		child.queue_free()
	
	# Get leaderboard data
	var leaderboard = []
	if GlobalSettings.has_method("get_leaderboard"):
		leaderboard = GlobalSettings.get_leaderboard()
	else:
		print("ERROR: get_leaderboard method not found in GlobalSettings!")
		return
	
	if leaderboard.is_empty():
		# Show "no entries" message
		var no_entries_label = Label.new()
		no_entries_label.text = "No leaderboard entries yet!\nPlay the game to get some times!"
		no_entries_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_entries_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		no_entries_label.add_theme_color_override("font_color", Color.WHITE)
		no_entries_label.add_theme_font_size_override("font_size", 24)
		entries_container.add_child(no_entries_label)
		return
	
	# Create entries for each leaderboard item
	for i in range(leaderboard.size()):
		var entry = leaderboard[i]
		create_leaderboard_entry(i + 1, entry["time"], entry["date"])

func create_leaderboard_entry(rank: int, time: float, date: String):
	# Create HBoxContainer for this entry
	var entry_container = HBoxContainer.new()
	entry_container.add_theme_constant_override("separation", 20)
	entry_container.custom_minimum_size = Vector2(0, 40)  # Ensure minimum height
	
	# Rank label
	var rank_label = Label.new()
	rank_label.text = str(rank) + "."
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rank_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rank_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rank_label.add_theme_font_size_override("font_size", 20)
	
	# Time label
	var time_label = Label.new()
	time_label.text = format_time(time)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_label.add_theme_font_size_override("font_size", 20)
	
	# Date label
	var date_label = Label.new()
	date_label.text = date
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	date_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	date_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	date_label.add_theme_font_size_override("font_size", 16)
	
	# Set colors based on rank
	var color = get_rank_color(rank)
	rank_label.add_theme_color_override("font_color", color)
	time_label.add_theme_color_override("font_color", color)
	date_label.add_theme_color_override("font_color", color)
	
	# Add labels to container
	entry_container.add_child(rank_label)
	entry_container.add_child(time_label)
	entry_container.add_child(date_label)
	
	# Add to entries container
	entries_container.add_child(entry_container)
	
	# Force update
	entry_container.set_size(entry_container.get_minimum_size())

func get_rank_color(rank: int) -> Color:
	match rank:
		1: return Color.GOLD
		2: return Color.SILVER
		3: return Color.ORANGE
		_: return Color.WHITE

func format_time(time: float) -> String:
	var minutes = int(time) / 60
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/mainmenu.tscn")

func _on_leaderboard_updated():
	refresh_leaderboard()
