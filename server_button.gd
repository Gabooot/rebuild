extends Button


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_button_down():
	print("starting server")
	get_node("/root/game/UDPserver").start_server()
	get_node("/root/game/ENETServer").start_server(5195)
	get_parent().exit()
