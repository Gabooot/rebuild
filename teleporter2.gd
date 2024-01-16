extends Teleporter


# Called when the node enters the scene tree for the first time.
func _ready():
	target = get_node("/root/game/teleporter")
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited) 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
