extends Node3D

signal tank_hit(shooter, target)
signal message_received(message : String, sender : int)
signal player_added(id : int, player_name : String, type : String)
signal player_disconnected(id : int)
signal node_teleported(node : Node3D, teleported : Teleporter)
signal preserve(tick_num : int)
signal restore(tick_num : int)
signal before_simulation()
signal simulate()
signal after_simulation()

var network_objects := {}
var game_logic : Callable = self._singleplayer_loop

var current_tick = 0
var active_tick = 0
var resimulation_request = null
var is_in_simulation : bool = false
var outputs : Array[Dictionary] = []
var self_id : int = -1
var space : RID 
#@onready var Network : Node = get_node("Network")
@export var RADAR_SCALE : int = 5

func _ready():
	if "--server" in OS.get_cmdline_args():
		get_node("Network").start_server(5195)
		print("starting server")
	
	self.player_added.connect(_on_player_added)
	self.player_disconnected.connect(_on_player_disconnected)
	self.space = get_world_3d().get_space()
	#self._moving_block_experiment()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	if not self.is_in_simulation:
		pass
		#game_logic.call()
	else:
		return


func _server_game_loop() -> void:
	var updates : Array[Dictionary] = Network.poll()
	
	for update in updates:
		var id = update.id
		if self.network_objects.has(id):
			self.network_objects[id].interface.update_state(update)
	print("oops")
	self.emit_signal("before_simulation")
	self.emit_signal("simulate")
	self.emit_signal("after_simulation")
	self._send_updates()


func _client_game_loop() -> void:
	self.current_tick += 1
	var updates : Array[Dictionary] = Network.poll()
	for update in updates:
		var id = update.id
		if self.network_objects.has(id):
			self.network_objects[id].interface.update_state(update)
	print("ooops")
	self._resimulate()
	self.active_tick = self.current_tick
	
	if self.network_objects.has(self_id):
		var player_inputs = self._get_player_inputs()
		self.queue_for_output(player_inputs)
		self.network_objects[self_id].interface.update_state(player_inputs)
	else:
		pass
	
	#print("running tick ", active_tick)
	self.emit_signal("before_simulation")
	self.emit_signal("preserve")
	self.emit_signal("simulate")
	self.emit_signal("after_simulation")
	#PhysicsServer3D.space_flush_queries(space)
	#PhysicsServer3D.space_step(space,0.0166667)
	self._send_updates()

func _resimulate() -> void:
	var simulation_index = self.resimulation_request
	print_debug("oppsy")
	if simulation_index:
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
			PhysicsServer3D.space_flush_queries(space)
			PhysicsServer3D.space_step(space, 0.0166667)
			self.emit_signal("before_simulation")
			self.emit_signal("preserve")
			self.emit_signal("simulate")
			self.emit_signal("after_simulation")
			simulation_index += 1
			self.active_tick = simulation_index

	self.resimulation_request = null
	self.is_in_simulation = false

func _get_player_inputs() -> Dictionary:
	var game_input = {}
	
	game_input.steering_input = Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")
	game_input.speed_input = -Input.get_action_strength("move_backward") + Input.get_action_strength("move_forward")
	game_input.is_dropping_flag = false
	
	if Input.is_action_pressed("jump"):
		game_input.is_jumping = true
	if Input.is_action_pressed("drop_flag"):
		game_input.is_dropping_flag = true
	if Input.is_action_just_pressed("shoot"):
		game_input.is_shooting = true
	game_input.order = self.current_tick
	return game_input

func _send_updates() -> void:
	Network.send_updates(outputs)
	self.outputs = []

func _singleplayer_loop() -> void:
	pass
	#for player in self.network_objects.values():
	#	player.interface.update_from_input

func _on_player_added(id : int, player_name : String, type : String) -> void:
	var player_dict = {"name": player_name, "score": 0, "tank": null}
	player_dict.interface = self._create_tank(type, id)
	network_objects[id] = player_dict


func _create_tank(type : String, id : int) -> Node:
	var network_array: Array
	
	match type:
		"server":
			network_array = NetworkObjects.create("tank", "server", id)
			print("Registered interface to: ", id)
			SynchronizationManager.register_network_interface(network_array[1], id)
		"client":
			network_array = NetworkObjects.create("tank", "client", id)
			var radar_icon = preload("res://radar_tank.tscn")
			radar_icon = radar_icon.instantiate()
			get_node("radar/rotater/mover").add_child(radar_icon)
			radar_icon.player = network_array[0]
			SynchronizationManager.register_network_interface(network_array[1], 1)
		"player":
			network_array = NetworkObjects.create("player", "player", id)
			get_node("radar/radar_player").player = network_array[0]
			get_node("HUD/scope/shot_counter").player_tank = network_array[0]
			self.self_id = id
			SynchronizationManager.register_network_interface(network_array[1], 1)
	
	self.add_child(network_array[0])
	#network_array[0].change_global_position(self._spawn())
	return network_array[1]


func _create_flag(type : String, network : String, id : int) -> FlagPole:
	var flag_data := []
	match network:
		"server":
			flag_data = NetworkObjects.create("flagpole", "server", id)
		"client":
			flag_data = NetworkObjects.create("flagpole", "simulated client", id)
	
	flag_data[0].flag_name = type
	network_objects[id] = {"flag": flag_data[0], "interface": flag_data[1],}
	self.add_child(flag_data[0])
	return flag_data[0]


func _moving_block_experiment(type : int) -> void:
	return
	var block = preload("res://MovingBlock.tscn").instantiate()
	var state_manager = StateManager.new(block, ["global_transform", "velocity", "next_velocity", "timer", "id"])
	var network_interface
	if type == 0:
		pass
		#print("spawning block on server")
		#network_interface = PlayerControlledServerInterface.new()
	else:
		#print("Spawning block on client")
		#network_interface = SimulatedClient.new()
		pass
	var new_id = -20
	network_objects[new_id] = {"interface": network_interface}
	self.add_child(block)
	block.add_child(state_manager)
	state_manager.add_child(network_interface)
	block.global_position = Vector3(12,3,14)

func _spawn_initial_flags(num_flags : int) -> void:
	return
	while num_flags > 0:
		var id = multiplayer.get_unique_id()
		var flag = _create_flag("V", "server", multiplayer.multiplayer_peer.generate_unique_id())
		flag.global_position = Vector3(randf_range(-15, 15), 5, randf_range(-15,15))
		num_flags -= 1


func _spawn() -> Vector3:
	return Vector3(10, 5, 10)

func _on_player_disconnected(id : int) -> void:
	if self.network_objects.has(id):
		#self.network_objects[id].interface.victim.queue_free()
		self.network_objects.erase(id)

func disconnect_client() -> void:
	for player in self.network_objects.values():
		player.interface.victim.queue_free()
	self.game_logic = self._singleplayer_loop
	self.network_objects = {}
	get_node("Network").disconnect_client()

func queue_for_output(state_dict : Dictionary) -> void:
	self.outputs.append(state_dict)

func request_resimulation(tick : int) -> void:
	if self.resimulation_request:
		if tick < self.resimulation_request:
			self.resimulation_request = tick
		else:
			return
	else:
		self.resimulation_request = tick
