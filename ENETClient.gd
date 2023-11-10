extends Node

var client = ENetMultiplayerPeer.new()
var players_dict = {}
var server_slot = -1
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
func spawn_tanks(own_slot : int) -> void:
	self.server_slot = own_slot
	for i in players_dict:
		if i != self.server_slot:
			get_parent().spawn(Vector3(-1,-1,-1), i, "client")

@rpc
func start_udp_connection(slot):
	%UDPclient.start_client(slot)

@rpc("reliable")
func _add_player(player_name : String, slot : int) -> void:
	players_dict[slot] = player_name
	get_parent().spawn(Vector3(-1,-1,-1), slot, "client")

func _on_client_button_button_up():
	player_name = str(randf())
	var error = client.create_client("45.33.68.146", 5195)
	multiplayer.set_multiplayer_peer(client)
	multiplayer.peer_connected.connect(_peer_connected)

func _peer_connected(id):
	print("peer: ", id, " connected")
	

@rpc("reliable")
func remove_player(slot : int) -> void:
	if players_dict.has(slot):
		players_dict.erase(slot)
		get_parent().get_node(str(slot)).queue_free()
