extends "Standard3D.gd"

# Maximum speed of tank.
@export var MAX_SPEED = 4
# The downward acceleration when in the air, in meters per second squared.
@export var GRAVITY = 9.8
# Tank turn rate
@export var TURN_SPEED = 1
# Tank initial jump velocity
@export var JUMP_SPEED = 8

var physics_delta = 0.00833333 * 2
var acceleration : float = 1000.0
var speed = 0
var angular_velocity = 0
var recent_server_data = Array()
var input_stream = Array()
var current_packet_number = 0
#screw this scripting language
var sync_history = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

func _process(_delta):
	#print("client z: ", self.global_position.z)
	#if Input.is_action_just_pressed("shoot"):
		#shoot()
	pass

func _physics_process(delta):
	get_player_input()
	
	var data = null
	
	if len(self.recent_server_data) > 10:
		data = self.recent_server_data[-3]
		self.sync_history.append(1 - (data.packet_number - data.player_tick))
		self.sync_history = self.sync_history.slice(1,)
		var sync_factor = rounded_average(self.sync_history)
		print("sync_factor: ", sync_factor)
		#print("Server tick - client tick: ", data.packet_number - data.player_tick)
		if data.packet_number > current_packet_number:
			#current_offset = Time.get_ticks_msec() - data.last_client_time
			current_packet_number = data.packet_number #+ sync_factor
			#print("server packet#: ", data.packet_number, " Current tick: ", len(self.input_stream))
			if data.shot_fired:
				shoot()
			self.global_transform = Transform3D(Basis(data.quat), data.origin)
			# Lazy way to determine if player is on floor after position reset/update
			self.velocity = Vector3.ZERO
			move_and_slide()
			
			self.velocity = data.velocity
			self.angular_velocity = data.angular_velocity
			for i in range(current_packet_number - 1, len(input_stream) - 1):
				self.velocity = input_to_velocity(input_stream[i], delta)
				move_and_slide()
			#print('update: ', self.global_transform.origin.z)

		else:
			self.velocity = input_to_velocity(input_stream[-3], delta)
			#self.rotate_object_local(Vector3.UP, input_stream[-1][1] * delta)
			move_and_slide()
			#print('no update: ', self.global_transform.origin.z)
		#self.rotate_object_local(Vector3.UP, data.angular_velocity*delta)

func get_player_input() -> Dictionary:
	var game_input = {"rotation": 0.0, "speed": 0.0, "jumped": false, "shot_fired": false, "was_on_floor": null}
	
	game_input.rotation = Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")

	game_input.speed = -Input.get_action_strength("move_backward") + Input.get_action_strength("move_forward")
	
	if Input.is_action_pressed("jump"):
		game_input.jumped = true
	if Input.is_action_just_pressed("shoot"):
		game_input.shot_fired = true
	
	input_stream.append(game_input)
	
	return game_input

func input_to_velocity(input : Dictionary, delta) -> Vector3:

	if self.is_on_floor():
		self.axis_lock_linear_y = true
		self.angular_velocity = input.rotation * TURN_SPEED
		self.rotate_object_local(Vector3.UP, angular_velocity * physics_delta)
		if input.speed * MAX_SPEED > self.speed:
			self.speed = min((self.speed + (acceleration * physics_delta)), input.speed * MAX_SPEED)
		elif input.speed * MAX_SPEED < self.speed:
			self.speed = max((self.speed - (acceleration * physics_delta)), input.speed * MAX_SPEED)
		if input.jumped:
			self.axis_lock_linear_y = false
			return (self.transform.basis.z * -speed) + Vector3(0, JUMP_SPEED, 0)
		else:
			return (self.transform.basis.z * -speed) 
	else:
		self.axis_lock_linear_y = false
		self.rotate_object_local(Vector3.UP, angular_velocity * physics_delta)
		return self.velocity - Vector3(0, GRAVITY * physics_delta, 0)

func shoot():
	var bullet = preload("res://bullet.tscn")
	var shot = bullet.instantiate()
	shot.position = position - (transform.basis.z * 1.2)
	shot.velocity = velocity + (-transform.basis.z * shot.SPEED)
	get_parent().add_child(shot)

func rounded_average(input_array : Array) -> int:
	return roundi(input_array.reduce(func(accum, number): return accum + number, 10)/len(input_array))
