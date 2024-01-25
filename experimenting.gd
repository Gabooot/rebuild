extends StaticBody3D


# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("/root/game").simulate.connect(simulate)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func simulate() -> void:
	var collide = self.move_and_collide(Vector3(0,0,-1), true)
	if collide:
		print("oopsy woopsy")
