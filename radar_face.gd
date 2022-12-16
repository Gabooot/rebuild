extends Polygon2D

var RADAR_SCALE = null
var height = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	RADAR_SCALE = get_node("/root/game").RADAR_SCALE
	self.scale = Vector2(RADAR_SCALE, RADAR_SCALE)
	self.color = Color(0.9, 0.9, 1, 0.7)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var height_delta = abs(get_node("/root/game/player/visual").global_position.y - self.height)
	self.color = Color(0.9, 0.9, 1, (0.7 - (height_delta / 10)))
	self.scale = Vector2(RADAR_SCALE, RADAR_SCALE)
