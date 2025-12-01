extends Control

#NODES
@onready var entries_container = $VBoxContainer/ScrollContainer/Entries
@onready var back_button = $VBoxContainer/ButtonsContainer/Back
@onready var scroll_container = $VBoxContainer/ScrollContainer

func _ready():
	#BUTTON SIGNALS
	back_button.pressed.connect(_on_back_button_pressed)
	
	#LEADERBOARD UPDATE SIGNAL
	GlobalSettings.leaderboard_updated.connect(_on_leaderboard_updated)
	
	#LOAD AND DISPLAY LEADERBOARD
	refresh_leaderboard()
	
	force_layout_update()
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
func force_layout_update():
	# FORCE CONTAINER TO UPDATE LAYOUT
	await get_tree().process_frame
	entries_container.queue_redraw()
	scroll_container.queue_redraw()
	
	# SIZE RECALCULATION
	entries_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	entries_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# PROPER SIZE
	scroll_container.custom_minimum_size = Vector2(700, 400)

#REFRESH LEADERBOARD DISPLAY
func refresh_leaderboard():
	#CLEAR EXISTING ENTRIES
	for child in entries_container.get_children():
		child.queue_free()
	
	#GET LEADERBOARD DATA
	var leaderboard = GlobalSettings.get_leaderboard()
	
	if leaderboard.is_empty():
		#SHOW "NO ENTRIES" MESSAGE
		var no_entries_label = Label.new()
		no_entries_label.text = "No leaderboard entries yet!\nPlay the game to get some times!"
		no_entries_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_entries_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		no_entries_label.add_theme_color_override("font_color", Color.WHITE)
		no_entries_label.add_theme_font_size_override("font_size", 24)
		entries_container.add_child(no_entries_label)
		return
	
	#CREATE ENTRIES FOR EACH LEADERBOARD ITEM
	for i in range(leaderboard.size()):
		var entry = leaderboard[i]
		create_leaderboard_entry(i + 1, entry["name"], entry["time"], entry["date"])

#CREATE SINGLE LEADERBOARD ENTRY
func create_leaderboard_entry(rank: int, name: String, time: float, date: String):
	#CREATE HBOXCONTAINER FOR THIS ENTRY
	var entry_container = HBoxContainer.new()
	entry_container.add_theme_constant_override("separation", 20)
	entry_container.custom_minimum_size = Vector2(0, 40)
	entry_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	#RANK LABEL
	var rank_label = Label.new()
	rank_label.text = str(rank) + "."
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rank_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rank_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rank_label.add_theme_font_size_override("font_size", 20)
	rank_label.add_theme_color_override("font_color", get_rank_color(rank))
	entry_container.add_child(rank_label)
	
	#NAME LABEL
	var name_label = Label.new()
	name_label.text = name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", get_rank_color(rank))
	entry_container.add_child(name_label)
	
	#TIME LABEL
	var time_label = Label.new()
	time_label.text = format_time(time)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_label.add_theme_font_size_override("font_size", 20)
	time_label.add_theme_color_override("font_color", get_rank_color(rank))
	entry_container.add_child(time_label)
	
	#DATE LABEL
	var date_label = Label.new()
	date_label.text = date
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	date_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	date_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	date_label.add_theme_font_size_override("font_size", 16)
	date_label.add_theme_color_override("font_color", get_rank_color(rank))
	entry_container.add_child(date_label)
	
	#ADD TO ENTRIES CONTAINER
	entries_container.add_child(entry_container)

#GET COLOR BASED ON RANK
func get_rank_color(rank: int) -> Color:
	match rank:
		1: return Color.GOLD
		2: return Color.SILVER
		3: return Color.ORANGE
		_: return Color.WHITE

#FORMAT TIME TO MM:SS.MS
func format_time(time: float) -> String:
	var minutes = int(time) / 60
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]

#BACK BUTTON PRESSED
func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/mainmenu.tscn")

#CLEAR BUTTON PRESSED
func _on_clear_button_pressed():
	GlobalSettings.clear_leaderboard()

#LEADERBOARD UPDATED SIGNAL
func _on_leaderboard_updated():
	refresh_leaderboard()
