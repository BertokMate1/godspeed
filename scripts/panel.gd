extends Panel

var time: float = 0.0
var seconds: int = 0
var msec: int = 0

func _process(delta) -> void:
	time += delta
	msec = fmod(time, 1) * 100
	seconds = fmod(time,1000)
	
	$seconds.text = "%02d." % seconds
	$msec.text = "%02d" % msec

func stop() -> void:
	set_process(false)
	
func get_time_formatted() -> String:
	return "%02d.%02d" % [seconds, msec]
