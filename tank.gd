extends "Standard3D.gd"

# Maximum speed of tank.
@export var MAX_SPEED = 4
# The downward acceleration when in the air, in meters per second squared.
@export var GRAVITY = 9.8
# Tank turn rate
@export var TURN_SPEED = 1
# Tank initial jump velocity
@export var JUMP_SPEED = 8
var acceleration : float = 100.0
var angular_velocity : float = 0.0
var speed : float = 0.0
var current_input : Dictionary = {"rotation": 0.0, "speed": 0.0, "jumped": false, "shot_fired": false}

func _physics_process(delta):
	self.velocity = input_to_velocity(current_input, delta)
	move_and_slide()

func input_to_velocity(input : Dictionary, delta) -> Vector3:
	if is_on_floor():
		#self.axis_lock_linear_y = true
		self.angular_velocity = input.rotation * TURN_SPEED
		self.rotate_object_local(Vector3.UP, angular_velocity * delta)
		if input.speed * MAX_SPEED > self.speed:
			self.speed = min((self.speed + (acceleration * delta)), input.speed * MAX_SPEED)
		elif input.speed * MAX_SPEED < self.speed:
			self.speed = max((self.speed - (acceleration * delta)), input.speed * MAX_SPEED)
		if input.jumped:
			return (self.transform.basis.z * -speed) + Vector3(0, JUMP_SPEED, 0)
		else:
			return (self.transform.basis.z * -speed) 
	else:
		#self.axis_lock_linear_y = false
		return self.velocity - Vector3(0, GRAVITY * delta, 0)

func shoot():
	var bullet = preload("res://bullet.tscn")
	var shot = bullet.instantiate()
	shot.position = position - (transform.basis.z * 1.2)
	shot.velocity = velocity + (-transform.basis.z * shot.SPEED)
	get_parent().add_child(shot)
