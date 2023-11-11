extends "Standard3D.gd"

# Maximum speed of tank.
@export var MAX_SPEED = 4
# The downward acceleration when in the air, in meters per second squared.
@export var GRAVITY = 9.8
# Tank turn rate
@export var TURN_SPEED = 1
# Tank initial jump velocity
@export var JUMP_SPEED = 8

const GUN_VELOCITY_MULTIPLIER : float = 1.2
const PHYSICS_DELTA = 0.01666666
 
var acceleration : float = 100.0
var angular_velocity : float = 0.0
var speed : float = 0.0
var current_input : Dictionary = {"rotation": 0.0, "speed": 0.0, "jumped": false, "shot_fired": false, "player_tick": 0.0}
var shot_fired : bool = false

func _physics_process(_delta):
	pass

func update_from_input(delta : float, input = self.current_input):
	self.rotate_from_input(input)
	self.velocity = get_velocity_from_input(input)
	move_and_slide()
	if input.shot_fired:
		self.shoot()
		self.shot_fired = true
		input.shot_fired = false
	else: 
		self.shot_fired = false

func get_velocity_from_input(input : Dictionary) -> Vector3:
	if self.is_on_floor():
		self.axis_lock_linear_y = true
		if input.speed * MAX_SPEED > self.speed:
			self.speed = min((self.speed + (acceleration * PHYSICS_DELTA)), input.speed * MAX_SPEED)
		elif input.speed * MAX_SPEED < self.speed:
			self.speed = max((self.speed - (acceleration * PHYSICS_DELTA)), input.speed * MAX_SPEED)
		if input.jumped:
			self.axis_lock_linear_y = false
			var external_velocity = ((self.transform.basis.z * -speed) + Vector3(0, JUMP_SPEED, 0))
			return external_velocity
		else:
			var external_velocity = self.transform.basis.z * -speed
			return external_velocity
	else:
		self.axis_lock_linear_y = false
		var external_velocity = (self.velocity - Vector3(0, GRAVITY * PHYSICS_DELTA, 0))
		return external_velocity

func rotate_from_input(input : Dictionary) -> void:
	if self.is_on_floor():
		self.angular_velocity = input.rotation * TURN_SPEED
		self.rotate_object_local(Vector3.UP, self.angular_velocity * PHYSICS_DELTA)
	else:
		self.rotate_object_local(Vector3.UP, self.angular_velocity * PHYSICS_DELTA)

func shoot(start_transform=self.global_transform, start_velocity=self.velocity) -> Node3D:
	var bullet = preload("res://bullet.tscn")
	var shot = bullet.instantiate()
	shot.position = start_transform.origin - (start_transform.basis.z * GUN_VELOCITY_MULTIPLIER)
	shot.velocity = start_velocity + (-start_transform.basis.z * shot.SPEED)
	get_parent().add_child(shot)
	
	return shot
