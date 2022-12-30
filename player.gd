extends "Standard3D.gd"

# Maximum speed of tank.
@export var MAX_SPEED = 5
# The downward acceleration when in the air, in meters per second squared.
@export var GRAVITY = 9.8
# Tank turn rate
@export var TURN_SPEED = 0.8
# Tank initial jump velocity
@export var JUMP_SPEED = 8

var new_acceleration = 100
var new_speed = 0
var angular_velocity = 0
var input_velocity = Vector3(0,0,0)
var recent_server_data = Array()
var input_stream = Array()
var current_packet_number = 0

func _process(delta):
	#print(self.rotation.y)
	if Input.is_action_just_pressed("shoot"):
		shoot()

func _physics_process(delta):
	get_input(delta)
	#print(input_stream)
	var data = null
	#print(self.position.z)
	if len(self.recent_server_data) > 10:
		data = self.recent_server_data[-1]
		
		#self.velocity = data.velocity
		if data.packet_number > current_packet_number:
			current_packet_number = data.packet_number
			self.global_position = data.origin
			#print(range(current_packet_number, len(input_stream)))
			for i in range(len(input_stream) - (len(input_stream) - current_packet_number + 2), len(input_stream)):
				#print("Range: ", current_packet_number, ' ', len(input_stream))
				self.velocity = input_stream[i]
				move_and_slide()
				if i == len(input_stream) - 1:
					pass
					#print('server position: ', data.origin)
					#print("Updated position: ", self.position.z, " Packet #: ", current_packet_number, " Input: ", len(input_stream) - 1)
		else:
			#self.global_position = data.origin
			#print(self.rotation)
			self.velocity = input_stream[-1]
			#print('Input velocity: ', self.velocity)
			move_and_slide()
			#print("no updates: ", self.position.z, " Input: ", len(input_stream))
		
		self.rotate_object_local(Vector3.UP, data.angular_velocity*delta)

func get_input(delta) -> void:
	if Input.is_action_pressed("turn_right"):
		angular_velocity = -TURN_SPEED
	elif Input.is_action_pressed("turn_left"):
		angular_velocity = TURN_SPEED
	else:
		angular_velocity = 0
		
	if Input.is_action_pressed("move_forward"):
		new_speed += new_acceleration * delta
	elif Input.is_action_pressed("move_backward"):
		new_speed -= new_acceleration * delta
	else:
		new_speed = 0
		
	if new_speed > MAX_SPEED:
		new_speed = MAX_SPEED
	elif new_speed < -MAX_SPEED:
		new_speed = -MAX_SPEED
		
	input_velocity = transform.basis.z * -new_speed
		
	if Input.is_action_pressed("jump"):
		self.axis_lock_linear_y = false
		input_velocity.y = JUMP_SPEED

func shoot():
	var bullet = preload("res://bullet.tscn")
	var shot = bullet.instantiate()
	shot.position = position - (transform.basis.z * 1.2)
	shot.velocity = velocity + (-transform.basis.z * shot.SPEED)
	get_parent().add_child(shot)
