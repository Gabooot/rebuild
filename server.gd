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
		game.spawn(Vector3(0, 0.5, 13), num_players)
		num_players = len(peers)
	send_positions()
	update_positions()
	

func _on_server_button_button_up():
	if not is_server:
		is_server = true
		server.listen(5194)

func update_positions() -> void:
	for i in range(0, peers.size()):
		var tank = game.get_node(str(i) + "/tank")
		for j in range(0, peers[i].get_available_packet_count()):
			var data = Array(peers[i].get_packet().to_float32_array())
			if data:
				tank.velocity.x = data[0]
				tank.velocity.z = data[2]
				if data[1] == 8:
					tank.velocity.y = data[1]
				tank.angular_velocity = data[3]
				#packet_number += 1
			

func send_positions() -> void:
	for i in range(0, peers.size()):
		var tank = game.get_node(str(i) + "/tank")
		var quaternion = tank.global_transform.basis.get_rotation_quaternion()
		var origin = tank.global_transform.origin + Vector3(0,0,3)
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
