extends Control

# NODE REFERENCES
@onready var entries_container = $VBoxContainer/ScrollContainer/Entries
@onready var back_button = $VBoxContainer/ButtonsContainer/Back
@onready var time_button = $VBoxContainer/ButtonsContainer/TimeButton
@onready var waves_button = $VBoxContainer/ButtonsContainer/WaveButton
@onready var scroll_container = $VBoxContainer/ScrollContainer

# DISPLAY MODE: "time" OR "waves"
var display_mode: String = "time"

func _ready():
	GlobalSettings.leaderboard_updated.connect(_on_leaderboard_updated)
	
	refresh_leaderboard()
	force_layout_update()
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func force_layout_update():
	# FORCE CONTAINER LAYOUT REFRESH
	await get_tree().process_frame
	entries_container.queue_redraw()
	scroll_container.queue_redraw()
	
	# SET MINIMUM SIZE FOR PROPER DISPLAY
	scroll_container.custom_minimum_size = Vector2(700, 400)

func _on_time_button_pressed() -> void:
	display_mode = "time"
	refresh_leaderboard()

func _on_wave_button_pressed() -> void:
	display_mode = "waves"
	refresh_leaderboard()

func refresh_leaderboard():
	# CLEAR EXISTING ENTRIES
	for child in entries_container.get_children():
		child.queue_free()
	
	var leaderboard = []
	if display_mode == "time":
		leaderboard = GlobalSettings.get_time_leaderboard()
	else:
		leaderboard = GlobalSettings.get_wave_leaderboard()
	
	# REBUILD UI ENTRIES
	for i in range(leaderboard.size()):
		var entry = leaderboard[i]
		if display_mode == "time":
			create_leaderboard_entry(i + 1, entry["name"], entry["time"], false)
		else:
			create_leaderboard_entry(i + 1, entry["name"], entry["waves"], true)

# CREATE SINGLE LEADERBOARD ENTRY ROW
func create_leaderboard_entry(rank: int, name: String, value, is_waves: bool = false):
	var entry_container = HBoxContainer.new()
	entry_container.custom_minimum_size = Vector2(0, 40)
	entry_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry_container.add_theme_constant_override("separation", 12)

	# RANK LABEL
	var rank_label = Label.new()
	rank_label.text = str(rank) + "."
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rank_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rank_label.custom_minimum_size = Vector2(56, 0)
	rank_label.add_theme_font_size_override("font_size", 20)
	rank_label.add_theme_color_override("font_color", get_rank_color(rank))
	entry_container.add_child(rank_label)

	# PLAYER NAME LABEL
	var name_label = Label.new()
	name_label.text = name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.custom_minimum_size = Vector2(200, 0)
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", get_rank_color(rank))
	entry_container.add_child(name_label)

	# VALUE LABEL (TIME OR WAVES)
	var value_label = Label.new()
	if is_waves:
		value_label.text = str(value) + " waves"
	else:
		value_label.text = format_time(value)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.custom_minimum_size = Vector2(140, 0)
	value_label.add_theme_font_size_override("font_size", 20)
	value_label.add_theme_color_override("font_color", get_rank_color(rank))
	entry_container.add_child(value_label)

	entries_container.add_child(entry_container)

# RETURN COLOR BASED ON RANK
func get_rank_color(rank: int) -> Color:
	match rank:
		1: return Color.GOLD
		2: return Color.SILVER
		3: return Color.ORANGE
		_: return Color.WHITE

# FORMAT FLOAT TIME TO MM:SS.MS
func format_time(time: float) -> String:
	var minutes = int(time) / 60
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]

# CLEAR BUTTON HANDLER
func _on_clear_button_pressed():
	GlobalSettings.clear_leaderboard()

# SIGNAL CALLBACK WHEN LEADERBOARD UPDATES
func _on_leaderboard_updated():
	refresh_leaderboard()

# RETURN TO MAIN MENU
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/mainmenu.tscn")
