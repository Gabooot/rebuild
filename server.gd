extends Node

var server = UDPServer.new()
var peers = []
var num_players : int = 0
var udp_player_ids = {}
@onready var game = get_parent()
@export var is_server = false
var packet_number : float = 0.0

func _ready():
	if is_server:
		server.listen(5194)

func _physics_process(delta):
	server.poll()
	initialize_new_connection()
	update_positions(delta)
	send_positions()

func initialize_new_connection() -> void:
	if server.is_connection_available():
		var peer : PacketPeerUDP = server.take_connection()
		var packet = peer.get_packet()
		var error = peer.get_packet_error()
		if error != OK:
			print("UDP initialization failed: failed to get PackedByteArray")
			return 
		
		var data = Array(packet.to_float32_array())
		if not data:
			print("UDP initialization failed: bad data")
			return
		
		print("Accepted peer: %s:%s" % [peer.get_packet_ip(), peer.get_packet_port()])
		print("Received data: %s" % [data])
		var player_slot = int(data[0])
		peer.put_packet(packet)
		%ENETServer.players_dict[player_slot]["udp_peer"] = peer
		peers.append(peer)
		num_players = len(peers)

func is_packet_valid(packet : PackedByteArray):
	pass

func _on_server_button_button_up():
	start_server()

func start_server():
	if not is_server:
		is_server = true
		server.listen(5194)

func update_positions(delta) -> void:
	for player in %ENETServer.players_dict.values():
		if not player.has("udp_peer"):
			continue
		
		var tank = player.tank
		if player.udp_peer.get_available_packet_count() != 0:
			for i in range(player.udp_peer.get_available_packet_count()):
				player.tank.add_ordered_input(extract_packet_data(player.udp_peer.get_packet()))
		tank.update_from_input(delta)

func get_most_recent_packet(peer : PacketPeerUDP) -> Dictionary:
	var packets = Array()
	for i in range(peer.get_available_packet_count()):
		packets.append(extract_packet_data(peer.get_packet()))
		packets.sort_custom(func(a, b): return a.player_tick > b.player_tick)
	for packet in packets:
		if packet.shot_fired:
			packets[-1].shot_fired = true
			break
		else:
			pass
	return packets[-1]

func extract_packet_data(packet) -> Dictionary:
	var player_input = {"rotation": 0.0, "speed": 0.0, "jumped": false, "shot_fired": false, "player_tick": 0}
	var data = packet.to_float32_array()
	#print("Receieved rotation: ", data[0])
	if len(data) == 5:
		player_input.rotation = data[0]
		player_input.speed = data[1]
		if data[2] > 0:
			player_input.jumped = true
		if data[3] > 0:
			player_input.shot_fired = true
		player_input.player_tick = data[4]
		return player_input
	else:
		return player_input

func send_positions() -> void:
	var positions = PackedFloat32Array()
	for i in %ENETServer.players_dict.keys():
		var tank = game.get_node(str(i))
		if not tank:
			continue
		var quaternion = tank.global_transform.basis.get_rotation_quaternion()
		var origin = tank.global_transform.origin#  + Vector3(0,0,3)
		var velocity = tank.velocity
		var angular_velocity = tank.angular_velocity
		var shot_fired = float(tank.shot_fired)
		tank.shot_fired = false
		var data = PackedFloat32Array([quaternion.x, quaternion.y, quaternion.z, quaternion.w,\
			origin.x, origin.y, origin.z, velocity.x, velocity.y, velocity.z,\
			angular_velocity, shot_fired, Time.get_ticks_msec(), tank.current_input.player_tick, i])
		positions.append_array(data)
		#print("Time: ", positions[-3])
	
	for j in %ENETServer.players_dict:
		if %ENETServer.players_dict[j].has("udp_peer"):
			%ENETServer.players_dict[j]["udp_peer"].put_packet(positions.to_byte_array())
