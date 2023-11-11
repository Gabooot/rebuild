extends Polygon2D

var player = null
var twod_position = Vector2(0,0)
var twod_rotation = 0.0
var RADAR_SCALE = null
# Called when the node enters the scene tree for the first time.
func _ready():
	RADAR_SCALE = get_node("/root/game").RADAR_SCALE


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if player and is_instance_valid(player):
		self.position = Vector2(player.global_position.x * RADAR_SCALE, player.global_position.z * RADAR_SCALE) 
		self.rotation = player.global_rotation.y
	else:
		self.queue_free()

