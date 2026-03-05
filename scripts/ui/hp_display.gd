extends CanvasLayer

var heart_labels: Array = []
const HEART_FULL = "♥"
const HEART_EMPTY = "♡"

func _ready():
	# HBOX FOR HEART LABELS
	var container = HBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	container.position = Vector2(20, 20)
	add_child(container)
	
	# 3 HEART LABELS
	for i in range(3):
		var label = Label.new()
		label.text = HEART_FULL
		label.add_theme_font_size_override("font_size", 40)
		label.add_theme_color_override("font_color", Color.RED)
		container.add_child(label)
		heart_labels.append(label)

func update_hp(current_hp: int, _max_hp: int):
	for i in range(heart_labels.size()):
		if i < current_hp:
			heart_labels[i].text = HEART_FULL
			heart_labels[i].add_theme_color_override("font_color", Color.RED)
		else:
			heart_labels[i].text = HEART_EMPTY
			heart_labels[i].add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
