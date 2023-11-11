extends Node
const MAX_PLAYERS = 12
var server = ENetMultiplayerPeer.new()
@onready var client = get_node("../ENETClient")

var server_on = false
var players_dict = {}
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
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
	#%radar.queue_free()
	#%player.queue_free()

func _on_server_button_button_up():
	start_server(5195)

func _on_client_connected(id :int):
	client.rpc_id(id, "send_info")

func _on_disconnect_server():
	pass

func _on_client_disconnected(id :int):
	print("Server: Client ", id, " is disconnected")
	for player in players_dict:
		if players_dict[player]["id"] == id:
			client.rpc("remove_player", player)
			players_dict[player].tank.queue_free()
			players_dict.erase(player)

@rpc("reliable", "any_peer") 
func _receive_player_info(data : String, id=multiplayer.get_remote_sender_id()) -> void:
	
	var k = 0
	for i in range(0, MAX_PLAYERS):
		if players_dict.has(i):
			continue
		else:
			players_dict[i] = {"name": data, "id": id}
			get_parent().spawn(Vector3(0, 0.5, 15), i)
			self.players_dict[i]["tank"] = get_parent().get_node(str(i))
			k = i
			break
	
	for j in players_dict.keys():
		if players_dict[j].id != id:
			client.rpc_id(players_dict[j].id, "_add_player", data, k)
	
	client.rpc_id(id, "sync_player_names", strip_ids(players_dict))
	client.rpc_id(id, "spawn_tanks", k)
	client.rpc_id(id, "start_udp_connection", k)
	print("Client: connected to peer", id)

func strip_ids(dict : Dictionary) -> Dictionary:
	var stripped = {}
	for key in dict.keys():
		stripped[key] = dict[key].name
	return stripped
