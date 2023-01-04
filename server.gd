extends Node

var server = UDPServer.new()
var peers = []
var num_players : int = 0
@onready var game = get_parent()
@export var is_server = false
var packet_number : float = 0.0

func _ready():
	if is_server:
		server.listen(5194)

func _physics_process(_delta):
	server.poll()
	if server.is_connection_available():
		var peer : PacketPeerUDP = server.take_connection()
		var packet = peer.get_packet()
		var data = Array(packet.to_float32_array())
		print("Accepted peer: %s:%s" % [peer.get_packet_ip(), peer.get_packet_port()])
		print("Received data: %s" % [data])
		
		peer.put_packet(packet)
		
		peers.append(peer)
		game.spawn(Vector3(0, 0.5, 15), num_players)
		num_players = len(peers)
	update_positions()
	send_positions()
	
	

func _on_server_button_button_up():
	if not is_server:
		is_server = true
		server.listen(5194)

func update_positions() -> void:
	for i in range(0, peers.size()):
		var tank = game.get_node(str(i) + "/tank")
		if peers[i].get_available_packet_count():
			tank.current_input = extract_packet_data(get_most_recent_packet(peers[i]))
			#print(tank.current_input)

func get_most_recent_packet(peer : PacketPeerUDP) -> PackedByteArray:
	var packets = Array()
	for i in range(peer.get_available_packet_count()):
		packets.append(peer.get_packet())
	return packets[-1]

func extract_packet_data(packet) -> Dictionary:
	var player_input = {"rotation": 0.0, "speed": 0.0, "jumped": false, "shot_fired": false}
	var data = packet.to_float32_array()
	player_input.rotation = data[0]
	player_input.speed = data[1]
	if data[2] > 0:
		player_input.jumped = true
	if data[3] > 0:
		player_input.shot_fired = true
	return player_input

func send_positions() -> void:
	for i in range(0, peers.size()):
		var tank = game.get_node(str(i) + "/tank")
		var quaternion = tank.global_transform.basis.get_rotation_quaternion()
		var origin = tank.global_transform.origin#  + Vector3(0,0,3)
		var velocity = tank.velocity
		var angular_velocity = tank.angular_velocity
		#print("server z value: ", origin.z)
		#print("server origin: ", origin, " server quaternion: ", quaternion)
		#print(game.get_node(str(i) + "/tank").transform.basis.x.x)
		var data = PackedFloat32Array([quaternion.x, quaternion.y, quaternion.z, quaternion.w,\
			origin.x, origin.y, origin.z, velocity.x, velocity.y, velocity.z,\
			angular_velocity, packet_number]).to_byte_array()
		#print("server data: ", Array(data.to_float32_array()), " Server quat: ", quaternion)
		packet_number += 1.0
		peers[i].put_packet(data)
