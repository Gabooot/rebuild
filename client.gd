extends Node

var udp = PacketPeerUDP.new()
var connected = false
@export var is_client = false
func _ready():
	if is_client:
		udp.connect_to_host("127.0.0.1", 5194)

func _process(_delta):
	connect_to_server()
	

func connect_to_server():
	var data = %player/collision.global_position
	data = [data[0], data[1], data[2]]
	if !connected and is_client:
		udp.put_packet(PackedFloat32Array(data).to_byte_array())
	elif is_client:
		udp.put_packet(PackedFloat32Array(data).to_byte_array())
	if udp.get_available_packet_count() > 0:
		print("Connected: %s" % udp.get_packet().to_float32_array())
		connected = true

func player_movement():
	pass

func _on_client_button_button_up():
	if not is_client:
		is_client = true
		udp.connect_to_host("127.0.0.1", 5194)
