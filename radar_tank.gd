extends Polygon2D

var radar_center = Vector2(250,250)
var twod_position = Vector2(0,0)
var twod_rotation = 0.0
var RADAR_SCALE = null
# Called when the node enters the scene tree for the first time.
func _ready():
	RADAR_SCALE = get_node("/root/game").RADAR_SCALE
	position = radar_center


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	twod_position = Vector2(%player.global_position.x * RADAR_SCALE, %player.global_position.z * RADAR_SCALE) 
	twod_rotation =  %player.global_rotation.y
