extends Panel

var time: float = 0.0
var seconds: int = 0
var msec: int = 0
var is_stopped: bool = false

func _ready():
	show()
	add_to_group("survival_timer")
	reset()

func _process(delta) -> void:
	if not is_stopped:
		time -= delta
		seconds = int(time)
		msec = int(fmod(time, 1) * 100)
		
		$seconds.text = "%02d." % seconds
		$msec.text = "%02d" % msec
	
func stop() -> void:
	is_stopped = true
	set_process(false)
	
func add_time(amount: float) -> void:
	time += amount
	
func get_survival_time() -> float:
	return time

func reset():
	time = 0.0
	seconds = 0
	msec = 0
	is_stopped = false
	set_process(true)
	
	$seconds.text = "00."
	$msec.text = "00"
