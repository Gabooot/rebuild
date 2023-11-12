extends "tank.gd"

const MIN_INTERPOLATION_DISTANCE = 0.1
const MIN_ANGLE_TO_INTERPOLATE = 0.015
var recent_server_data = Array()
var input_stream = Array()
var current_packet_number = 0

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

#Needs some rework.
func update_transform():
	var data = {"quat": Quaternion(0,0,0,0),
					"origin": Vector3(0,0,0),
					"velocity": Vector3(0,0,0),
					"angular_velocity": 0,
					"shot_fired": false,
					"server_ticks_msec": 0,
					"player_ticks_msec": 0}
	
	if len(self.recent_server_data) > 0:
		data = self.recent_server_data[-1]
	else: 
		return
	self.rotate_from_input(input_stream[-1])
	self.move_from_input(input_stream[-1])
	var no_update_prediction = self.global_transform
	
	if data.server_ticks_msec > current_packet_number:
		current_packet_number = data.server_ticks_msec
		self.predict_transform(data)
		#print("Server rotation: ", Basis(data.quat).get_euler().y, " Local rotation: ", self.global_rotation.y)
		var new_prediction = self.global_transform 
		
		var speed = self.velocity.length()
		print("original position diff: ", (new_prediction.origin - no_update_prediction.origin), " new: ", new_prediction.origin, " no update: ", no_update_prediction.origin)
		var position_diff = (new_prediction.origin - no_update_prediction.origin).length()
		var rotation_diff = new_prediction.basis.get_euler().y - no_update_prediction.basis.get_euler().y
		
		if rotation_diff > PI:
			rotation_diff -= (2 * PI)
		elif rotation_diff < -PI:
			rotation_diff += (2 * PI)
		
		print("rotation_diff: ", rotation_diff, " position_diff: ", position_diff)
		if (abs(rotation_diff) > MIN_ANGLE_TO_INTERPOLATE) or (position_diff > MIN_INTERPOLATION_DISTANCE):
			#print("interpolating")
			self.global_transform = no_update_prediction.interpolate_with(self.global_transform, 1)
		
	else:
		pass

func predict_transform(data) -> void:
	self.global_transform = Transform3D(Basis(data.quat), data.origin)
	# Lazy way to determine if player is on floor after position reset/update
	self.velocity = Vector3.ZERO
	move_and_slide()
		
	self.velocity = data.velocity
	self.speed = sqrt((data.velocity.x**2) + (data.velocity.z**2)) *\
	(float(data.velocity.angle_to(self.transform.basis.z) < (0.5)) * -1)
	#print("Server angular: ", data.angular_velocity, " Current angular: ", self.angular_velocity)
	self.angular_velocity = data.angular_velocity
	
	var i = get_local_tick_diff(data)
	while i < -1:
		i += 1
		self.rotate_from_input(input_stream[i])
		self.move_from_input(input_stream[i]) 


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

func add_bullets() -> void:
	for packet in self.recent_server_data:
		if packet.shot_fired:
			#print("Shot fired at: ", packet.server_ticks_msec)
			var current_transform = Transform3D(Basis(packet.quat), packet.origin)
			var current_velocity = packet.velocity
			var shot_tick = get_local_tick_diff(packet)
			add_local_bullet(current_transform, current_velocity, shot_tick)
			#break
	self.recent_server_data[-1].shot_fired = false
	self.recent_server_data = [self.recent_server_data[-1]]

func move_from_input(input : Dictionary) -> void:
	self.velocity = get_velocity_from_input(input)
	self.move_and_slide()

func add_local_bullet(start_transform, start_velocity, shot_tick):
	var shot = self.shoot(start_transform, start_velocity)
	for i in range((-shot_tick) - 1):
		shot.travel(PHYSICS_DELTA)
