extends Control

@onready var wave_based_checkbox = $WaveBased
@onready var time_based_checkbox = $TimeBased
@onready var sensitivity_slider = $HSlider
@onready var sensitivity_label = $SensitivityLabel
@onready var mainbutton = $mainmenu

func _ready():
	#UI SIGNALS
	wave_based_checkbox.toggled.connect(_on_wave_based_toggled)
	time_based_checkbox.toggled.connect(_on_time_based_toggled)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	
	#SENS SLIDER
	sensitivity_slider.min_value = 0.1
	sensitivity_slider.max_value = 1.0
	sensitivity_slider.step = 0.05
	
	#CURRENT SETTINGS FROM GLOBALSETTINGS
	time_based_checkbox.set_pressed(GlobalSettings.spawn_mode == "time_based")
	wave_based_checkbox.set_pressed(GlobalSettings.spawn_mode == "wave_based")
	sensitivity_slider.value = GlobalSettings.mouse_sensitivity
	
	_update_sensitivity_label()

func _on_wave_based_toggled(button_pressed):
	if button_pressed:
		time_based_checkbox.set_pressed(false)
		#UPDATE THE GLOBALSETTING
		GlobalSettings.set_spawn_mode("wave_based")
	elif not time_based_checkbox.is_pressed():
		time_based_checkbox.set_pressed(true)

func _on_time_based_toggled(button_pressed):
	if button_pressed:
		wave_based_checkbox.set_pressed(false)
		#UPDATE THE GLOBALSETTING
		GlobalSettings.set_spawn_mode("time_based")
	elif not wave_based_checkbox.is_pressed():
		wave_based_checkbox.set_pressed(true)

func _on_sensitivity_changed(value: float):
	_update_sensitivity_label()
	#UPDATE THE GLOBALSETTING
	GlobalSettings.set_mouse_sensitivity(value)

func _update_sensitivity_label():
	if sensitivity_label:
		sensitivity_label.text = "Mouse Sensitivity: %.2f" % sensitivity_slider.value

func _on_mainmenu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
