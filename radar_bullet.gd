extends Sprite2D

var radar_start = Vector2(250,230)
var bullet = null
var RADAR_SCALE

# Called when the node enters the scene tree for the first time.
func _ready():
	RADAR_SCALE = get_node("/root/game").RADAR_SCALE
	self.visible = false
	#self.global_rotation = -0.4 * PI
	#self.global_position = Vector2(0,-4) 
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	#TODO Why
	if not is_instance_valid(bullet):
		self.queue_free()
	
	var next_position = Vector2(bullet.global_position.x * RADAR_SCALE, bullet.global_position.z * RADAR_SCALE)
	
	if next_position != position:
		self.visible = true
		rotation = position.angle_to_point(next_position)
		self.visible = true
	
	position = next_position
	#print("position " + str(position))
	

