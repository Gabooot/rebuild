extends Node3D
class_name FlagPole

var tank : TankInterface
var flag : StringName
@onready var detector : HackyArea3D = HackyArea3D.new(7)
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
