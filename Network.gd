# Public interface for frankenstein networking setup
extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

# Don't call this before starting network
func poll() -> Array[OrderedInput]:
	return %UDP.poll()

func start_server(port : int) -> Error:
	var error = %ENET.start_server(port)
	%UDP.start_server(port)
	return error

func start_client(address : String, port : int) -> Error:
	var error = %ENET.start_client(address, port)
	%UDP.start_client(address, port)
	return error

#Send unreliable updates (Array of OrderedInputs) via raw UDP. 
func send_updates(updates : Array[OrderedInput]) -> void:
	%UDP.send_updates(updates)
