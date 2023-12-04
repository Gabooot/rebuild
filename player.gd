extends Node

const MIN_DISTANCE_TO_INTERPOLATE = 0.01
const MIN_ANGLE_TO_INTERPOLATE = 0.01
var recent_server_data = Array()
var input_stream = Array()
var current_packet_number = 0

var interpolates = 0.0
var teles = 0.0 
var total = 1.0

func _ready():
	pass

func get_player_input() -> Dictionary:
	var game_input = {"rotation": 0.0, "speed": 0.0, "jumped": false, "shot_fired": false, "time": Time.get_ticks_msec()}
	
	game_input.rotation = Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")
	game_input.speed = -Input.get_action_strength("move_backward") + Input.get_action_strength("move_forward")
	
	if Input.is_action_pressed("jump"):
		game_input.jumped = true
	if Input.is_action_just_pressed("shoot"):
		game_input.shot_fired = true
	
	input_stream.append(game_input)
	
	return game_input

# FIX PACKET ORDERING!!!!!!!
func update_transform():
	self.recent_server_data.sort_custom(func(a, b): return a.server_ticks_msec < b.server_ticks_msec)
	var data = {"quat": Quaternion(0,0,0,0),
					"origin": Vector3(0,0,0),
					"velocity": Vector3(0,0,0),
					"angular_velocity": 0,
					"shot_fired": false,
					"server_ticks_msec": 0,
					"player_ticks_msec": 0}
	var current_input = self.input_stream[-1]
	
	if len(self.recent_server_data) > 0:
		data = self.recent_server_data[-1]
	else: 
		return
	
	
	%input_tracker.rotate_from_input(current_input)
	%input_tracker.move_from_input(current_input)
	%server_tracker.predict_transform(data)
	
	self._determine_error()
	
	var stats =  (self.interpolates + self.teles) / self.total
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
	
	
	
func get_rotation_input() -> float:
	var rotation_diff = %input_tracker.global_rotation.y - %server_tracker.global_rotation.y
	if rotation_diff < 0.0001:
		return 0.0
	if rotation_diff > PI:
		rotation_diff -= (2 * PI)
	elif rotation_diff < -PI:
		rotation_diff += (2 * PI)
	
	var delta_turn = (%input_tracker.TURN_SPEED * %input_tracker.PHYSICS_DELTA)
	if (rotation_diff / delta_turn) > 1:
		return 1
	elif (rotation_diff / delta_turn) < -1:
		return -1
	else:
		return (rotation_diff / delta_turn)

# Needs to happen before updating %server tracker with current input
func get_position_input(recent_input) -> float:
	var test_input = {"rotation": 0.0, "speed": 0.0, "jumped": false, "shot_fired": false, "time": Time.get_ticks_msec()}
	var last_server_position = %server_tracker.global_position
	var mid_speed = %server_tracker.get_speed_from_input(test_input)
	var mid_velocity = %server_tracker.get_velocity_from_speed(mid_speed) * %server_tracker.PHYSICS_DELTA
	test_input.speed = 1.0
	var max_speed = %server_tracker.get_speed_from_input(test_input)
	var max_velocity = (%server_tracker.get_velocity_from_speed(max_speed) * %server_tracker.PHYSICS_DELTA)
	test_input.speed = -1.0
	var min_speed = %server_tracker.get_speed_from_input(test_input)
	var min_velocity = (%server_tracker.get_velocity_from_speed(min_speed) * %server_tracker.PHYSICS_DELTA) - mid_velocity
	var input_position = %input_tracker.global_position - %server_tracker.global_position
	if input_position.length() < 0.01:
		return 0
	
	var max_velocity_point = twod_clamped_projection(input_position, max_velocity)
	var min_velocity_point = twod_clamped_projection(input_position, min_velocity)
	
	if max_velocity_point > min_velocity_point:
		#print("Forward: ", max_velocity_point)
		return max_velocity_point
	else:
		#print("Backwards: ", min_velocity_point)
		return -min_velocity_point

func twod_clamped_projection(point : Vector3, line_segment : Vector3) -> float:
	var twod_point = Vector2(point.x,point.z)
	var twod_line_segment = Vector2(line_segment.x, line_segment.z)
	if twod_line_segment.length() < 0.0001:
		#print("small vector")
		return 0.0
	elif abs(twod_point.angle_to(twod_line_segment)) > (0.5*PI):
		#print("wrong direction")
		return 0.0
	else:
		var projection = twod_point.project(twod_line_segment)
		#print("Vector: ", twod_line_segment, " Projection: ", projection)
		return min((projection.length() / twod_line_segment.length()), 1.0)
#Bad things might happen here
# Estimates the number of ticks the server has run between now and when it sent out "data"
func get_local_tick_diff(data : Dictionary) -> int:
	var i = -1
	var sync_factor = %UDPclient.get_sync_factor()
	while (data.server_ticks_msec < (input_stream[i - 1].time - sync_factor)) and (-i + 2) < len(input_stream): 
		i -= 1
		if abs(data.server_ticks_msec - (input_stream[i - 1].time - sync_factor)) < abs(data.server_ticks_msec - (input_stream[i].time - sync_factor)):
			i -= 1
	return i

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
