extends RichTextLabel

@onready var game_manager = get_node("/root/game")
var last_message_time = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	self.text = "[center]Press \"N\" to chat[center]"
	game_manager.message_received.connect(_on_game_message_received)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Time.get_ticks_msec() - self.last_message_time > 5000:
		self.text = ""


func _on_game_message_received(message : String, sender : int):
	var sender_text := "Anonymouse"
	if sender == 0:
		sender_text = "SERVER"
	elif (sender in game_manager.network_objects.keys()):
		sender_text = game_manager.network_objects[sender].name
	self.text = "[center]" + "[color=yellow]" + sender_text + ": [/color]" + message + "[center]"
	last_message_time = Time.get_ticks_msec()
