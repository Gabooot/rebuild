extends Node3D

signal tank_hit(shooter, target)
signal message_received(message, sender)
signal player_added(id : int, player_name : String, type : String)

var player_dictionary := {}
var game_logic : Callable = self._singleplayer_loop
@onready var Network : Node = get_node("Network")

@export var RADAR_SCALE : int = 5

func _ready():
	if "--server" in OS.get_cmdline_args():
		get_node("Network").start_server(5195)
		print("starting server")
	
	self.player_added.connect(_on_player_added)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	game_logic.call()

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
		if not multiplayer.is_server():
			print("update received: ", bytes_to_var(update.to_byte_array()))
		#print("Getting updates: ", updates)
		var player = player_dictionary.get(update.id)
		if player:
			if not multiplayer.is_server():
				print("Found player: ", player.tank)
			player.tank.add_ordered_input(update)
	#print("Player dictionary: ", self.player_dictionary, " ", multiplayer.is_server())
	
	for id in player_dictionary.keys():
		var result = player_dictionary[id].tank.update_from_input()
		if result:
			result.id = id
			new_inputs.append(result)
		
	Network.send_updates(new_inputs)
		
	
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
	
	match type:
		"server":
			tank_tscn = preload("res://tank.tscn")
		"client":
			tank_tscn = preload("res://client_tank.tscn")
		"player":
			tank_tscn = preload("res://player.tscn")
	
	new_tank = tank_tscn.instantiate()
	#new_tank.change_global_position(self._spawn())
	self.add_child(new_tank)
	return new_tank

func _spawn() -> Vector3:
	return Vector3(10, 5, 10)
