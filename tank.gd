class_name tank extends "Standard3D.gd"
# Maximum speed of tank.
@export var MAX_SPEED = 5
# The downward acceleration when in the air, in meters per second squared.
@export var GRAVITY = 9.8
# Tank turn rate
@export var TURN_SPEED = .8
# Tank initial jump velocity
@export var JUMP_SPEED = 9.5

const GUN_VELOCITY_MULTIPLIER : float = 1.4
const PHYSICS_DELTA = 0.01666666
const MAX_INPUTS = 4
 
var shot_timers = [0,0,0]
var reload_time_msec = 3000
var acceleration : float = 100.0
var angular_velocity : float = 0.0
var speed : float = 0.0
var current_input : Dictionary = {"rotation": 0.0, "speed": 0.0, "jumped": false, "shot_fired": false, "player_tick": 0.0}
var buffer = null
var buffer_length = 4
var shot_fired : bool = false

func _ready():
	get_node("/root/game").tank_hit.connect(_tank_hit)
	self._start_buffer()

func _start_buffer() -> void:
	self.buffer = PlayerInputBuffer.new(PlayerInput.new(), buffer_length)

func _physics_process(_delta):
	pass

func update_from_input(input : OrderedInput=self.buffer.take()) -> Variant:
	'''if input and multiplayer.is_server():
		#print("Input: ", bytes_to_var(input.to_byte_array()))
		print("Current position: ", self.position)'''
	rotate_from_input(input)
	move_from_input(input)
	if input.shot_fired and (Time.get_ticks_msec() - shot_timers[0]) > reload_time_msec:
		self.shoot()
		self.shot_fired = true
		input.shot_fired = false
	else: 
		self.shot_fired = false
	
	var server_update = _get_current_server_input()
	server_update.order = input.order
	return server_update

func change_global_position(new_position : Vector3) -> void:
	self.global_position = new_position

func add_ordered_input(input : OrderedInput) -> void:
	assert(input is PlayerInput, "Error: server tank provided with non-player input type")
	self.buffer.add(input)

func _get_current_server_input() -> ServerInput:
	var current_transform = self.global_transform
	var quat = Quaternion(current_transform.basis.orthonormalized())
	var origin = current_transform.origin
	#print("output origin: ", origin)
	return ServerInput.new(quat, origin, self.velocity, self.angular_velocity, self.shot_fired)

func get_speed_from_input(input : PlayerInput) -> float:
	var new_speed = 0.0
	if input.speed * MAX_SPEED > self.speed:
		new_speed = min((self.speed + (acceleration * PHYSICS_DELTA)), input.speed * MAX_SPEED)
	elif input.speed * MAX_SPEED < self.speed:
		new_speed = max((self.speed - (acceleration * PHYSICS_DELTA)), input.speed * MAX_SPEED)
	else:
		new_speed = self.speed
	
	return new_speed

func get_velocity_from_speed(speed=self.speed, jumped=false) -> Vector3:
	if self.is_on_floor():
		if jumped:
			var external_velocity = ((self.transform.basis.z * -speed) + Vector3(0, JUMP_SPEED, 0))
			return external_velocity
		else:
			var external_velocity = self.transform.basis.z * -speed
			return external_velocity
	else:
		var external_velocity = (self.velocity - Vector3(0, GRAVITY * PHYSICS_DELTA, 0))
		return external_velocity

func move_from_input(input : PlayerInput) -> void:
	if (not self.is_on_floor()) or input.jumped:
		self.axis_lock_linear_y = false
	else:
		self.axis_lock_linear_y = true
	
	self.speed = get_speed_from_input(input)
	self.velocity = get_velocity_from_speed(self.speed, input.jumped)
		#print("server old: ", self.global_position)
	self.move_and_slide()

func rotate_from_input(input : PlayerInput) -> void:
	if self.is_on_floor():
		self.angular_velocity = input.rotation * TURN_SPEED
		self.rotate_object_local(Vector3.UP, self.angular_velocity * PHYSICS_DELTA)
	else:
		self.rotate_object_local(Vector3.UP, self.angular_velocity * PHYSICS_DELTA)

func shoot(start_transform=self.global_transform, start_velocity=self.velocity) -> Node3D:
	self.shot_timers.pop_back()
	self.shot_timers.append(Time.get_ticks_msec())
	var bullet = preload("res://bullet.tscn")
	var shot = bullet.instantiate()
	shot.position = start_transform.origin - (start_transform.basis.z * 1.5)
	shot.velocity = start_velocity + (-start_transform.basis.z * shot.SPEED)
	get_parent().add_child(shot)
	return shot

func _tank_hit(shooter, target):
	#print(self.name)
	if target == self.name:
		self.global_position += Vector3(randf_range(-1,1) * 8,100,randf_range(-1,1) * 8)
