extends Node

var udp = PacketPeerUDP.new()
var is_connected = false
@export var is_client = false

var sync_history : Array = []
var sync_counter : int = 0

func _ready():
	sync_history.resize(21)
	sync_history.fill(0.0)

func _physics_process(_delta):
	if not is_connected and is_client:
		finalize_connection()
	elif is_connected and is_client:
		get_newest_update()
		apply_server_update()
		send_player_update()
	else:
		pass

func start_client(slot) -> void:
	if not is_client:
		is_client = true
		#45.33.68.146
		udp.connect_to_host("45.33.68.146", 5194)
		connect_to_udp_server(slot)
	else:
		print("Client already initiated")

func connect_to_udp_server(slot):
	%player.get_player_input()
	var data = %player.input_stream[-1]
	%player.input_stream = [%player.input_stream[-1]]
	data = [slot, data.rotation, data.speed, float(data.jumped), float(data.shot_fired), float(data.time)]
	udp.put_packet(PackedFloat32Array(data).to_byte_array())

func finalize_connection() -> void:
	if udp.get_available_packet_count() > 0:
		print("Connected: %s" % udp.get_packet().to_float32_array())
		%player.global_position = Vector3(0, 0.5, 15)
		is_connected = true

func send_player_update() -> void:
	var data = %player.input_stream[-1]
	data = [data.rotation, data.speed, float(data.jumped), float(data.shot_fired), float(data.time)]
	udp.put_packet(PackedFloat32Array(data).to_byte_array())

func get_newest_update() -> void:
	var packets = Array()
	#var player = %player/collision
	#packets.append(udp.get_packet())
	for i in range(0, udp.get_available_packet_count()):
		var packet = udp.get_packet()
		packets.append(extract_data_from_packet(packet))
		packets.reverse()
		#print(packets)
	for packet_array in packets:
		#print("Data distributed")
		distribute_data(packet_array)

func distribute_data(packet_array : Array) -> void:
	#print("Data distributed")
	for packet_dict in packet_array:
		var current_slot = int(packet_dict.player_slot)
		var enet = %ENETClient
		#print(enet.players_dict.keys())
		if current_slot in enet.players_dict.keys():
			#print("dictionary: ", enet.players_dict[current_slot], " Name: ", enet.player_name)
			if enet.players_dict[current_slot] == enet.player_name:
				#print("Server time: ", packet_dict.server_ticks_msec)
				self.update_sync_factor(packet_dict)
				%player.recent_server_data.append(packet_dict)
			else:
				var tank = get_parent().get_node(str(current_slot))
				tank.add_recent_update(packet_dict)
				tank.update_transform()
		else:
			pass
			#print("Error: tried to update position with unknown server slot #: " + str(current_slot))

func apply_server_update() -> void: 
	var player = %player
	player.get_player_input()
	player.update_transform()
	player.add_bullets()

func update_sync_factor(packet : Dictionary) -> void:
	var clock_diff = packet.player_ticks_msec - (packet.server_ticks_msec) #- latency)
	self.sync_history[sync_counter % 21] = clock_diff
	sync_counter += 1

func get_sync_factor() -> int:
	var median = self.sync_history.duplicate()
	median.sort()
	return median[10] 

func _on_client_button_button_up():
	pass

func extract_data_from_packet(packet) -> Array:
	#var data = Array(packet.to_float32_array())
	var split_data = split_packet(packet)
	#print(split_data)
	var dictionary_array = []
	
	for player_data in split_data:
		dictionary_array.append(read_player_data(player_data))
	#print(dictionary_array)
	return dictionary_array

func split_packet(packet : PackedByteArray) -> Array:
	const data_length : int = 15
	var packet_array = Array(packet.to_float32_array())
	var player_data_array = []
	
	var i = data_length
	while i <= len(packet_array):
		player_data_array.append(packet_array.slice(i - data_length, i))
		i += data_length
	
	return player_data_array

func read_player_data(data : Array) -> Dictionary:
	var packet_dict = {"quat": Quaternion(data[0], data[1], data[2], data[3]),
					"origin": Vector3(data[4], data[5], data[6]),
					"velocity": Vector3(data[7], data[8], data[9]),
					"angular_velocity": data[10],
					"shot_fired": bool(data[11]),
					"server_ticks_msec": data[12],
					"player_ticks_msec": data[13],
					"player_slot": data[14]}
	return packet_dict
