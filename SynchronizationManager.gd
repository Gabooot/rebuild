extends Node3D

@onready var Space : RID = get_world_3d().get_space()

signal preserve(tick_num : int)
signal restore(tick_num : int)
signal collect_input()
signal simulate()

signal peer_added(id : int)

var synchronization_peers : Dictionary = {}
var network_objects : Dictionary = {}
var current_tick = 0
var active_tick = 0
var resimulation_request = null
var is_in_simulation : bool = false
var network_active : bool = false
var outputs : Array[Dictionary] = []
#var self_id : int = -1

func _physics_process(_delta):
	if network_active:
		self._client_game_loop()
	else:
		pass

func _client_game_loop() -> void:
	self.current_tick += 1
	var updates : Array = Network.poll()
	for update in updates:
		#if multiplayer.is_server():
		#	print("update: ", update[-1])
		var peer = self.synchronization_peers.get(update.pop_back())
		if peer:
			#if multiplayer.is_server():
				#print("found peer: ", update)
			peer.process_packet(update)
	
	self._resimulate()
	self.active_tick = self.current_tick
	
	'''if self.network_objects.has(self_id):
		var player_inputs = self._get_player_inputs()
		self.queue_for_output(player_inputs)
		self.network_objects[self_id].interface.update_state(player_inputs)
	else:
		pass'''
	
	#print("running tick ", active_tick)
	#self.emit_signal("before_simulation")
	self.emit_signal("collect_input")
	self._send_updates()
	self.emit_signal("preserve")
	self.emit_signal("simulate")
	self.resimulation_request = null
	#self.emit_signal("after_simulation")
	#PhysicsServer3D.space_flush_queries(space)
	#PhysicsServer3D.space_step(space,0.0166667)
	

func _send_updates() -> void:
	for peer : SynchronizationPeer in synchronization_peers.values():
		#print("found peer")
		var state_update : Array = []
		for network_interface : NetworkInterface in network_objects.values():
			var delta_state = network_interface.get_delta_state(peer.last_remote_tick)
			#if multiplayer.is_server():
			#	print("Delta :", delta_state)
			state_update.append([delta_state, network_interface.id])
		#print("state update: ", state_update)
		if state_update:
			state_update += [peer.last_remote_tick, current_tick]
			#print("Sent update: ", bytes_to_var(var_to_bytes(state_update)))
			peer.peer.put_packet(var_to_bytes(state_update))
		else:
			return

func _resimulate() -> void:
	var simulation_index = self.resimulation_request

	if simulation_index:
		print("Resimulating from: ", simulation_index, " to: ", self.current_tick)
		self.active_tick = simulation_index
		#print("Resimulating difference: ", current_tick - simulation_index)
		self.is_in_simulation = true
		#ILOVEMAGICNUMBERSILOVEMAGICNUMEBRS
		if (self.current_tick - simulation_index) > Shared.num_states_stored:
			self.resimulation_request = null
			self.is_in_simulation = false
			return
		self.emit_signal("restore", simulation_index)
		
		while simulation_index < self.current_tick:
			#print("re-running tick ", active_tick)
			PhysicsServer3D.space_flush_queries(Space)
			PhysicsServer3D.space_step(Space, 0.0166667)
			#self.emit_signal("before_simulation")
			self.emit_signal("preserve")
			self.emit_signal("simulate")
			#self.emit_signal("after_simulation")
			simulation_index += 1
			self.active_tick = simulation_index

	self.is_in_simulation = false


func request_resimulation(tick : int) -> void:
	if self.resimulation_request:
		if tick < self.resimulation_request:
			self.resimulation_request = tick
		else:
			return
	else:
		self.resimulation_request = tick


func start_synchronization() -> void:
	self.network_active = true


func stop_synchronization() -> void:
	self.network_active = false


func register_network_interface(network_interface : NetworkInterface, peer_id : int) -> void:
	var player : SynchronizationPeer = self.synchronization_peers.get(peer_id)
	if player:
		player.add_owned_node(network_interface.id, network_interface)
		network_objects[network_interface.id] = network_interface
	else:
		print_debug("Peer ", peer_id, " not found!")


func register_peer(peer_id : int, peer : PacketPeerUDP) -> void:
	if synchronization_peers.has(peer_id):
		print_debug("Peer already registered to id #", peer_id)
		return
	var new_peer = SynchronizationPeer.new(peer)
	synchronization_peers[peer_id] = new_peer
