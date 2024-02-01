extends Node3D

signal tank_hit(shooter, target)
signal message_received(message : String, sender : int)
signal player_added(id : int, player_name : String, type : String)
signal player_disconnected(id : int)
signal node_teleported(node : Node3D, teleported : Teleporter)
signal preserve(tick_num : int)
signal restore(tick_num : int)
signal establish_state()
signal simulate()

var player_dictionary := {}
var game_logic : Callable = self._singleplayer_loop

var current_tick = 0
var active_tick = 0
var simulation_requests : Array[int] = []

@onready var Network : Node = get_node("Network")

@export var RADAR_SCALE : int = 5

func _ready():
	if "--server" in OS.get_cmdline_args():
		get_node("Network").start_server(5195)
		print("starting server")
	
	self.player_added.connect(_on_player_added)
	self.player_disconnected.connect(_on_player_disconnected)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	game_logic.call()
	if snapped(_delta, 0.0001) != 0.0167:
		print(snapped(_delta, 0.0001))

func spawn(location, id_number, environment="server"):
	print("id spawned: ", id_number)
	var tank = null
	if environment == "server":
		tank = preload("res://tank.tscn" )
	elif environment == "client":
		tank = preload("res://client_tank.tscn")
	var player = tank.instantiate()
	player.name = str(id_number)
	add_child(player)
	player.global_position = location
	
	if environment == "client":
		var radar_icon = preload("res://radar_tank.tscn")
		radar_icon = radar_icon.instantiate()
		radar_icon.player = player
		%radar/rotater/mover.add_child(radar_icon)

func apoptose(player):
	player.queue_free()

func _game_loop() -> void:
	var updates : Array[OrderedInput] = Network.poll()
	var players = player_dictionary.keys()
	var new_inputs : Array[OrderedInput] = []
	
	for update in updates:
		#print("Getting updates: ", updates)
		var player = player_dictionary.get(update.id)
		if player:
			player.tank.add_ordered_input(update)
	#print("Player dictionary: ", self.player_dictionary, " ", multiplayer.is_server())
	
	for id in player_dictionary.keys():
		var result = player_dictionary[id].tank.update_from_input()
		if result:
			result.id = id
			new_inputs.append(result)
		
	Network.send_updates(new_inputs)

'''
func _client_gameplay_loop() -> void:
	var updates : Array[OrderedInput] = Network.poll()
	
	for update in updates:
		var id = update.id
		if self.networked_objects has id:
			self.networked_objects[id].update_state(update)
	
	self._resimulate()
	self.current_tick += 1
	self.active_tick = self.current_tick
	
	var player_inputs = self._get_player_inputs()
	self.networked_objects[player_inputs.id].update_state(player_inputs)
	
	self.emit_signal("establish_state")
	self.emit_signal("preserve")
	self.emit_signal("simulate")
	
	self.send_updates()

func _resimulate()
	var simulation_index = self.simulation_requests.min()
	if simulation_index:
		self.emit_signal("restore", simulation_start)
		while simulation_index <= self.current_tick:
			self.emit_signal("establish_state")
			self.emit_signal("preserve")
			self.emit_signal("simulate")
			simulation_index += 1
			self.active_tick = simulation_index

func _get_player_inputs() -> Dictionary:
	var game_input = {}
	
	game_input.steering = Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")
	game_input.accelerator = -Input.get_action_strength("move_backward") + Input.get_action_strength("move_forward")
	
	if Input.is_action_pressed("jump"):
		game_input.is_jumping = true
	if Input.is_action_just_pressed("shoot"):
		game_input.is_shooting = true
	game_input.order = self.current_tick
	
	return game_input

'''

func _singleplayer_loop() -> void:
	for player in self.player_dictionary.values():
		player.tank.update_from_input

func _on_player_added(id : int, player_name : String, type : String) -> void:
	var player_dict = {"name": player_name, "score": 0, "tank": null}
	player_dict.tank = self._create_tank(type)
	player_dictionary[id] = player_dict
	if multiplayer.is_server():
		print("Server player dictionary: ", self.player_dictionary)

func _create_tank(type : String) -> Node:
	var tank_tscn : PackedScene
	var new_tank : Node
	print("What the f is going on")
	match type:
		"server":
			tank_tscn = preload("res://tank.tscn")
		"client":
			tank_tscn = preload("res://client_tank.tscn")
		"player":
			tank_tscn = preload("res://player.tscn")
	
	new_tank = tank_tscn.instantiate()
	self.add_child(new_tank)
	new_tank.change_global_position(self._spawn())
	return new_tank

func _spawn() -> Vector3:
	return Vector3(10, 5, 10)

func _on_player_disconnected(id : int) -> void:
	self.player_dictionary[id].tank.queue_free()
	self.player_dictionary.erase(id)

func disconnect_client() -> void:
	for player in self.player_dictionary.values():
		player.tank.queue_free()
	self.game_logic = self._singleplayer_loop
	self.player_dictionary = {}
	get_node("Network").disconnect_client()
