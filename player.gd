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
		#print("Elapsed time: ", elapsed_time)
	if data.server_ticks_msec > current_packet_number:
		current_packet_number = data.server_ticks_msec
		print("Server rotation: ", Basis(data.quat).get_euler().y, " current rotation: ", self.global_rotation.y)
		var current_transform = self.global_transform
		var current_rotation = self.global_rotation.y
		
		self.predict_transform(data)
		
		var pos_diff = (self.global_transform.origin - current_transform.origin).length()
		#print("Real rotation: ", self.global_rotation.y, " Current visual: ", current_rotation)
		var rotation_diff = self.global_rotation.y - current_rotation
		
		if rotation_diff > PI:
			#print("High error")
			rotation_diff -= (2 * PI)
		elif rotation_diff < -PI:
			#print("Low error")
			rotation_diff += (2 * PI)
		
		#print("rotation_diff: ", rotation_diff)
		if abs(rotation_diff) > MIN_ANGLE_TO_INTERPOLATE:
			print("interpolating angle")
			self.global_rotation.y -= (rotation_diff * 0.4)
		if pos_diff > MIN_INTERPOLATION_DISTANCE:
			#print("transform ", self.global_transform)
			self.global_transform = current_transform.interpolate_with(self.global_transform, 0.5)
			#print("interpolated: ", self.global_transform)
		
	else:
		#print("no update")
		self.velocity = input_to_velocity(input_stream[-1], 1)
		self.rotate_from_input(input_stream[-1])
		move_and_slide()
		#print('no update: ', self.global_transform.origin.z)

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
	while i < 0:
		i += 1
		self.rotate_from_input(input_stream[i])
		self.move_from_input(input_stream[i])

# Bad things might happen here
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

func input_to_velocity(input : Dictionary, delta : float) -> Vector3:
	#print(delta)
	if self.is_on_floor():
		self.axis_lock_linear_y = true
		if input.speed * MAX_SPEED > self.speed:
			self.speed = min((self.speed + (acceleration * physics_delta)), input.speed * MAX_SPEED)
		elif input.speed * MAX_SPEED < self.speed:
			self.speed = max((self.speed - (acceleration * physics_delta)), input.speed * MAX_SPEED)
		if input.jumped:
			self.axis_lock_linear_y = false
			return ((self.transform.basis.z * -speed) + Vector3(0, JUMP_SPEED, 0)) * delta
		else:
			return (self.transform.basis.z * -speed) * delta
	else:
		self.axis_lock_linear_y = false
		return (self.velocity - Vector3(0, GRAVITY * physics_delta, 0)) * delta

func move_from_input(input : Dictionary) -> void:
	if self.is_on_floor():
		self.axis_lock_linear_y = true
		if input.speed * MAX_SPEED > self.speed:
			self.speed = min((self.speed + (acceleration * physics_delta)), input.speed * MAX_SPEED)
		elif input.speed * MAX_SPEED < self.speed:
			self.speed = max((self.speed - (acceleration * physics_delta)), input.speed * MAX_SPEED)
		if input.jumped:
			self.axis_lock_linear_y = false
			var external_velocity = ((self.transform.basis.z * -speed) + Vector3(0, JUMP_SPEED, 0))
			self.velocity = external_velocity
			self.move_and_slide()
		else:
			var external_velocity = self.transform.basis.z * -speed
			self.velocity = external_velocity
			self.move_and_slide()
	else:
		self.axis_lock_linear_y = false
		var external_velocity = (self.velocity - Vector3(0, GRAVITY * physics_delta, 0))
		self.velocity = external_velocity
		self.move_and_slide()

func rotate_from_input(input : Dictionary) -> void:
	if self.is_on_floor():
		self.angular_velocity = input.rotation * TURN_SPEED
		self.rotate_object_local(Vector3.UP, self.angular_velocity * physics_delta)
	else:
		self.rotate_object_local(Vector3.UP, self.angular_velocity * physics_delta)

	
func add_local_bullet(start_transform, start_velocity, shot_tick):
	var shot = self.shoot(start_transform, start_velocity)
	for i in range((-shot_tick) - 1):
		shot.travel(physics_delta)
