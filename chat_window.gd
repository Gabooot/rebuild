extends RichTextLabel

@onready var base = get_node("/root/game")
var last_message_time = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	self.text = "[center]Press \"N\" to chat[center]"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Time.get_ticks_msec() - self.last_message_time > 5000:
		self.text = ""


func _on_game_message_received(message : String, sender : int):
	var sender_text := "Anonymouse"
	if sender == 0:
		sender_text = "SERVER"
	elif (sender in base.player_dictionary.keys()):
		sender_text = base.player_dictionary[sender].name
	self.text = "[center]" + "[color=yellow]" + sender_text + ": [/color]" + message + "[center]"
	last_message_time = Time.get_ticks_msec()
