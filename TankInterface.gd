# Base class for client and server-side tanks. TankInterface holds state for the tank (e.g. velocity or inputs) 
# and passes data to and from Flag functions. Flags must be able to handle input from clients and servers. 
# THis is the default tank/flag are for server.
 
extends TeleportableCharacterBody
class_name TankInterface

var flag : Flag
var id : int = 0

var speed_input : float = 0.0
var steering_input : float = 0.0
var angular_velocity : float = 0.0
var engine_speed : float = 0.0
var is_shooting : bool = false
var is_jumping : bool = false
var shot_timers = [0,0,0]

@onready var game_controller : Node3D = get_node("/root/game")

func _ready():
	Flag.new(self)
	self.add_child(TeleportDevice.new())

func simulate() -> void:
	flag.simulate()

