extends TankInterface
class_name PlayerTankInterface

const MIN_ANGLE_TO_INTERPOLATE : float = 0.01
const MIN_DISTANCE_TO_INTERPOLATE : float = 0.05
var input_stream : Array[OrderedInput] = [PlayerInput.new()]
@onready var server_tracker : ServerTrackerTankInterface = get_node("server_tracker")
# Called when the node enters the scene tree for the first time.
func _ready():
	Flag.new(self)
	self.buffer = InputBuffer.new(ServerInput.new(Quaternion(0,0,0,1), Vector3(10,5,10)),2)
	self._connect_to_radar()
	self.add_child(TeleportDevice.new())

func update_from_input(server_input : OrderedInput=self.buffer.take()) -> Variant:
	#print("Server input order: ", server_input.order)
	var current_input = self.get_player_input()
	input_stream.append(current_input)
	var extrapolation_factor = get_local_tick_diff(server_input)
	#print("Before: ", server_tracker.global_position)
	server_tracker.flag.set_client_state(server_input, extrapolation_factor)
	#print("After: ", server_tracker.global_position)
	while extrapolation_factor < 0:
			var new_input = self.input_stream[extrapolation_factor]
			server_tracker.flag.run_input_from_client(new_input)
			extrapolation_factor += 1
	
	self.flag.run_input_from_client(current_input, true)
	self._interpolate()
	#get_node("first_person_camera").global_transform = self.global_transform
	#print("client position: ", self.global_position)
	return current_input

func _interpolate() -> void:
	
	var rotation_diff = self.global_rotation.y - server_tracker.global_rotation.y
	if rotation_diff > PI:
		rotation_diff -= (2 * PI)
	elif rotation_diff < -PI:
		rotation_diff += (2 * PI)
	
	var position_diff = (self.global_position - server_tracker.global_position).length()
	#print("Position diff: ", position_diff)
	if (position_diff > 1.0) or (rotation_diff > 0.3):
		self.global_transform = server_tracker.global_transform
		self.velocity = server_tracker.velocity
	elif (rotation_diff > self.MIN_ANGLE_TO_INTERPOLATE):
		self._correct_transform(0.004, rotation_diff)
	elif (position_diff > self.MIN_DISTANCE_TO_INTERPOLATE):
		self._correct_transform(0.004, position_diff)
	else:
		pass

func _correct_transform(step : float, error : float) -> void:
	if error <= 0:
		print("Warning: stop trying to correct 0 error!")
		return
	var interp_percent = min((step / error), 1)
	#print("Transforms: ", self.global_transform, " ", server_tracker.global_transform)
	self.global_transform = self.global_transform.interpolate_with(server_tracker.global_transform, interp_percent)

func get_local_tick_diff(packet : OrderedInput) -> int:
	return -(self.input_stream[-1].order - packet.order)

func get_player_input() -> OrderedInput:
	var game_input = PlayerInput.new()
	
	game_input.rotation = Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")
	game_input.speed = -Input.get_action_strength("move_backward") + Input.get_action_strength("move_forward")
	
	if Input.is_action_pressed("jump"):
		game_input.jumped = true
	if Input.is_action_just_pressed("shoot"):
		game_input.shot_fired = true
	game_input.order = input_stream[-1].order + 1
	
	return game_input

func _connect_to_radar() -> void:
	var radar = get_node("/root/game/radar/radar_player")
	radar.player = self

func change_global_position(new_position : Vector3) -> void:
	self.global_position = new_position
	server_tracker.global_position = new_position
