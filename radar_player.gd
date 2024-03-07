extends Polygon2D

var RADAR_SCALE = 1
var twod_position = Vector2(1.0,1.0)
var twod_rotation = 0
var player = null
# Called when the node enters the scene tree for the first time.
func _ready():
	self.RADAR_SCALE = get_node("/root/game").RADAR_SCALE
	#self.player = get_node("/root/game/player/input_tracker")
	self.position = Vector2(250,250)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_instance_valid(player):
		self.twod_position = Vector2(player.global_position.x * RADAR_SCALE, player.global_position.z * RADAR_SCALE)
		self.twod_rotation = player.global_rotation.y
