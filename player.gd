extends "Standard3D.gd"

# Maximum speed of tank.
@export var MAX_SPEED = 4
# The downward acceleration when in the air, in meters per second squared.
@export var GRAVITY = 9.8
# Tank turn rate
@export var TURN_SPEED = 1
# Tank initial jump velocity
@export var JUMP_SPEED = 8

var physics_delta = 0.00833333
var acceleration = 100
var speed = 0
var angular_velocity = 0
var input_velocity = Vector3(0,0,0)
var recent_server_data = Array()
var input_stream = Array()
var current_packet_number = 0

func _process(_delta):
	#print("client z: ", self.global_position.z)
	#if Input.is_action_just_pressed("shoot"):
		#shoot()
	pass

func _physics_process(delta):
	'''if len(recent_server_data) > 7:
		print("position: ", self.global_transform.origin.z, " server: ", recent_server_data[-7].origin.z, " packet#: ",\
			recent_server_data[-7].packet_number, " # inputs: ", len(self.input_stream))'''
	get_player_input()
	#print(input_stream)
	var data = null
	
	if len(self.recent_server_data) > 7:
		data = self.recent_server_data[-5]
		#self.velocity = data.velocity
		if data.packet_number > current_packet_number:
			current_packet_number = data.packet_number
			if data.shot_fired:
				shoot()
			self.global_transform = Transform3D(Basis(data.quat), data.origin)
			self.velocity = data.velocity
			for i in range(current_packet_number - 1, len(input_stream) - 1):
				self.velocity = input_to_velocity(input_stream[i], delta)
				move_and_slide()
				if i == len(input_stream) - 1:
					#print('client rotation: ', input_stream[i].rotation)
					pass
			#print("Updated position: ", self.global_transform.origin.y, " Packet #: ", current_packet_number, " Input: ",\
				#len(input_stream), " server position: ", data.origin.y)
		else:
			self.velocity = input_to_velocity(input_stream[-1], delta)
			#self.rotate_object_local(Vector3.UP, input_stream[-1][1] * delta)
			move_and_slide()
			#print("input_stream length: ", len(self.input_stream) - 1, " Position: ", self.position.z)
			#print("no update y: ", self.global_transform.origin.y, " Packet #: ", current_packet_number, " Input: ",\
				#len(input_stream), " server position: ", data.origin.y)
			#print("no updates: ", self.position.z, " Input: ", len(input_stream))
		
		#self.rotate_object_local(Vector3.UP, data.angular_velocity*delta)

func get_player_input() -> Dictionary:
	var game_input = {"rotation": 0.0, "speed": 0.0, "jumped": false, "shot_fired": false, "was_on_floor": null}
	
	game_input.rotation = Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")

	game_input.speed = -Input.get_action_strength("move_backward") + Input.get_action_strength("move_forward")
	
	if Input.is_action_pressed("jump"):
		game_input.jumped = true
	if Input.is_action_just_released("shoot"):
		print("shoot!")
		game_input.shot_fired = true
	
	input_stream.append(game_input)
	
	return game_input

func input_to_velocity(input : Dictionary, delta) -> Vector3:
	if input.was_on_floor == null:
		input.was_on_floor = is_on_floor()
	if input.was_on_floor:
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
