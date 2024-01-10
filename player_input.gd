extends OrderedInput
class_name PlayerInput

var rotation : float = 0.0
var speed : float = 0.0
var jumped : bool = false
var shot_fired : bool = false
var id : Variant = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _init(rotation : float=0.0, speed : float=0.0, jumped : bool=false, shot_fired : bool=false, order : int=0, id: Variant = null):
	if (abs(rotation) > 1) or (abs(speed) > 1):
		self.free()
	self.rotation = rotation
	self.speed = speed
	self.jumped = jumped
	self.shot_fired = shot_fired
	self.order = order
	self.id = id

func to_byte_array() -> PackedByteArray:
	return var_to_bytes([self.rotation, self.speed, self.jumped, self.shot_fired, self.order])
