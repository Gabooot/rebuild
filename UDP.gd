extends Node

@onready var base = get_node("/root/game")
var client = null
var server = null
var polling_method : Callable = self._polling_off
var input_method : Callable = self.send_inputs_to_server
var peers : Array = []

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

func poll() -> Array[OrderedInput]:
	return polling_method.call()

func send_updates(inputs : Array[OrderedInput]) -> void:
	return input_method.call(inputs)

func start_client(passkey : int, address : String=server_address, port : int=server_port) -> Error:
	client = PacketPeerUDP.new()
	print("Starting UDP client at ", address, " ", port)
	polling_method = self.poll_client
	input_method = self.send_inputs_to_server
	var err = client.connect_to_host(address, port)
	client.put_var(passkey)
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
		print("Received UDP connection")
		var peer : PacketPeerUDP = server.take_connection()
		var packet = peer.get_packet()
		var error = peer.get_packet_error()
		if (error == OK) and (%ENET.current_patient):
			var data = bytes_to_var(packet)
			print("Received starting data: ", data)
			if data == %ENET.current_patient[0]:
				print("New UDP client accepted")
				%ENET.current_patient[2] = true
				self.peers.append([peer, data])
	else:
		return

func send_inputs_to_server(inputs : Array[OrderedInput]) -> void:
	for input in inputs:
		client.put_packet(input.to_byte_array())

func poll_server() -> Array[OrderedInput]:
	#print("polling server")
	var inputs : Array[OrderedInput] = []
	for peer in peers:
		while peer[0].get_available_packet_count() > 0:
			var packet = bytes_to_var(peer[0].get_packet())
			if typeof(packet) != 28:
				continue
			else:
				packet.append(peer[1])
			packet = PlayerInput.new.callv(packet) 
			#print("Server interpreted packet: ", packet.speed, " ", packet.jumped)
			inputs.append(packet)
	return inputs

# TODO combine packets optimally
func send_inputs_to_clients(inputs : Array[OrderedInput]) -> void:
	var byte_arrays : Array[PackedByteArray]= []
	for input in inputs:
		#print("Sending... ", bytes_to_var(input.to_byte_array()))
		byte_arrays.append(input.to_byte_array())
	for peer in self.peers:
		for byte_array in byte_arrays:
			peer[0].put_packet(byte_array)

func poll_client() -> Array[OrderedInput]:
	#print("polling client")
	var packets : Array[OrderedInput] = []
	while client.get_available_packet_count() > 0:
		var packet = client.get_packet()
		#print("Client received packet: ", bytes_to_var(packet))
		packets.append(ServerInput.new.callv(bytes_to_var(packet)))
	return packets

func _polling_off() -> Array[OrderedInput]:
	return []

func _on_player_disconnected(id : int) -> void:
	for i in range(len(self.peers)):
		if peers[i][1] == id:
			peers.pop_at(i)
			return
