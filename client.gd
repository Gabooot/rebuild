extends Node

var udp = PacketPeerUDP.new()
var is_connected = false
@export var is_client = false

func _ready():
	if is_client:
		udp.connect_to_host("127.0.0.1", 5194)

func _physics_process(delta):
	if not is_connected and is_client:
		connect_to_server()
	elif is_connected and is_client:
		send_player_movement()
		apply_server_update()
	

func connect_to_server():
	var data = %player/collision.input_stream[-1]
	data = [data.rotation, data.speed, float(data.jumped), float(data.shot_fired)]
	if !is_connected and is_client:
		udp.put_packet(PackedFloat32Array(data).to_byte_array())
	elif is_client:
		udp.put_packet(PackedFloat32Array(data).to_byte_array())
	if udp.get_available_packet_count() > 0:
		print("Connected: %s" % udp.get_packet().to_float32_array())
		%player/collision.global_position = Vector3(0, 0.5, 15)
		%player/collision.input_stream = [%player/collision.input_stream[-1]]
		is_connected = true

func send_player_movement() -> void:
	var data = %player/collision.input_stream[-1]
	data = [data.rotation, data.speed, float(data.jumped), float(data.shot_fired)]
	udp.put_packet(PackedFloat32Array(data).to_byte_array())



func apply_server_update() -> void:
	var packets = Array()
	var player = %player/collision
	#packets.append(udp.get_packet())
	for i in range(0, udp.get_available_packet_count()):
		var packet = udp.get_packet()
		packets.append(extract_data_from_packet(packet))
		packets.reverse()
		player.recent_server_data.append_array(packets)

func _on_client_button_button_up():
	if not is_client:
		is_client = true
		udp.connect_to_host("127.0.0.1", 5194)

func extract_data_from_packet(packet) -> Dictionary:
	var data = Array(packet.to_float32_array())
	var packet_dict = {"quat": Quaternion(data[0], data[1], data[2], data[3]),
					"origin": Vector3(data[4], data[5], data[6]),
					"velocity": Vector3(data[7], data[8], data[9]),
					"angular_velocity": data[10],
					"packet_number": data[11]}
	return packet_dict
