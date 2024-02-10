extends ShapeCast3D
class_name HackyArea3D

@onready var game_manager = get_node("/root/game")
var overlapping_bodies : Array[Node3D] = []

func _init(mask : int=8, threed_shape : Shape3D=SphereShape3D.new()):
	self.collide_with_areas = true
	self.set_collision_mask_value(mask, true)
	shape=threed_shape

# Called when the node enters the scene tree for the first time.
func _ready():
	self.target_position = Vector3(0,0,0)


func _on_establish_state() -> void:
	force_shapecast_update()
	self.overlapping_bodies = []
	for i in range(get_collision_count()):
		self.overlapping_bodies.append(self.get_collider(i))
	#print("Overlapping bodies: ", self.overlapping_bodies)

func get_overlapping_bodies() -> Array[Node3D]:
	_on_establish_state()
	return self.overlapping_bodies.duplicate()
