extends Node

#TODO make these proportional to velocity
const MIN_DISTANCE_TO_INTERPOLATE = 0.05
const MIN_ANGLE_TO_INTERPOLATE = 0.01

var recent_server_data = Array()
var input_stream = Array()
var current_packet_number = 0

var interpolates = 0.0
var teles = 0.0 
var total = 1.0
var tracker = 10000
func _ready():
	pass

func _physics_process(_delta):
	if Time.get_ticks_msec() - tracker > 0:
		tracker += 10000
		var stats =  (self.interpolates + self.teles) / self.total
		print("Stats, # of interpolations: ", self.interpolates, " # of teleports: ", self.teles, " /total: ", stats)

func get_player_input() -> Dictionary:
	var game_input = PlayerInput.new()
	
	game_input.rotation = Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")
	game_input.speed = -Input.get_action_strength("move_backward") + Input.get_action_strength("move_forward")
	
	if Input.is_action_pressed("jump"):
		game_input.jumped = true
	if Input.is_action_just_pressed("shoot"):
		game_input.shot_fired = true
	game_input.order = input_stream[-1].order + 1
	
	return game_input

func add_ordered_input(input : ServerInput) -> void:
	%server_tracker.buffer.add(input)

func update_from_input() -> PlayerInput:
	var current_input = self.get_player_input()
	input_stream.append(current_input)
	
	%server_tracker.predict_transform(%server_tracker.buffer.take())
	%input_tracker.rotate_from_input(current_input)
	%input_tracker.move_from_input(current_input)
	self._determine_error()
	get_node("input_tracker/first_person_camera").global_transform = %input_tracker.global_transform
	return current_input
	#print("Stats, # of interpolations: ", self.interpolates, " # of teleports: ", self.teles, " /total: ", stats)

func _determine_error() -> void:
	
	var rotation_diff = %input_tracker.global_rotation.y - %server_tracker.global_rotation.y
	if rotation_diff > PI:
		rotation_diff -= (2 * PI)
	elif rotation_diff < -PI:
		rotation_diff += (2 * PI)
	
	var position_diff = (%input_tracker.global_position - %server_tracker.global_position).length()
	
	if (position_diff > 1.0) or (rotation_diff > 0.3):
		self.teles += 1
		self.total += 1
		%input_tracker.global_transform = %server_tracker.global_transform
		%input_tracker.velocity = %server_tracker.velocity
	elif (rotation_diff > MIN_ANGLE_TO_INTERPOLATE):
		self.interpolates += 1
		self.total += 1
		self._interpolate(0.004, rotation_diff)
	elif (position_diff > MIN_DISTANCE_TO_INTERPOLATE):
		self.interpolates += 1
		self.total += 1
		self._interpolate(0.004, position_diff)
	else:
		self.total += 1

func _interpolate(step : float, error : float) -> void:
	if error <= 0:
		print("Warning: stop trying to correct 0 error!")
		return
	var interp_percent = min((step / error), 1)
	%input_tracker.global_transform = %input_tracker.global_transform.interpolate_with(%server_tracker.global_transform, interp_percent)

func add_bullets() -> void:
	for packet in self.recent_server_data:
		if packet.shot_fired:
			#print("Shot fired at: ", packet.server_ticks_msec)
			var current_transform = Transform3D(Basis(packet.quat), packet.origin)
			var current_velocity = packet.velocity
			var shot_tick = get_local_tick_diff(packet)
			%server_tracker.add_local_bullet(current_transform, current_velocity, shot_tick)
			#break
	self.recent_server_data[-1].shot_fired = false
	self.recent_server_data = [self.recent_server_data[-1]]

func get_local_tick_diff(packet : OrderedInput) -> int:
	return (self.input_stream[-1].order - packet.order) - 1
