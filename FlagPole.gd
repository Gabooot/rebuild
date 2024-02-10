extends CharacterBody3D
class_name FlagPole

var _tank : TankInterface
var id : int
var flag_name : String = "V"
@onready var detector : HackyArea3D = HackyArea3D.new(2)
@onready var game_manager : Node3D = get_node("/root/game")
var tank_id : int = -1:
	get:
		return tank_id
	set(id):
		if id == tank_id:
			return
		tank_id = id
		if game_manager.network_objects.has(id):
			self._tank = game_manager.network_objects[id].interface.victim
			if not _tank.flag_dropped.is_connected(_detach_from_tank):
				_tank.flag_dropped.connect(_detach_from_tank)
var is_active : bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	game_manager.after_simulation.connect(_after_simulation)
	self.add_child(detector)

func simulate() -> void:
	if not is_on_floor():
		var collision = self.move_and_collide(Vector3(0,-0.1,0.0))
		if collision:
			if collision.get_collider() is CharacterBody3D:
				var velocity_adjustment = collision.get_collider().velocity
				self.move_and_collide(velocity_adjustment * 0.0166667)

func _after_simulation() -> void:
	if (tank_id > 0) and (is_instance_valid(_tank)):
		self.global_position = self._tank.global_position + Vector3(0, 0.5, 0)
		#print("Evil flag, tank_id: ", self.tank_id, " tank id: ", _tank.id," own id: ", self.id, " signal_connection_status: ", _tank.flag_dropped.is_connected(_detach_from_tank))
	else:
		self.is_active = true
	
	if self.is_active:
		var bodies = detector.get_overlapping_bodies()
		for body in bodies:
			if body is TankInterface:
				body.grab_flag(self)
	

func attach_to_tank(tank_id : int) -> void:
	self.tank_id = tank_id
	self._tank.flag_name = self.flag_name
	#print("Tanks new flag: ", _tank._flag, " on-server: ", multiplayer.is_server())
	self.is_active = false

func _detach_from_tank() -> void:
	self.global_position += Vector3(0,1,0)
	self.is_active = true
	self.tank_id = -1
	_tank.flag_dropped.disconnect(_detach_from_tank)
