extends Polygon2D

var chambers : Array = []
var chamber_timers : Array = [-9999999,-99999,-99999]
var reload_time_ticks : int = 120
var player_tank : TankInterface

func _ready():
	chambers = [get_node("../2"), get_node("../1"), get_node("../0")]

func _process(delta):
	for i in range(len(chambers)):
		chambers[i].scale.x = max((float(chamber_timers[i]) / float(reload_time_ticks)), 0.0)
	if self.player_tank:
		self._check_for_new_timers() 

func start_shot_timer(reload_time : int):
	var time = Time.get_ticks_msec()
	for timer in range(len(chamber_timers)):
		if time - chamber_timers[timer] < reload_time:
			continue
		else:
			chamber_timers[timer] = time
			break

func _check_for_new_timers() -> void:
	if is_instance_valid(player_tank):
		self.chamber_timers = player_tank.shot_timers
	#print(self.chamber_timers, " ", player_tank.shot_timers)
