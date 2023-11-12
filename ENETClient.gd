extends Node

var client = ENetMultiplayerPeer.new()
var players_dict = {}
var player_slot = -1
var player_name = null
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

@rpc("reliable") 
func send_info() -> void:
	%ENETServer.rpc_id(1, "_receive_player_info", self.player_name)

@rpc
func sync_player_names(data : Dictionary) -> void:
	players_dict = data
	print("player names synced!")
	print(players_dict)

@rpc
func spawn_tanks(player_slot : int) -> void:
	print("Tanks spawned")
	self.player_slot = player_slot
	for i in players_dict:
		if i != self.player_slot:
			get_parent().spawn(Vector3(-1,-1,-1), i, "client")

@rpc("reliable")
func start_udp_connection(slot):
	print("Starting udp connection")
	%UDPclient.start_client(slot)

@rpc("reliable")
func _add_player(new_name : String, slot : int) -> void:
	players_dict[slot] = new_name
	get_parent().spawn(Vector3(-1,-1,-1), slot, "client")

func connect_to_server(nickname : String, server : String, port : int):
	self.player_name = nickname
	var error = client.create_client(server, port)
	multiplayer.set_multiplayer_peer(client)
	multiplayer.peer_connected.connect(_peer_connected)

func disconnect_from_server() -> void:
	multiplayer.get_multiplayer_peer().close()
	self.client = ENetMultiplayerPeer.new()
	%UDPclient.stop_client()

func _peer_connected(id):
	print("peer: ", id, " connected")
	

@rpc("reliable")
func remove_player(slot : int) -> void:
	if players_dict.has(slot):
		players_dict.erase(slot)
		get_parent().get_node(str(slot)).queue_free()
