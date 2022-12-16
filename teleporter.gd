extends Node3D
class_name Teleporter

@onready var target = Vector3(0, 7, -4)
# Called when the node enters the scene tree for the first time.
func _ready():
	self.body_entered.connect(teleport_shape) 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func teleport_shape(shape):
	shape.global_position = target
