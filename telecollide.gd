extends CollisionShape3D


# Called when the node enters the scene tree for the first time.
func _ready():
	self.add_to_group("visible_on_radar")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
