extends CenterContainer

@export var DOT_RADIUS : float = 2.0
@export var DOT_COLOR : Color = Color.CADET_BLUE

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2(0,0), DOT_RADIUS, DOT_COLOR)
