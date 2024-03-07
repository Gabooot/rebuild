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
		print("Error: ", err)
		return err
	else:
		multiplayer.set_multiplayer_peer(server)
		multiplayer.peer_connected.connect(_on_client_connected)
		multiplayer.peer_disconnected.connect(_on_client_disconnected)
		base.player_disconnected.connect(_disconnect_client)
		base._moving_block_experiment(0)
		return OK
	


func start_client(address : String, port : int) -> Error:
	var client = ENetMultiplayerPeer.new()
	var error = client.create_client(address, port)
	multiplayer.set_multiplayer_peer(client)
	return error

func disconnect_client() -> void:
	multiplayer.get_multiplayer_peer().disconnect_peer(0, true)
	self.client_queue = []
	self.current_patient = null
	self.active_ids = []

@rpc("reliable")
func add_player(player_array : Array, tank_type : String) -> void:
	print("Adding player")
	base.emit_signal("player_added", player_array[0], player_array[1], tank_type)
	
func _on_client_connected(id):
	self._add_client(id)

func _on_client_disconnected(id):
	rpc("_send_disconnect", id)

@rpc("reliable", "any_peer")
func _send_message_to_server(message : String) -> void:
	if multiplayer.is_server():
		self.rpc("_send_message_to_clients", message, multiplayer.get_remote_sender_id())

@rpc("reliable")
func _send_message_to_clients(message : String, sender : int) -> void:
	base.emit_signal("message_received", message, sender)

@rpc("reliable", "call_local")
func _send_disconnect(id : int) -> void:
	base.emit_signal("player_disconnected", id)

func _disconnect_client(id : int) -> void:
	active_ids.erase(id)

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
			print("player ready to add")
			self._server_add_player(patient.slice(0,2))
			self.current_patient = null
		elif (Time.get_ticks_msec() - patient[3]) > TIMEOUT_ON_JOIN:
			multiplayer.network_peer.disconnect_peer(patient[0], true)
			self.current_patient = null
		else:
			print("Resolving player status: ", current_patient)
			return
	else:
		return

func _server_add_player(player_array : Array) -> void:
	print("Server attempting to add new player")
	for id in active_ids:
		rpc_id(id, "add_player", player_array, "client")
	rpc_id(player_array[0], "add_player", player_array, "player")
	self.add_player(player_array, "server")
	self.active_ids.append(player_array[0])

@rpc("reliable")
func sync_new_player(names : Dictionary, passkey : int) -> void:
	print("Syncing existing players")
	
	for key in names:
		if names[key].has("name"):
			names[key].interface = base._create_tank("client", key)
		
	base.network_objects = names
	
	for key in names:
		if names[key].has("flag_name"):
			print("Creating flag: ", names[key])
			base._create_flag(names[key].flag_name, "client", key)
	
	rpc_id(1, "add_new_player_name", get_parent().public_name)
	%UDP.start_client(passkey)
	base._moving_block_experiment(1)


@rpc("any_peer", "reliable")
func add_new_player_name(player_name : String) -> void: 
	print("Received new player name: ", player_name)
	if multiplayer.get_remote_sender_id() != self.current_patient[0]:
		return
	else:
		self.current_patient[1] = player_name

func get_client_friendly_data() -> Dictionary:
	var network_objects = base.network_objects
	var client_dictionary = {}
	
	for key in network_objects.keys():
		var object = network_objects[key]
		if object.has("name"):
			client_dictionary[key] = {"name": object.name, "score": object.score, "type": "client"}
		elif object.has("flag"):
			client_dictionary[key] = {"flag_name": object.flag.flag_name}
	print("Client dictionary ", client_dictionary)
	return client_dictionary
