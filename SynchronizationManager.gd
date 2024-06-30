extends Node3D

@onready var Space : RID = get_world_3d().get_space()

signal preserve(tick_num : int)
signal restore(tick_num : int)
signal interface_removed(interface : NetworkInterface)
signal collect_input()
signal simulate()

signal peer_added(id : int)

var synchronization_peers : Dictionary = {}
var network_objects : Dictionary = {}
var restoration_ticks : Dictionary = {}
var resimulation_ticks : Dictionary = {}
var end_ticks : Dictionary = {}
var objects_to_resimulate : Array[NetworkInterface] = []
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
		var peer = self.synchronization_peers.get(update.pop_back())
		if peer:
			peer.process_packet(update)
	
	self._resimulate()
	self.active_tick = self.current_tick
	
	self.emit_signal("collect_input")
	self._send_updates()
	for interface_p in network_objects.values():
		interface_p.preserve()
	for interface_s in network_objects.values():
		interface_s.simulate()
	
	self.resimulation_request = null
	self.objects_to_resimulate = []
	self.restoration_ticks = {}
	self.end_ticks = {}


func _resimulate() -> void:
	var simulation_start = self.resimulation_request

	if simulation_start:
		#print("Resimulating from: ", simulation_index, " to: ", self.current_tick)
		self.active_tick = simulation_start
		if (self.current_tick - self.active_tick) > Shared.num_states_stored:
			return
		for interface in self.objects_to_resimulate:
			interface.state_manager._restore(self.active_tick)
		#self.emit_signal("restore", simulation_index)
		
		while self.active_tick < self.current_tick:
			var to_restore = restoration_ticks.get(self.active_tick)
			if to_restore:
				for interface_st in to_restore:
					interface_st.is_active = true
			
			PhysicsServer3D.space_flush_queries(Space)
			PhysicsServer3D.space_step(Space, 0.0166667)
			#self.emit_signal("before_simulation")
			for interface_p in network_objects.values():
				if interface_p.is_active:
					interface_p.preserve()
			for interface_s in network_objects.values():
				if interface_s.is_active:
					interface_s.simulate()
			
			self.active_tick += 1
			
			var to_end = end_ticks.get(self.active_tick)
			if to_end:
				for interface_e : NetworkInterface in to_end:
					pass
					#interface_e.is_active = false


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


func request_resimulation(registrant : NetworkInterface, start : int, end : int=self.current_tick) -> void:
	if resimulation_request:
		self.resimulation_request = min(resimulation_request, start)
	else:
		self.resimulation_request = start
	
	var starting_points = restoration_ticks.get(start)
	registrant.state_manager._restore(start)
	
	if starting_points:
		starting_points.append(registrant)
	else:
		restoration_ticks[start] = [registrant]
	
	var end_points = end_ticks.get(end)
	
	if end_points:
		end_points.append(registrant)
	else:
		end_ticks[end] = [registrant]

func request_resimulation2(tick : int, simulation_groups : Array[int] = [0]) -> void:
	if resimulation_request:
		self.resimulation_request = min(resimulation_request, tick)
	else:
		self.resimulation_request = tick
	
	for group in simulation_groups:
		var current = resimulation_ticks.get(group)
		if current:
			resimulation_ticks[group] = min(current, tick)

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


func deregister_network_interface(network_interface : NetworkInterface) -> void:
	network_objects.erase(network_interface.id)
	interface_removed.emit(network_interface)


func register_network_action(network_action : RefCounted) -> void:
	self.network_actions[network_action.id] = network_action


func deregister_network_action() -> void:
	pass

func register_peer(peer_id : int, peer : PacketPeerUDP) -> void:
	if synchronization_peers.has(peer_id):
		print_debug("Peer already registered to id #", peer_id)
		return
	var new_peer = SynchronizationPeer.new(peer)
	synchronization_peers[peer_id] = new_peer
