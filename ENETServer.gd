extends Node

var server = ENetMultiplayerPeer.new()
@onready var client = get_node("../ENETClient")

var server_on = false
var player_ids = [-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1]
var name_dict = {}
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if server_on:
		pass

func start_server(port):
	server_on = true
	var err = server.create_server(port)
	if err != OK:
		prints("Server start failed.")
		return
	multiplayer.set_multiplayer_peer(server)
	multiplayer.peer_connected.connect(_on_client_connected)
	multiplayer.peer_disconnected.connect(_on_client_disconnected)
	multiplayer.server_disconnected.connect(_on_disconnect_server)




func _on_server_button_button_up():
	start_server(5195)

func _on_client_connected(id :int):
	client.rpc_id(id, "send_info")

func _on_disconnect_server():
	pass


func _on_client_disconnected(id :int):
	print("Server: Client ", id, " is disconnected")

@rpc("reliable", "any_peer") 
func _receive_player_info(data : String) -> void:
	var id = multiplayer.get_remote_sender_id()
	
	var i = 0
	for j in player_ids:
		if j == -1:
			player_ids[i] = id
			break
		else:
			i += 1
	
	print("name: ", data)
	name_dict[i] = data
	client.rpc_id(id, "sync_player_names", name_dict)
	client.rpc_id(id, "spawn_tanks", i)
	client.rpc_id(id, "start_udp_connection", i)
	print("Client: connected to peer", id)
