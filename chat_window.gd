extends RichTextLabel

var last_message_time = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	self.text = "[center]Press \"N\" to chat[center]"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Time.get_ticks_msec() - self.last_message_time > 5000:
		self.text = ""


func _on_game_message_received(message, sender):
	self.text = "[center]" + "[color=yellow]" + sender + ": [/color]" + message + "[center]"
	last_message_time = Time.get_ticks_msec()
