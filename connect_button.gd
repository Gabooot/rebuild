extends Button


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass




func _on_button_down():
	var client = get_node("/root/game/ENETClient")
	var nickname = get_node("../name_edit").text
	var server = get_node("../server_edit").text
	var port = int(get_node("../port_edit").text)
	#fix this bullshit
	get_node("/root/game/UDPclient").server = server
	get_node("/root/game/UDPclient").port = port - 1
	client.connect_to_server(nickname, server, port)
	get_parent().exit()
