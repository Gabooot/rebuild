# Base class for client and server-side tanks. TankInterface holds state for the tank (e.g. velocity or inputs) 
# and passes data to and from Flag functions. Flags must be able to handle input from clients and servers. 
 
extends TeleportableCharacterBody
class_name TankInterface

var _flag : Flag=default_flag
var flag_name : String:
	get:
		return flag_name
	set(new_name):
		flag_name = new_name
		match new_name:
			"default":
				self._flag = default_flag
			"V":
				self._flag = high_speed
			_:
				self._flag = default_flag

var id : int = 0
var speed_input : float = 0.0
var steering_input : float = 0.0
var angular_velocity : float = 0.0
var engine_speed : float = 0.0
var is_shooting : bool = false
var is_jumping : bool = false
var is_dropping_flag : bool = false
var shot_timers = [0,0,0]

signal flag_dropped()

@onready var game_controller : Node3D = get_node("/root/game")

func _ready():
	#Flag.new(self)
	self.add_child(TeleportDevice.new())
	print("id: ", self.id)

func simulate() -> void:
	self._flag.simulate(self)

func grab_flag(flag_pole : FlagPole) -> void:
	if not (self.name == "input_tracker"):
		_flag.grab_flag(self, flag_pole)
