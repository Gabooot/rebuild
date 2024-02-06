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
@onready var Network : Node = get_node("Network")

@export var RADAR_SCALE : int = 5

func _ready():
	if "--server" in OS.get_cmdline_args():
		get_node("Network").start_server(5195)
		print("starting server")
	
	self.player_added.connect(_on_player_added)
	self.player_disconnected.connect(_on_player_disconnected)
	self.space = get_world_3d().get_space()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	if not self.is_in_simulation:
		game_logic.call()
	else:
		return


func _server_game_loop() -> void:
	var updates : Array[Dictionary] = Network.poll()
	
	for update in updates:
		var id = update.id
		if self.network_objects.has(id):
			self.network_objects[id].tank.update_state(update)
	
	self.emit_signal("before_simulation")
	self.emit_signal("simulate")
	self.emit_signal("after_simulation")
	self._send_updates()


func _client_game_loop() -> void:
	var updates : Array[Dictionary] = Network.poll()
	self.current_tick += 1
	
	for update in updates:
		var id = update.id
		if self.network_objects.has(id):
			self.network_objects[id].tank.update_state(update)
	
	self._resimulate()
	self.active_tick = self.current_tick
	
	if self.network_objects.has(self_id):
		var player_inputs = self._get_player_inputs()
		self.queue_for_output(player_inputs)
		#if player_inputs.speed_input > 0:
			#print("client tick: ", self.active_tick, " input: ", player_inputs.speed_input, " position: ", network_objects[self_id].tank.victim.global_position)
		self.network_objects[self_id].tank.update_state(player_inputs)
	else:
		pass
	
	self.emit_signal("before_simulation")
	self.emit_signal("preserve")
	self.emit_signal("simulate")
	self.emit_signal("after_simulation")
	#PhysicsServer3D.space_flush_queries(space)
	#PhysicsServer3D.space_step(space,0.0166667)
	self._send_updates()

func _resimulate() -> void:
	var simulation_index = self.resimulation_request

	if simulation_index:
		self.is_in_simulation = true
		#ILOVEMAGICNUMBERSILOVEMAGICNUMEBRS
		if (self.current_tick - simulation_index) > 19:
			self.resimulation_request = null
			return 
		self.emit_signal("restore", simulation_index)
		self.active_tick = simulation_index
		while simulation_index < self.current_tick:
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
	
	if Input.is_action_pressed("jump"):
		game_input.is_jumping = true
	if Input.is_action_just_pressed("shoot"):
		game_input.is_shooting = true
	game_input.order = self.current_tick
	return game_input

func _send_updates() -> void:
	Network.send_updates(outputs)
	self.outputs = []

func _singleplayer_loop() -> void:
	for player in self.network_objects.values():
		player.tank.update_from_input

func _on_player_added(id : int, player_name : String, type : String) -> void:
	var player_dict = {"name": player_name, "score": 0, "tank": null}
	player_dict.tank = self._create_tank(type, id)
	network_objects[id] = player_dict
	#if multiplayer.is_server():
		#print("Server player dictionary: ", self.player_dictionary)

func _create_tank(type : String, id : int) -> Node:
	var network_array: Array
	
	match type:
		"server":
			network_array = NetworkObjects.create("tank", "server", id)
		"client":
			network_array = NetworkObjects.create("tank", "client", id)
			var radar_icon = preload("res://radar_tank.tscn")
			radar_icon = radar_icon.instantiate()
			get_node("radar/rotater/mover").add_child(radar_icon)
			radar_icon.player = network_array[0]
		"player":
			network_array = NetworkObjects.create("player", "player", id)
			get_node("radar/radar_player").player = network_array[0]
			get_node("HUD/scope/shot_counter").player_tank = network_array[0]
			self.self_id = id
	
	self.add_child(network_array[0])
	#network_array[0].change_global_position(self._spawn())
	return network_array[1]

func _spawn() -> Vector3:
	return Vector3(10, 5, 10)

func _on_player_disconnected(id : int) -> void:
	self.network_objects[id].tank.victim.queue_free()
	self.network_objects.erase(id)

func disconnect_client() -> void:
	for player in self.network_objects.values():
		player.tank.queue_free()
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
