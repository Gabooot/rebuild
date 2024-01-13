extends Node

const TIMEOUT_ON_JOIN = 2500
# TODO change to configurable
var max_players : int = 32

@onready var base : Node = get_node("/root/game")
var client_queue : Array = []
var current_patient = null
var active_ids : Array = []
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if multiplayer.is_server():
		self.integrate_new_clients()

func start_server(port : int) -> Error:
	var server = ENetMultiplayerPeer.new()
	var err = server.create_server(port)
	if err != 0:
		return err
	else:
		multiplayer.set_multiplayer_peer(server)
		multiplayer.peer_connected.connect(_on_client_connected)
		multiplayer.peer_disconnected.connect(_on_client_disconnected)
		return 0

func start_client(address : String, port : int) -> Error:
	var client = ENetMultiplayerPeer.new()
	var error = client.create_client(address, port)
	multiplayer.set_multiplayer_peer(client)
	return error

func add_player(player_array : Array, tank_type : String) -> void:
	base.emit_signal("player_added",{"id": player_array[0], "name": player_array[1], "type": tank_type})
	
func _on_client_connected(id):
	self._add_client(id)

func _on_client_disconnected(id):
	base.emit_signal("player_disconnected", id)

func _add_client(id):
	self.client_queue.append(id)

func integrate_new_clients() -> void:
	var patient = self.current_patient
	if (not patient) and self.client_queue:
		var id = self.client_queue.pop_front()
		# id, name, udp confirmation
		self.current_patient = [id, null, null, Time.get_ticks_msec()]
		rpc_id(id, "sync_new_player", get_client_friendly_data(), id)
	elif patient:
		if not (null in patient):
			self._server_add_player(patient.slice(0,2))
			self.current_patient = null
		elif (patient[3] - Time.get_ticks_msec()) > TIMEOUT_ON_JOIN:
			multiplayer.network_peer.disconnect_peer(patient[1], true)
			self.current_patient = null
		else:
			return
	else:
		return

func _server_add_player(player_array : Array) -> void:
	for id in active_ids:
		rpc_id(id, "add_player", player_array, "client")
	rpc_id(player_array[1], "add_player", player_array, "player")
	self.add_player(player_array, "server")
	self.active_ids.append(player_array[1])

@rpc("reliable")
func sync_new_player(names : Dictionary, passkey : int) -> void:
	for key in names:
		names[key].tank = base._create_tank("client")
	base.player_dictionary = names
	rpc_id(1, "add_new_player_name", get_parent().public_name)
	%UDP.start_client(passkey)
	base.game_logic = base.game_loop
	

@rpc("any_peer", "reliable")
func add_new_player_name(player_name : String) -> void: 
	if multiplayer.get_remote_sender_id() != self.current_patient[1]:
		return
	else:
		self.current_patient[1] = player_name

func get_client_friendly_data() -> Dictionary:
	var current_players = base.player_dictionary
	var client_dictionary = {}
	
	for key in current_players.keys():
		var player = current_players[key]
		client_dictionary[key] = {"name": player.name, "score": player.score, "type": "client"}
	
	return client_dictionary
