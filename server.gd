extends Node

var server = UDPServer.new()
var peers = []
@onready var game = get_parent()
@export var is_server = false

func _ready():
	if is_server:
		server.listen(5194)

func _process(_delta):
	server.poll()
	if server.is_connection_available():
		var peer : PacketPeerUDP = server.take_connection()
		var packet = peer.get_packet()
		var data = Array(packet.to_float32_array())
		print("Accepted peer: %s:%s" % [peer.get_packet_ip(), peer.get_packet_port()])
		print("Received data: %s" % [data])
		
		peer.put_packet(packet)
		
		peers.append(peer)
		game.spawn(Vector3(data[0],data[1],data[2]))
	for i in range(0, peers.size()):
		#print(i)
		#print(peers[i].get_packet().to_float32_array())
		pass


func _on_server_button_button_up():
	if not is_server:
		is_server = true
		server.listen(5194)
