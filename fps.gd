extends Label


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _physics_process(delta):
	if Input.is_action_just_pressed('toggle_fps'):
		self.visible = not self.visible
	self.set_text(" FPS " + str(Engine.get_frames_per_second()))
	
