extends TextEdit


# Called when the node enters the scene tree for the first time.
func _ready():
	self.release_focus()
	self.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if self.text.ends_with("\n"):
		self.send_message(self.text)
		

func send_message(message : String) -> void:
	get_node("/root/game/Network").send_message(message)
	self.text = ""
	self.release_focus()
	self.visible = false
	
