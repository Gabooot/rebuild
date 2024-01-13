extends Node
var client = PacketPeerUDP.new()
var server = UDPServer.new()
var polling_method : Callable = self.poll_client
var input_method : Callable = self.send_inputs_to_server
var peers : Array = []

var server_address : String = "127.0.0.1"
var server_port : int = 5194

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func poll() -> Array[OrderedInput]:
	return polling_method.call()

func send_updates(inputs : Array[OrderedInput]) -> void:
	return input_method.call(inputs)

func start_client(passkey : int, address : String=server_address, port : int=server_port) -> Error:
	polling_method = self.poll_client
	input_method = self.send_inputs_to_server
	client.connect_to_host(address, port)
	var err = client.put_packet(var_to_bytes(passkey))
	return err

func start_server(port : int) -> Error:
	polling_method = self.poll_server
	input_method = self.send_inputs_to_clients
	var error = server.listen(port)
	return error

func initialize_new_clients() -> void:
	if server.is_connection_available():
		var peer : PacketPeerUDP = server.take_connection()
		var packet = peer.get_packet()
		var error = peer.get_packet_error()
		if (error == OK) and (%ENET.current_patient):
			var data = bytes_to_var(packet)
			if data == %ENET.current_patient[0]:
				%ENET.current_patient[2] = true
				self.peers.append([peer, data])
	else:
		return

func send_inputs_to_server(inputs : Array[PlayerInput]) -> void:
	for input in inputs:
		client.put_packet(input.to_byte_array())

func poll_server() -> Array[PlayerInput]:
	var inputs = []
	for peer in peers:
		while peer[0].get_available_packet_count() > 0:
			var packet = bytes_to_var(peer[0].get_packet())
			if typeof(packet) != 28:
				continue
			else:
				packet.append(peer[1])
			packet = PlayerInput.new.callv(packet) 
			inputs.append(packet)
	return inputs

# TODO combine packets optimally
func send_inputs_to_clients(inputs : Array[ServerInput]) -> void:
	var byte_arrays : Array[PackedByteArray]= []
	for input in inputs:
		byte_arrays.append(input.to_byte_array())
	for peer in self.peers:
		for byte_array in byte_arrays:
			peer[0].put_packet(byte_array)

func poll_client() -> Array[ServerInput]:
	var packets : Array[ServerInput] = []
	while client.get_available_packet_count() > 0:
		var packet = client.get_packet()
		packets.append(ServerInput.new.callv(bytes_to_var(packet)))
	return packets
		
