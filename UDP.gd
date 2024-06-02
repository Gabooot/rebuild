extends Node

@onready var base = get_node("/root/game")
var client = null
var server = null
var polling_method : Callable = self._polling_off
var input_method : Callable = self.send_inputs_to_server
var peers : Array = []
#var output_buffer : Array[OrderedInput] = []
var server_address : String = "127.0.0.1"
var server_port : int = 5194

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if server:
		server.poll()
		self.initialize_new_clients()

func poll() -> Array:
	return polling_method.call()

func send_updates(inputs : Array[Dictionary]) -> void:
	return input_method.call(inputs)

func start_client(passkey : int, address : String=server_address, port : int=server_port) -> Error:
	client = PacketPeerUDP.new()
	print("Starting UDP client at ", address, " ", port)
	polling_method = self.poll_client
	input_method = self.send_inputs_to_server
	var err = client.connect_to_host(address, port)
	client.put_var(passkey)
	SynchronizationManager.register_peer(1, client)
	#print("Client error: ", err)
	return err

func disconnect_client() -> void:
	self.polling_method = self._polling_off
	self.peers = []
	client = null

func start_server(port : int) -> Error:
	server = UDPServer.new()
	print("Starting UDP server at port ", port)
	polling_method = self.poll_server
	input_method = self.send_inputs_to_clients
	var error = server.listen(port)
	#print("Server error: ", error)
	base.player_disconnected.connect(_on_player_disconnected)
	return error

func initialize_new_clients() -> void:
	if server.is_connection_available():
		#print("Received UDP connection")
		var peer : PacketPeerUDP = server.take_connection()
		var packet = peer.get_packet()
		var error = peer.get_packet_error()
		if (error == OK) and (ENET.current_patient):
			var data = bytes_to_var(packet)
			#print("Received starting data: ", data)
			if data == ENET.current_patient[0]:
				print("New UDP client accepted")
				ENET.current_patient[2] = peer
				self.peers.append([peer, data])
	else:
		return

func send_inputs_to_server(inputs : Array[Dictionary]) -> void:
	#print("Sedning")
	for input in inputs:
		#self.output_buffer.append(inputs[0])
		client.put_packet(var_to_bytes(input))
	#if len(self.output_buffer) > 3:
		#self.output_buffer.pop_front()
	#else:
		#pass

func poll_server() -> Array:
	#print("polling server")
	var inputs : Array = []
	
	for peer in peers:
		while peer[0].get_available_packet_count() > 0:
			var packet = bytes_to_var(peer[0].get_packet())
			packet.append(peer[1])
			inputs.append(packet)
		
	return inputs

# TODO combine packets optimally.
func send_inputs_to_clients(inputs : Array[Dictionary]) -> void:
	for peer in self.peers:
		#print("Found peer")
		for input in inputs:
			#print("sent input")
			#if input.has("next_velocity"):
				#print("update: ", input)
			input.order = base.network_objects[peer[1]].interface.current_tick
			peer[0].put_packet(var_to_bytes(input))


func poll_client() -> Array:
	#print("polling client")
	var packets : Array = []
	while client.get_available_packet_count() > 0:
		var packet = bytes_to_var(client.get_packet())
		packet.append(1)
		packets.append(packet)
	return packets


func _polling_off() -> Array[Dictionary]:
	return []


func _on_player_disconnected(id : int) -> void:
	for i in range(len(self.peers)):
		if peers[i][1] == id:
			peers.pop_at(i)
			return
