extends "Standard3D.gd"

# Maximum speed of tank.
@export var MAX_SPEED = 4
# The downward acceleration when in the air, in meters per second squared.
@export var GRAVITY = 9.8
# Tank turn rate
@export var TURN_SPEED = 1
# Tank initial jump velocity
@export var JUMP_SPEED = 8
var sync_len : int = 20
var physics_delta = 0.00833333 * 2
var acceleration : float = 1000.0
var speed = 0
var angular_velocity = 0
var recent_server_data = Array()
var input_stream = Array()
var current_packet_number = 0
#screw this scripting language
var sync_history = []

func _ready():
	sync_history.resize(sync_len)
	sync_history.fill(0.0)
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

func update_transform(delta):
	var data = null
	
	if len(self.recent_server_data) > 10:
		data = self.recent_server_data[-1]
		

		#print("Elapsed time: ", elapsed_time)
		if data.packet_number > current_packet_number:
			var sync_factor = get_sync_factor(data)
			#print("sync_factor: ", sync_factor)
			var elapsed_time = abs((Time.get_ticks_msec() - sync_factor) - data.packet_number) / 2
			#current_offset = Time.get_ticks_msec() - data.last_client_time
			current_packet_number = data.packet_number 
			#print("server packet#: ", data.packet_number, " Current tick: ", len(self.input_stream))
			if data.shot_fired:
				shoot()
			self.global_transform = Transform3D(Basis(data.quat), data.origin)
			# Lazy way to determine if player is on floor after position reset/update
			self.velocity = Vector3.ZERO
			move_and_slide()
			
			self.velocity = data.velocity
			self.angular_velocity = data.angular_velocity
			
			var i = -1
			#print("Initial: ", elapsed_time, " Sync factor: ", sync_factor, " sync history: ", self.sync_history[-1])
			while ((input_stream[i - 1].time - sync_factor) > data.packet_number) and -i + 1 < len(input_stream):
				i -= 1
			
			while ((elapsed_time) > 0.0) and i <= -1:
				var step_time = (input_stream[i].time - sync_factor) - data.packet_number
				if step_time < elapsed_time:
					var time_fraction = step_time / (physics_delta * 1000)
					self.velocity = input_to_velocity(input_stream[i], time_fraction)
					move_and_slide()
					elapsed_time -= step_time
					i += 1
				else:
					var time_fraction = elapsed_time / (input_stream[i].time - input_stream[i-1].time)
					self.velocity = input_to_velocity(input_stream[i], time_fraction)
					self.velocity = self.velocity * time_fraction
					move_and_slide()
					elapsed_time -= elapsed_time
			#print("final: ", elapsed_time, " final input#: ", i,)
			#self.velocity = input_to_velocity(input_stream[i], (elapsed_time/(physics_delta * 1000)))
			#move_and_slide()
			if is_nan(self.global_transform.origin.y):
				breakpoint
			#print('update: ', data.packet_number, " current time: ", input_stream[-1].time - sync_factor)

		else:
			self.velocity = input_to_velocity(input_stream[-2], 1)
			#self.rotate_object_local(Vector3.UP, input_stream[-1][1] * delta)
			move_and_slide()
			#print('no update: ', self.global_transform.origin.z)

func get_sync_factor(packet : Dictionary) -> int:
	self.sync_history[sync_len % 20] = (packet.player_tick - packet.packet_number)
	sync_len += 1
	var median = sync_history.duplicate()
	median.sort()
	# This seems to work better than the appropriate rounding....
	return (median[9] + median[10]) / 2.0

func get_time_diff(server_time, sync_factor):
	return Time.get_ticks_msec() - (server_time + sync_factor)

func input_to_velocity(input : Dictionary, delta : float) -> Vector3:
	#print(delta)
	if self.is_on_floor():
		self.axis_lock_linear_y = true
		self.angular_velocity = input.rotation * TURN_SPEED
		self.rotate_object_local(Vector3.UP, angular_velocity * physics_delta * delta)
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
		self.rotate_object_local(Vector3.UP, angular_velocity * physics_delta * delta)
		return self.velocity - Vector3(0, GRAVITY, 0) * delta

func shoot():
	var bullet = preload("res://bullet.tscn")
	var shot = bullet.instantiate()
	shot.position = position - (transform.basis.z * 1.2)
	shot.velocity = velocity + (-transform.basis.z * shot.SPEED)
	get_parent().add_child(shot)

func rounded_average(input_array : Array) -> int:
	return roundi(input_array.reduce(func(accum, number): return accum + number, 10)/len(input_array))
