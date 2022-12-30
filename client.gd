extends Node

var udp = PacketPeerUDP.new()
var is_connected = false
@export var is_client = false

var packet_number = 0.0
func _ready():
	if is_client:
		udp.connect_to_host("127.0.0.1", 5194)

func _physics_process(delta):
	if not is_connected and is_client:
		connect_to_server()
	elif is_connected and is_client:
		send_player_movement()
		apply_server_update(delta)
	

func connect_to_server():
	var data = %player/collision.velocity
	data = [data[0], data[1], data[2], %player/collision.angular_velocity, packet_number]
	if !is_connected and is_client:
		udp.put_packet(PackedFloat32Array(data).to_byte_array())
	elif is_client:
		udp.put_packet(PackedFloat32Array(data).to_byte_array())
	if udp.get_available_packet_count() > 0:
		print("Connected: %s" % udp.get_packet().to_float32_array())
		%player/collision.global_position = Vector3(0, 0.5, 15)
		is_connected = true

func send_player_movement() -> void:
	var data = %player/collision.input_velocity
	%player/collision.input_stream.append(data)
	#print("Client input: ", data)
	data = [data[0], data[1], data[2], %player/collision.angular_velocity, packet_number]
	udp.put_packet(PackedFloat32Array(data).to_byte_array())
	packet_number += 1.0


func apply_server_update(delta) -> void:
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
