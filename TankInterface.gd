# Base class for client and server-side tanks. TankInterface holds state for the tank (e.g. velocity or inputs) 
# and passes data to and from Flag functions. Flags must be able to handle input from clients and servers. 
# Flags should provide a reversed version of a server input. Default tank/flag are for server.
 
extends TeleportableCharacterBody
class_name TankInterface

var flag : Flag
var buffer : InputBuffer
var id : int = 0

var angular_velocity : float = 0.0
var speed : float = 0.0
var shot_fired : bool = false
var shot_timers = [0,0,0]
var current_order = 0

@onready var game_controller : Node3D = get_node("/root/game")

func _ready():
	Flag.new(self)
	self.buffer = PlayerInputBuffer.new(PlayerInput.new(), 4)
	self.add_child(TeleportDevice.new())

func add_ordered_input(input : OrderedInput) -> void:
	self.buffer.add(input)

func update_from_input(input : OrderedInput=self.buffer.take()) -> Variant:
	flag.run_input_from_client(input)
	self.current_order = input.order
	#print("Server position: ", self.global_position)
	return flag.get_state()

func change_global_position(new_position : Vector3) -> void:
	self.global_position = new_position
