extends Node
class_name SynchronizationPeer

var peer : PacketPeerUDP = null
var last_remote_tick : int = 0 
var current_local_tick : int = 0
var owned_nodes : Dictionary = {}
var visible_nodes : Dictionary = {}

func _init(peer : PacketPeerUDP):
	self.peer = peer

func add_owned_node(id : int, network_interface : NetworkInterface) -> void:
	self.owned_nodes[id] = network_interface

func get_owned_node_or_null(id : int) -> NetworkInterface:
	return self.owned_nodes.get(id)

func remove_owned_node(id : int) -> bool:
	return self.owned_nodes.erase(id)

func add_visible_node(id : int, network_interface : NetworkInterface) -> void:
	self.visible_nodes[id] = network_interface

func remove_visible_node(id : int) -> bool:
	return self.visible_nodes.erase(id)

func get_visible_nodes() -> Array:
	return self.visible_nodes.values()

func process_packet(packet : Array) -> void:
	var remote_tick : int = packet.pop_back()
	var local_tick  : int = packet.pop_back()
	#print("Remote tick: ", remote_tick, " Local tick: ", local_tick)
	if remote_tick > self.last_remote_tick:
		self.last_remote_tick = remote_tick
	else:
		pass
	for update in packet:
		var interface : NetworkInterface = SynchronizationManager.network_objects.get(update.pop_back())
		if interface:
			update[-1].order = remote_tick
			interface.update_state(update.pop_back())
		else:
			pass
