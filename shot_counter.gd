extends Polygon2D

var chambers : Array = []
var chamber_timers : Array = [-9999999,-99999,-99999]
var reload_time_msec : int = 3000

func _ready():
	chambers = [get_node("../2"), get_node("../1"), get_node("../0")]

func _process(delta):
	for i in range(len(chambers)):
		chambers[i].scale.x = max((float((reload_time_msec - (Time.get_ticks_msec() - chamber_timers[i])))/float(reload_time_msec)),0.0)

func start_shot_timer():
	var time = Time.get_ticks_msec()
	for timer in range(len(chamber_timers)):
		if time - chamber_timers[timer] < reload_time_msec:
			continue
		else:
			chamber_timers[timer] = time
			break


