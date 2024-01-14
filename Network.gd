# Public interface for frankenstein networking setup
extends Node

@onready var base = get_node("/root/game")
var public_name : String = "Anonymouse"
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func poll() -> Array[OrderedInput]:
	return %UDP.poll()

func start_server(port : int) -> Error:
	var error = %ENET.start_server(port)
	%UDP.start_server(port - 1)
	base.game_logic = base._game_loop 
	return error

func start_client(nickname : String, address : String, port : int) -> Error:
	self.public_name = nickname
	var error = %ENET.start_client(address, port)
	%UDP.server_address = address
	%UDP.server_port = port - 1
	base.game_logic = base._game_loop 
	return error

#Send unreliable updates (Array of OrderedInputs) via raw UDP. 
func send_updates(updates : Array[OrderedInput]) -> void:
	#print("Sending updates", multiplayer.is_server())
	%UDP.send_updates(updates)

func disconnect_from_server() -> void:
	pass
