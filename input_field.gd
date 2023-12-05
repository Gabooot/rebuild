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
	%ENETClient.rpc("send_message", message, %ENETClient.player_slot)
	self.text = ""
	self.release_focus()
	self.visible = false
	
